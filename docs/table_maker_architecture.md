# Table Maker Architecture

## 1. System Overview

Table Maker is a feature enabling computation of poverty and inequality indicators from microdata. Users can:
- Select up to 15 surveys (country-year pairs)
- Request multiple measures (poverty headcount, Gini, mean welfare, etc.)
- Specify up to 4 breakdown dimensions (gender, age, education, area, etc.)
- Receive results as JSON with computed indicators

## 2. Data Architecture

### Data Flow Pipeline

```
Raw Surveys (Y-drive)
    ↓
Harmonization Pipeline ({pipdata} package)
    ↓
Survey Metadata (.qs2 files)
    ↓
Harmonized Microdata (.qs2 files)
    ↓
Arrow/Parquet Partitioned Dataset
    ↓
Computation Engine ({piptm} package)
    ↓
API Layer (Plumber)
    ↓
Platform UI
```

### Input Data Sources

- **Raw Surveys**: AGO_2008_IBEP_ALL.csv, ALB_2005_LSMS_ALL.csv, etc.
- **Location**: Y-drive (raw survey files)
- **Format**: CSV

### Harmonization Pipeline

Handled by {pipdata} package
Output: Standardized .qs2 files (metadata + microdata)

### Harmonized Data Storage

- **Location**: `Y:\PIP_ingestion_pipeline_v2\pip_repository\pip_data\`
  - Metadata: `surveys_metadata/`
  - Microdata: `surveys/`
- **File Format**: .qs2 (serialized R objects)
- **Example**: `BOL_2008_EH_INC_ALL.qs2`
- **Metadata Contents**: country_code, survey_year, welfare_type, CPI, PPP, population, GDP, PCE, available variables
- **Microdata Contents**: Rows = observations; Columns = welfare, gender, area, education, age, weight, etc.

## 3. Arrow Dataset Design

### Partition Structure

Partitioned by key dimensions for efficient filtering. **Note: CHN is excluded entirely** (only has group data, no microdata for covariates):

```
arrow_data/parquet/
├─ country_code=COL/
│  ├─ surveyid_year=2010/
│  │  └─ welfare_type=INC/
│  │     ├─ part-0.parquet
│  │     └─ part-1.parquet
│  └─ surveyid_year=2012/
│     ├─ welfare_type=INC/
│     │  └─ part-0.parquet
│     └─ welfare_type=CON/
│        └─ part-0.parquet
└─ country_code=IND/
   └─ surveyid_year=2011/
      └─ welfare_type=CON/
         └─ part-0.parquet
```

### Partition Dimensions

- **country_code**: Country (e.g., COL, IND, BOL) — **CHN is excluded**
- **surveyid_year**: Survey year (e.g., 2010, 2015)
- **welfare_type**: Income (INC) or Consumption (CON) — only when available for that survey

**Removed dimensions**:
- **reporting_level**: Not partitioned. Reason: CHN is the only country with multiple reporting levels (NATIONAL, URBAN, RURAL), but CHN has no microdata—only group aggregates. All other countries have only one reporting level (NATIONAL). Therefore, reporting_level is not a useful partition dimension and is omitted. 

### Generation Strategy

**Approach: Pre-Generation Only with Release Metadata**

- **All Arrow datasets are pre-generated** before API deployment
  - No on-demand generation at query time
  - All partitions created and validated before release
  - Generation triggered by PIP release cycles, not by individual API requests

- **Release Metadata Manifest**: For each PIP release, a manifest file specifies:
  - Available datasets (country, year, welfare_type combinations)
  - Arrow generation timestamp
  - {pipdata} version used
  - Data quality flags
  - Example structure:
    ```json
    {
      "release_date": "2026-03-04",
      "pipdata_version": "0.8.2",
      "datasets": [
        {"country": "COL", "year": 2010, "welfare_type": "INC"},
        {"country": "COL", "year": 2012, "welfare_type": "INC"},
        {"country": "COL", "year": 2012, "welfare_type": "CON"},
        {"country": "IND", "year": 2011, "welfare_type": "CON"}
      ],
      "excluded_countries": ["CHN"],
      "excluded_partitions": ["reporting_level"]
    }
    ```

- **API Initialization**: On startup, API loads release metadata to determine available datasets
  - No runtime dataset discovery; use manifest for validation
  - Performance benefit: Pre-validated, pre-computed data

## 4. Computation Engine ({piptm} Package)

### Architecture & Development Approach

A new {piptm} package will be created (not refactoring legacy {piptb}) with the following design:

**Principle**: Implement custom functions in {piptm} with reference to existing implementations in {wbpip} and {pipapi}, but without creating dependencies on external packages for computation.

**Implementation Strategy**:
- Copy/adapt algorithmic logic from {wbpip} and {pipapi} where useful
- Implement as native {piptm} functions
- Self-contained computation engine

### Core Design: Measure-Specific Functions (New in {piptm})

**Current Functions** (need refactoring):
- `tb()` - Generic cross-tabulation function using collapse::collapv()
  - **Issue**: Too generic; mixes grouping logic, statistics selection, and output formatting
  - **Current behavior**: Accepts arbitrary variables/statistics; limited to basic aggregations (mean, sum, median, min, max)
  - **Problem for Table Maker**: Cannot compute specialized indicators (poverty gaps, Gini, percentiles)

- `tb_heap()` - Generates all possible dimension combinations for a single survey
  - **Issue**: Over-inclusive; generates combinations not requested by users (up to 4-way breakdowns)
  - **Problem for Table Maker**: API requests specific dimension combinations; this creates unnecessary output
  - **Output format**: Uses prefixed column names ("dim_*", "int_*") that don't match API response schema

- `table_baker()` - Loads pre-computed Arrow data and retrieves raw results
  - **Current role**: Arrow query layer (should work as-is, but may need optimization)
  - **Issue**: No computation; just filtering and collecting data

- `tb_create_arrow()` - Pre-computes all indicators and writes to Arrow
  - **Issue**: Pre-computation approach; designed for batch generation, not API on-demand queries
  - **Problem for Table Maker**: API needs dynamic computation at query time, not pre-stored results

### Required Refactoring Strategy

**Phase 1: Implement Measure Functions**

Create specialized, focused functions for each measure:

```r
# Core poverty measures
compute_poverty_headcount(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: weighted proportion of population below poverty_line
  └─ Implementation: Custom in {piptm}, referencing {wbpip} algorithm
  
compute_poverty_gap(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: average depth of poverty (normalized gap)
  └─ Implementation: Custom in {piptm}, referencing {pipapi} approach
  
compute_poverty_severity(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: squared poverty gap (Foster-Greer-Thorbecke P2)
  └─ Implementation: Custom in {piptm}

# Welfare measures
compute_mean_welfare(microdata, welfare_var, weight_var)
  └─ Returns: weighted mean welfare level
  └─ Implementation: data.table or collapse
  
compute_median_welfare(microdata, welfare_var, weight_var)
  └─ Returns: weighted percentile at 50th position
  └─ Implementation: Custom weighted percentile in {piptm}
  
compute_percentile(microdata, welfare_var, weight_var, percentile = c(10, 25, 75, 90))
  └─ Returns: weighted percentile at specified levels
  └─ Implementation: Custom in {piptm}

# Inequality measures
compute_gini(microdata, welfare_var, weight_var)
  └─ Returns: Gini coefficient (requires specialized algorithm with weights)
  └─ Implementation: Custom in {piptm}, referencing {wbpip} algorithm
  
compute_population(microdata, weight_var)
  └─ Returns: total weighted population
  └─ Implementation: Simple weighted sum

# Implementation Approach:
# - All functions implemented natively in {piptm}
# - Reference {wbpip} and {pipapi} for algorithms, copy logic as needed
# - No external dependencies for computation
# - All functions accept pre-grouped data and compute within groups
# - All functions return NA for missing dimensions (not skip/fail)
```

**Phase 2: Create Orchestrator Function**

Create main computation orchestrator:

```r
table_maker_compute(
  surveys,            # list of pre-filtered data.frames from Arrow
  measures,           # c("poverty_headcount", "mean_welfare", "gini")
  breakdowns,         # c("gender", "area") — specific user request, not all combos
  welfare_var,        # "welfare_ppp" or "welfare_lcu"
  poverty_lines = 1.9,
  weight_var = "weight",
  include_totals = TRUE
)
  └─ Orchestrates computation:
      1. Validate measure/breakdown compatibility
      2. For each measure:
         - Create derived variables if needed (e.g., poor = welfare < poverty_line)
         - Group by breakdowns
         - Call measure-specific function
         - Collect results with metadata (n, se)
      3. Bind results; add "all" rows if include_totals=TRUE
      4. Return in API schema format
```

Handle missing breakdown variables intentionally:

**Scenario**: User requests breakdown by ["gender", "education", "age"], but survey lacks "age" variable.
- Include all rows from survey with age=NA
- Compute measures across entire survey (not grouped by age)
- Clarify in response metadata that age dimension is missing
- User gets results with age=NA, allowing comparison with other surveys

**Implementation**:

```r
# When loading microdata for a survey:
breakdowns_requested <- c("gender", "education", "age")
breakdowns_available <- names(survey_df)
missing_breakdowns <- setdiff(breakdowns_requested, breakdowns_available)

if (length(missing_breakdowns) > 0) {
  # Add missing dimensions as NA columns
  for (dim in missing_breakdowns) {
    survey_df[[dim]] <- NA  # All rows have NA for missing dimension
  }
  # Store metadata about missing dimensions
  survey_metadata$missing_dimensions <- missing_breakdowns
}

# During computation:
# - Groups will include (gender, education, NA)
# - Each group computes measures across all matching rows
# - Results include rows with dim=NA for missing dimensions
# - API metadata indicates which dimensions were missing
```

**Rationale**:
- Simplifies API logic: Always include requested surveys in results
- User sees all available data even if dimensions don't align
- Missing dimension represented explicitly (NA, not absent)
- Enables cross-survey comparison despite different available dimensions



### High-Level Computation Flow 

```
API Request
│
├─ 1. Validate request
│  ├─ Check surveys loaded successfully
│  ├─ Check measures in supported list
│  ├─ Check breakdowns exist in surveys
│  └─ Check poverty_lines are numeric/positive
│
├─ 2. Load filtered Arrow data
│  └─ table_baker(COL = c(2010, 2012), ...) 
│     └─ Returns: list of data.frames, one per survey
│
├─ 3. For each (measure, poverty_line if applicable):
│  │
│  ├─ 3a. Prepare microdata
│  │  └─ Create derived variables if needed
│  │     (e.g., poor = (welfare_ppp < 1.9))
│  │
│  ├─ 3b. Group by breakdowns
│  │  └─ data.table grouping: DT[, measure_func(), by = breakdowns]
│  │
│  ├─ 3c. Call measure-specific function
│  │  └─ compute_poverty_headcount(DT, weight_var = "weight")
│  │
│  └─ 3d. Add metadata
│     └─ Compute n_unweighted, n_weighted, se (if applicable)
│
├─ 4. Add subgroup totals (if requested)
│  └─ For each breakdown: add row with value = aggregate
│
├─ 5. Combine all results
│  └─ rbindlist() all measure results into single data.frame
│
└─ 6. Return formatted output
   └─ Columns: country, year, [breakdown cols], measure, poverty_line, value, se, n, ...
```

### Computation Interface (Proposed)

```r
# Main orchestrator function (new)
table_maker_compute(
  surveys,            # list of data.frames, one per survey
  measures,           # c("poverty_headcount", "gini", "mean_welfare")
  breakdowns,         # c("gender", "area")
  welfare_var,        # "welfare_ppp"
  poverty_lines = 1.9,
  weight_var = "weight",
  include_totals = TRUE
) -> data.frame

# Output columns
data.frame(
  country = "COL",
  year = 2010,
  gender = "male",              # breakdown dimensions (if requested)
  area = "urban",
  measure = "poverty_headcount",
  poverty_line = 1.9,           # only for poverty measures
  value = 0.154,                # computed indicator
  se = 0.012,                   # standard error
  n_weighted = 1234567,         # total weighted sample
  n_unweighted = 1234           # unweighted count
)
```

### Supported Measures (Phase 1 MVP)

- `poverty_headcount`: Proportion below poverty line (wrap {pipster} if available)
- `poverty_gap`: Average depth; requires: `sum((poverty_line - welfare) * poor) / weighted_pop`
- `mean_welfare`: Weighted mean of welfare variable
- `median_welfare`: Weighted 50th percentile
- `gini`: Gini coefficient with sampling weights
- `population`: Total weighted population

**Phase 2 Extensions**:
- Additional measures if needed

### Key Implementation Details

**Grouping & Aggregation**:
- Use `data.table` grouped operations for speed
- Apply weights in all aggregations via `collapse::collapv()` or {data.table} `by`
- Standard errors require variance estimation (design-based with weights)

**Multiple Poverty Lines**:
- Create all derived variables upfront: `poor_1_9 = welfare < 1.9`, `poor_3_2 = welfare < 3.2`
- Compute poverty headcount once per line to avoid redundant computation
- Result: Multiple rows per group (one per poverty line)

**Subgroup Totals**:
- If user requests breakdown by gender, compute totals across all gender values
- Include as row with gender="all" or gender=NA (TBD in Q6)
- Use weighted aggregate of all gender groups

**Standard Errors** (Design-Based):
- For weighted statistics, SE depends on sampling design
- Proposed: Use design-based SE (assuming simple random sampling with weights)
- Formula for mean: `SE = sqrt(V / n_unweighted)` where V is weighted variance
- Formula for proportions: `SE = sqrt(p * (1-p) / eff_n)` where eff_n = (sum(w))^2 / sum(w^2)

**Performance Optimization**:
- **Data Loading**: Arrow partition pruning is critical (avoid loading unnecessary welfare types)
- **Grouping**: Use data.table key-based grouping for sorted joins
- **Gini Computation**: Profile separately; typically 30-50% of compute time for inequality-heavy queries
- **Memory**: Monitor data.frame size in memory; consider streaming for very large surveys

## 5. API Layer 

### Request Schema

```json
{
  "surveys": [
    { "country": "COL", "year": 2010 },
    { "country": "COL", "year": 2012 }
  ],
  "measures": [
    { "measure_name": "poverty_headcount", "poverty_lines": [1.9, 3.2] },
    { "measure_name": "gini_coefficient" },
    { "measure_name": "mean_welfare" }
  ],
  "breakdowns": ["gender", "area", "education"],
  "welfare_type": "consumption",
  "include_totals": true,
  "format": "json"
}
```

### Response Schema: Success

```json
{
  "status": "success",
  "request_id": "req-abc123",
  "computation_time_ms": 456,
  "data_version": "2026-03-04T15:30:00Z",
  "data": [
    {
      "country": "COL",
      "year": 2010,
      "gender": "male",
      "area": "urban",
      "education": "primary",
      "measure_name": "poverty_headcount",
      "poverty_line": 1.9,
      "value": 0.154,
      "se": 0.012,
      "n_weighted": 1234567,
      "n_unweighted": 1234
    }
  ],
  "metadata": {
    "surveys_returned": 2,
    "rows_returned": 48,
    "surveys_not_found": [],
    "breakdown_positions": {
      "columns": "gender",
      "rows": "area",
      "super_columns": "education",
      "super_rows": null
    },
    "missing_dimensions": [],
    "warnings": []
  }
}
```

### Response Schema: Partial Success

```json
{
  "status": "partial",
  "request_id": "req-abc124",
  "computation_time_ms": 234,
  "data_version": "2026-03-04T15:30:00Z",
  "data": [
    {
      "country": "COL",
      "year": 2010,
      "gender": "male",
      "area": "urban",
      "education": null,
      "measure_name": "poverty_headcount",
      "poverty_line": 1.9,
      "value": 0.154,
      "se": 0.012,
      "n_weighted": 1234567,
      "n_unweighted": 1234
    }
  ],
  "metadata": {
    "surveys_returned": 2,
    "rows_returned": 24,
    "surveys_not_found": ["HND_2006"],
    "breakdown_positions": {
      "columns": "gender",
      "rows": "area",
      "super_columns": "education",
      "super_rows": null
    },
    "missing_dimensions": [
      {
        "survey": "BRA_2018",
        "missing": ["education"]
      }
    ],
    "warnings": [
      "Survey HND_2006 not found; skipped.",
      "Survey BRA_2018 lacks 'education' variable; returned with education=NA."
    ]
  }
}
```
### Response Schema: Error

```json
{
  "status": "error",
  "request_id": "req-abc125",
  "error_code": "INVALID_SURVEY",
  "error_message": "Survey 'COL_2099' does not exist. Available years: 2008, 2010, 2012...",
  "data": null
}
```


### Common Error Codes

- `INVALID_SURVEY`: Requested survey doesn't exist
- `INVALID_MEASURE`: Unsupported measure requested
- `INVALID_BREAKDOWN`: Breakdown dimension not available
- `MISSING_VARIABLE`: Required variable missing in survey
- `COMPUTATION_ERROR`: Server error during computation
- `INVALID_INPUT`: Malformed or invalid request

### Implementation Flow (Plumber)

```r
#' @post /api/table-maker
function(req) {
  
  # 1. Log request
  log_request(req)
  
  # 2. Validate input
  validation <- validate_table_maker_request(req)
  if (!validation$valid) return(error_response(validation$errors))
  
  # 3. Load survey metadata
  survey_metadata <- load_survey_metadata()
  
  # 4. Check survey availability
  missing <- identify_missing_surveys(req$surveys, survey_metadata)
  if (length(missing) == length(req$surveys)) {
    return(error_response("All requested surveys not found"))
  }
  
  # 5. Load filtered Arrow data
  arrow_data_list <- lapply(req$surveys, function(survey) {
    arrow::open_dataset(arrow_root) %>%
      filter(country_code == !!survey$country,
             surveyid_year == !!survey$year) %>%
      collect()
  })
  
  # 6. Call computation engine
  tryCatch({
    results <- table_maker_compute(
      surveys = arrow_data_list,
      measures = req$measures,
      breakdowns = req$breakdowns,
      welfare_var = req$welfare_type,
      poverty_lines = extract_poverty_lines(req$measures),
      weight_var = "weight"
    )
    return(success_response(results, missing))
  }, error = function(e) {
    log_error(e)
    return(error_response("Computation failed", e$message))
  })
}
```

## 6. Survey Metadata Management (Release-Based Manifest)

### Release Metadata Manifest

All survey metadata is defined in a **Release Metadata Manifest** JSON file that is generated once per PIP release and embedded in the {piptm} package:

**Location**: `inst/release_manifest_2026-03-04.json` (or date of release)

```json
{
  "release_date": "2026-03-04T00:00:00Z",
  "pipdata_version": "0.8.2",
  "datasets": [
    {
      "country": "COL",
      "country_name": "Colombia",
      "year": 2010,
      "survey_id": "COL_2010_GEIH_V1",
      "welfare_type": "INC",
      "welfare_var": "income",
      "weight_var": "weight",
      "n_weighted": 12345678,
      "n_unweighted": 5432,
      "available_breakdowns": ["gender", "area", "education", "age"]
    },
    {
      "country": "COL",
      "country_name": "Colombia",
      "year": 2012,
      "survey_id": "COL_2012_GEIH_V1",
      "welfare_type": "INC",
      "welfare_var": "income",
      "weight_var": "weight",
      "n_weighted": 13245678,
      "n_unweighted": 5832,
      "available_breakdowns": ["gender", "area", "education", "age"]
    },
    {
      "country": "IND",
      "country_name": "India",
      "year": 2011,
      "survey_id": "IND_2011_NSS_V1",
      "welfare_type": "CON",
      "welfare_var": "consumption",
      "weight_var": "weight",
      "n_weighted": 98765432,
      "n_unweighted": 101234,
      "available_breakdowns": ["gender", "area"]
    }
  ],
  "excluded_countries": ["CHN"],
  "excluded_partitions": ["reporting_level"],
  "excluded_surveys": [],
  "metadata_notes": "CHN excluded because only group aggregates available (no microdata). Reporting level excluded as all included countries have NATIONAL only."
}
```

### Key Characteristics

1. **Static**: Generated once per PIP release, does not change at runtime
2. **Complete**: Lists all available surveys and their properties
3. **Comprehensive**: Includes breakdown availability, sample sizes, welfare variable names
4. **Self-Documenting**: Explains exclusions and design decisions

### API Initialization

```r
# At package load time:
.onLoad <- function(libname, pkgname) {
  # Load release manifest from package
  manifest_file <- system.file("release_manifest_2026-03-04.json", package = "piptm")
  .piptm_manifest <<- jsonlite::read_json(manifest_file)
}

# API endpoint validation:
validate_request <- function(request) {
  surveys_requested <- request$surveys
  
  # Check against manifest
  available_surveys <- .piptm_manifest$datasets |>
    lapply(function(x) paste0(x$country, "_", x$year)) |>
    unlist()
  
  not_found <- setdiff(
    paste0(surveys_requested$country, "_", surveys_requested$year),
    available_surveys
  )
  
  if (length(not_found) > 0) {
    return(list(valid = FALSE, error = paste("Surveys not found:", paste(not_found, collapse = ", "))))
  }
  
  return(list(valid = TRUE))
}
```

### No Runtime Dataset Discovery

- API does NOT scan Arrow directory for available datasets
- API does NOT query {pipdata} package for survey metadata
- API ONLY uses manifest to determine what datasets exist
- Ensures consistent, predictable behavior per release
- Manifest can be version-controlled and audited

## 7. Versioning Strategy (Release-Based)

### Release Versioning

Versioning is tied to **PIP Release Cycles**, not individual partition updates:

```
Release: PIP 2026-03-04
├─ Version string: "2026-03-04"
├─ Release date: 2026-03-04T00:00:00Z
├─ Included {pipdata} version: 0.8.2
├─ Included Arrow datasets: All surveys in release manifest
├─ API version: 1.0 (no breaking changes within release)
└─ {piptm} package version: 1.0.2 (patch for this release)
```

### Version Information in API Response

Every API response includes the release date:

```json
{
  "status": "success",
  "request_id": "req-abc123",
  "computation_time_ms": 456,
  "data_version": "2026-03-04T15:30:00Z",
  "data": [ /* results */ ]
}
```

### Updating to New Release

When PIP releases new data:

1. **Generate new Arrow datasets** from updated {pipdata}
2. **Create new release manifest** (e.g., `release_manifest_2026-06-15.json`)
3. **Update {piptm} package**:
   - Add new manifest file
   - Update default manifest path in .onLoad()
   - Bump minor version (e.g., 1.1.0)
4. **Deploy API** with new {piptm} version

Old releases remain available by installing older {piptm} versions.

### No Per-Partition Versioning

Unlike the original design, we do NOT track versions per partition (country-year-welfare_type):
- **Before**: reporting_level=NATIONAL v1.2, reporting_level=URBAN v1.1, etc.
- **Now**: All datasets in a release have same version (release date)
- **Rationale**: Simpler version management, clearer release semantics, easier deployment

## 8. Breakdown Dimension Ordering Logic

### Table Structure Determination

The user-specified `breakdowns` vector order determines the final table structure:

```
breakdowns[1] → columns (innermost horizontal dimension)
breakdowns[2] → rows (innermost vertical dimension)
breakdowns[3] → super_columns (outer horizontal dimension)
breakdowns[4] → super_rows (outer vertical dimension)
breakdowns[5+] → Not supported (maximum 4 dimensions)
```

### Examples

**Example 1: Single Breakdown**
```r
breakdowns = ["gender"]
# Result: Columns structure
# | female | male | all |
# |--------|------|-----|
# | value  | value| value |
```

**Example 2: Two Breakdowns**
```r
breakdowns = ["gender", "area"]
# Result: 
#         female       male         all
#       urban rural  urban rural  urban rural
# ------+------+-----+------+-----+------+-----+
#        value  value value  value value  value
```

**Example 3: Three Breakdowns**
```r
breakdowns = ["gender", "area", "education"]
# Result: super_columns=education, columns=gender, rows=area
#
#         education=primary         education=secondary       education=all
#       female       male          female       male          female      male
#     urban rural  urban rural    urban rural  urban rural  urban rural  urban rural
# ----+------+-----+------+-----+------+-----+------+-----+------+-----+------+-----+
#      value value value value  value value value value  value value value value
```

**Example 4: Four Breakdowns**
```r
breakdowns = ["gender", "area", "education", "age_group"]
# Result: super_rows=age_group, super_columns=education, columns=gender, rows=area
#
# age_group=15-24
#         education=primary         education=secondary       ...
#       female       male          female       male
#     urban rural  urban rural    urban rural  urban rural
# ----+------+-----+------+-----+------+-----+------+-----+
#      value value value value  value value value value
#
# age_group=25-34
#         education=primary         education=secondary       ...
#  ...
```

### Implementation in API Response

The API response structure is data-centric (not pre-formatted as a table), but includes `breakdown_positions` metadata:

```json
{
  "data": [
    {
      "country": "COL",
      "year": 2010,
      "gender": "female",
      "area": "urban",
      "education": "primary",
      "age_group": "15-24",
      "measure": "poverty_headcount",
      "value": 0.154
    },
    {
      "country": "COL",
      "year": 2010,
      "gender": "female",
      "area": "urban",
      "education": "primary",
      "age_group": "25-34",
      "measure": "poverty_headcount",
      "value": 0.142
    }
    // ... more rows ...
  ],
  "metadata": {
    "breakdown_positions": {
      "columns": "gender",
      "rows": "area",
      "super_columns": "education",
      "super_rows": "age_group"
    }
  }
}
```

**Client-Side Responsibility**:
- Client receives breakdown_positions metadata
- Client uses this to format the table structure
- Client iterates through data rows and places values in correct table cells

### Ordering Validation

At request time, validate:
- `breakdowns` array has 1-4 elements
- All breakdown names are valid column names
- All breakdowns exist in all requested surveys (or return NA for missing)
- No duplicate breakdowns in the array

## 10. Logging Strategy

### Request Logging

Log each API query with:

```json
{
  "request_id": "uuid-1234",
  "timestamp": "2026-03-04T15:30:00Z",
  "user_id": "user@example.com",
  "surveys_requested": ["COL_2010", "COL_2012"],
  "measures_requested": ["poverty_headcount", "mean_welfare"],
  "breakdowns_requested": ["gender"],
  "status": "success|error|partial",
  "rows_returned": 4,
  "computation_time_ms": 245,
  "arrow_data_version": "2026-03-04T15:30:00Z",
  "error_message": null
}
```

### Logging Infrastructure

- Framework: {logger} or {serilog}
- Store: Server logs or logging service
- Monitor: Track performance, errors, and usage patterns

## 11. Performance Considerations -for later
