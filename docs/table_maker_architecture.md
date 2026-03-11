# Table Maker Architecture

## 1. System Overview

Table Maker is a feature enabling dynamic computation of poverty and inequality indicators from microdata. Users can:
- Select up to 15 surveys (country-year pairs)
- Request multiple measures (poverty headcount, Gini, mean welfare, etc.)
- Specify up to 3 breakdown dimensions (gender, age, education, area, etc.)
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
Computation Engine ({piptb} package)
    ↓
API Layer (Plumber, {piptbapi} package)
    ↓
Platform UI
```

### Input Data Sources

- **Raw Surveys**: AGO_2008_IBEP_ALL.csv, ALB_2005_LSMS_ALL.csv, etc.
- **Location**: Y-drive (raw survey files)
- **Format**: CSV

### Harmonization Pipeline

Handled by {pipdata} package:
- Standardize variable names, units, definitions
- Validate data quality
- Ensure analysis-ready format

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

Partitioned by key dimensions for efficient filtering:

```
arrow_data/parquet/
├─ country_code=COL/
│  ├─ surveyid_year=2010/
│  │  ├─ welfare_type=INC/
│  │  │  └─ reporting_level=NATIONAL/
│  │  │     ├─ part-0.parquet
│  │  │     └─ part-1.parquet
│  │  └─ welfare_type=CON/
│  │     └─ reporting_level=NATIONAL/
│  │        └─ part-0.parquet
│  └─ surveyid_year=2012/
│     ├─ welfare_type=INC/...
│     └─ welfare_type=CON/...
└─ country_code=IND/
   └─ [similar structure]
```

### Partition Dimensions

- **country_code**: Country (e.g., COL, IND)
- **surveyid_year**: Survey year (e.g., 2010, 2015)
- **welfare_type**: Income (INC) or Consumption (CON)
- **reporting_level**: NATIONAL, URBAN, RURAL, etc.

### Generation Strategy

**Recommended Approach: Smart On-Demand with Version Tracking**

- **Version Tracking**: Each partition records:
  - Source data hash (SHA256 of .qs2 file)
  - Source file timestamp
  - Arrow creation timestamp
  - {pipdata} version used
  - Data lineage (file path, row count, size)

- **Staleness Detection**:
  - Before API query: Check if source .qs2 file hash matches recorded hash
  - Match → Use existing partition
  - Mismatch → Regenerate partition
  - Missing → Generate on first request

- **Optional Pre-Generation**:
  - During PIP releases, proactively regenerate changed partitions
  - Result: ~90% of queries hit pre-generated data
  - Remaining ~10%: On-demand generation

## 4. Computation Engine ({piptb} Package)

### Current State & Refactoring Needs

The current {piptb} package is legacy code that performs computation but requires significant restructuring for Table Maker:

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

**Phase 1: Create Measure-Specific Functions**

Replace the generic `tb()` function with specialized functions:

```r
# Core poverty measures
compute_poverty_headcount(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: weighted proportion of population below poverty_line
  
compute_poverty_gap(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: average depth of poverty (normalized gap)
  
compute_poverty_severity(microdata, welfare_var, poverty_line, weight_var)
  └─ Returns: squared poverty gap (Foster-Greer-Thorbecke P2)

# Welfare measures
compute_mean_welfare(microdata, welfare_var, weight_var)
  └─ Returns: weighted mean welfare level
  
compute_median_welfare(microdata, welfare_var, weight_var)
  └─ Returns: weighted percentile at 50th position
  
compute_percentile(microdata, welfare_var, weight_var, percentile = c(10, 25, 75, 90))
  └─ Returns: weighted percentile at specified levels

# Inequality measures
compute_gini(microdata, welfare_var, weight_var)
  └─ Returns: Gini coefficient (requires specialized algorithm with weights)
  
compute_population(microdata, weight_var)
  └─ Returns: total weighted population

# Proposed implementation approach:
# - Leverage {pipster} functions where available (e.g., poverty headcount)
# - For missing measures, implement using data.table + collapse for speed
# - All functions accept pre-grouped data and compute within groups
```

**Phase 2: Create API-Facing Orchestrator**

Replace/refactor `table_baker()` into a true computation orchestrator:

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

**Phase 3: Decompose Current Logic**

Current issues in existing functions:

- **`tb()` function problems**:
  - Line 75-84: Generic stats selection doesn't support poverty gap, Gini
  - Line 86-103: Poverty line handling hard-coded for binary poor/not-poor; can't compute multiple statistics at same poverty line
  - Line 105-135: collapse::collapv() provides only basic aggregations; can't compute standard errors
  - Line 160-180: Output formatting mixes column naming logic; not suitable for API responses

- **`tb_heap()` function problems**:
  - Line 15-25: Generates ALL possible dimension combinations (1-way, 2-way, 3-way, 4-way)
  - Line 31-40: Calls `tb()` for each combination; massive redundant computation
  - Line 60-68: Adds prefix columns; extra processing overhead
  - Use case: Batch pre-computation only; unusable for API on-demand queries

**Migration Path**:
1. Keep `table_baker()` as Arrow filtering layer
2. Remove dependency on `tb()` and `tb_heap()` for API
3. Implement measure-specific functions independently
4. Create new `table_maker_compute()` orchestrator
5. Optional: Retain legacy `tb()` for backward compatibility in other tools

### High-Level Computation Flow (New Design)

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
- Additional percentiles (10th, 25th, 75th, 90th)
- Poverty severity (Foster-Greer-Thorbecke P2)
- Additional inequality measures if needed

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

## 5. API Layer ({piptbapi} Package)

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
  "breakdowns": ["gender", "area"],
  "welfare_type": "consumption",
  "reporting_level": "national",
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
  "data": [ /* results for available surveys */ ],
  "metadata": {
    "surveys_returned": 2,
    "rows_returned": 24,
    "surveys_not_found": ["HND_2006"],
    "warnings": [
      "Survey HND_2006 not found; skipped.",
      "Survey BRA_2018 lacks 'age' variable; returned without age breakdown."
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

## 6. Survey Metadata Management

### What to Store

Minimally required metadata:
- **Survey Inventory**: List of all available country-year pairs
- **Variable Inventory**: Which variables exist per survey (used to validate requested breakdowns)

### Implementation Strategy

**Option 1: Load from {pipdata} (Recommended)**
- On API startup, scan all survey metadata .qs2 files
- Build in-memory lookup table:
  ```r
  survey_variables <- list(
    "COL_2010_INC" = c("welfare", "gender", "age", "area", ...),
    "BOL_2008_CON" = c("welfare", "gender", "area", ...)
  )
  ```

**Option 2: Extract from Arrow Schema**
- Arrow already knows its columns
- Check schema when loading partition
- Slightly slower but requires no preprocessing

## 7. Versioning Strategy

### Arrow Dataset Metadata Manifest

Store version information with each Arrow partition:

```
├─ Generation timestamp: 2026-03-04T15:30:00Z
├─ {pipdata} version: 0.8.2
├─ {pipdata} Git commit: abc123def456
├─ Source surveys:
│  ├─ AGO_2008: hash=xyz789
│  ├─ ALB_2005: hash=abc123
│  └─ [all with content hash]
├─ Harmonization scripts version: v1.2.3
├─ Arrow format version: 1.0
├─ Total surveys: 450
├─ Total microdata rows: 12,345,678
└─ Data lineage: traceable from raw → harmonized → Arrow
```

### Versioning Components

Track versions of:
- {pipdata} harmonization
- Arrow dataset generation
- {piptb} computation engine

## 8. Logging Strategy

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

## 9. Performance Considerations

### Latency Targets

- Typical query (<5 surveys, <5 measures, <2 breakdowns): **<2 seconds**
- Medium query (10 surveys, 8 measures, 2 breakdowns): **<10 seconds**
- Large query (15 surveys, 15 measures, 3 breakdowns): **<30 seconds**
- Target maximum: **60 seconds** before timeout

### Memory Constraints

- Benchmark typical query memory usage
- Set max query size at ~80% of available memory
- Return 400 error if exceeded
- Consider safeguards for large datasets

### Optimization Strategies

- **Arrow Partitioning**: Leverage partition pruning to minimize data loaded
- **In-Memory Computation**: Use data.table and collapse for fast aggregation
- **Poverty Lines**: Compute multiple lines in single pass
- **Caching**: Implement result caching for identical queries (cleared on PIP releases)

### Data Transfer Size

Estimate typical response sizes:
- 3 surveys × 2 measures × 2 breakdowns × 1 poverty line = 12 rows
- ~200 bytes per row (JSON) = ~2.4 KB
- Typical responses: **<100 KB**
- Large responses: **<5 MB** (gzip compression available if needed)

## 10. Data Quality & Validation

### Request Validation

Before computation, validate:
- Surveys exist and are available
- Measures are supported
- Breakdown dimensions are valid
- Requested variables exist in selected surveys
- Poverty lines are numeric and positive

### Handling Missing Data

**Missing Breakdowns**: If user requests age breakdown but survey lacks age variable
- Skip that survey with warning
- Return results for surveys with the variable
- Include warning in response metadata

**Partial Data Availability**: If user requests COL 2010, 2012, 2015 but 2015 is incomplete
- Return results for 2010-2012
- Include missing surveys in metadata
- Status: "partial"

**Empty Groups**: After filtering/grouping, a combination has zero observations
- Return zero or null value (TBD)
- Include sample size (n=0)
- Document in output
