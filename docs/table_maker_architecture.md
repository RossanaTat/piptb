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

### High-Level Computation Flow

```
1. Validate input
   ├─ Check surveys exist
   ├─ Check measures supported
   └─ Check dimensions valid

2. Load filtered microdata
   └─ Arrow filter(country, year, welfare_type, reporting_level) → collect()

3. For each (measure, dimension_combination):
   ├─ 3a. Pre-compute derived variables if needed
   ├─ 3b. Group microdata by dimensions
   ├─ 3c. Call computation function
   └─ 3d. Collect results

4. Combine results
   └─ Aggregate into single output table

5. Return to API
```

### Supported Measures

Core computation functions (implementations leverage {pipster} where available):

- `compute_poverty_headcount()` - Proportion below poverty line
- `compute_poverty_gap()` - Average depth of poverty
- `compute_poverty_severity()` - Squared poverty gap
- `compute_mean_welfare()` - Average welfare
- `compute_median_welfare()` - Median welfare
- `compute_gini()` - Gini coefficient
- `compute_population()` - Weighted population count

### Computation Interface

```r
table_maker_compute(
  surveys,          # list of data.frames (filtered from Arrow)
  measures,         # c("poverty_headcount", "mean_welfare", "gini")
  breakdowns,       # c("gender", "area") — up to 3
  welfare_var,      # "welfare_ppp" or "welfare_lcu"
  poverty_lines,    # c(1.9, 3.2) — for poverty measures
  weight_var = "weight",
  subgroup_totals = TRUE
) -> data.frame
```

### Output Format

```r
data.frame(
  country = "COL",
  year = 2010,
  gender = "male",           # if in breakdowns
  area = "urban",            # if in breakdowns
  measure = "poverty_headcount",
  poverty_line = 1.9,        # if applicable
  value = 0.154,
  se = 0.012,                # standard error
  n_weighted = 1234567,
  n_unweighted = 1234
)
```

### Key Implementation Details

- **Sampling Weights**: All aggregations apply weights using collapse::collapv() or equivalent
- **Multiple Poverty Lines**: Compute all in one pass to minimize re-computation
- **Subgroup Totals**: Include "all" rows when breakdowns requested (e.g., gender="all")
- **Performance**: Profile and optimize data loading, grouping, and aggregation (Gini typically slowest)

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
