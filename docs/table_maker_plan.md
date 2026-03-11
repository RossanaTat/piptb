# TABLE MAKER IMPLEMENTATION PLAN

## PHASE 1 — ARCHITECTURE VALIDATION & CRITICAL DESIGN DECISIONS

This phase resolves all critical architectural decisions and investigates existing code/packages to define the implementation approach.

- [ ] Step 1.1: Investigate {pipster} and related PIP packages
  - **Objective**: Determine which poverty and inequality measures are available in {pipster} and other PIP packages
  - **Tasks**:
    - Review {pipster} package exports for measure functions (e.g., `pipgd_pov_headcount()`, `pipgd_pov_gap()`, inequality functions)
    - Examine {wbpip} package for Gini coefficient and percentile computation functions
    - Identify function signatures, parameter requirements, and handling of sampling weights
    - Determine whether functions can handle grouped computation or require looping
    - Test compatibility with Arrow/data.table data sources
    - Document findings and limitations
  - **Outputs**:
    - Inventory of available measure functions from {pipster}, {wbpip}, and other packages
    - Compatibility assessment matrix (function name, can_handle_weights, can_handle_grouped_data, can_handle_multiple_lines)
    - Recommendation: which measures to wrap vs. implement custom
  - **Deliverables**:
    - Technical memo: `pipster_and_wbpip_inventory.md`
  - **Dependencies**: None

- [ ] Step 1.2: Resolve Q8 — Measure Computation Strategy
  - **Objective**: Decide between wrapping {pipster} functions or implementing custom measure functions
  - **Tasks**:
    - Based on Step 1.1 findings, evaluate pros/cons of wrapping vs. implementing custom
    - For Gini coefficient: decide whether to implement custom function or use alternative package
    - For multiple poverty lines: determine whether to loop over {pipster} functions or compute once with custom implementation
    - For grouped computation: assess {pipster} capability vs. wrapper complexity
    - Document decision with rationale
  - **Outputs**:
    - Measure computation strategy document
    - Decision matrix: (measure_name, approach, rationale, package_dependencies)
    - Phase 1 measure list for MVP (poverty_headcount, poverty_gap, mean_welfare, median_welfare, gini, population)
  - **Deliverables**:
    - Design document: `measure_computation_strategy.md`
  - **Dependencies**: Step 1.1

- [ ] Step 1.3: Resolve Q3 — Welfare Type Selection
  - **Objective**: Decide whether users or system select welfare type
  - **Tasks**:
    - Consult product/API stakeholders on user experience preferences
    - Review current survey metadata structure to understand default welfare types
    - Determine API schema impact (additional request parameter vs. survey metadata lookup)
    - Document decision
  - **Outputs**:
    - API parameter specification (if user-selected: `welfare_type` field in request schema)
    - Survey metadata structure definition
  - **Deliverables**:
    - Decision document: `welfare_type_selection.md`
  - **Dependencies**: None

- [ ] Step 1.4: Resolve Q7 — Missing Breakdown Variable Handling
  - **Objective**: Decide whether to fail entire request or skip survey with warning
  - **Tasks**:
    - Evaluate multi-survey query UX impact
    - Design warning message format and response schema
    - Document decision and error handling approach
  - **Outputs**:
    - Decision: fail vs. skip with warning
    - Response schema for partial success (status: "partial", warnings: [...])
    - Error message templates
  - **Deliverables**:
    - Decision document: `missing_variables_handling.md`
  - **Dependencies**: None

- [ ] Step 1.5: Resolve Q1 — Arrow Generation Trigger Strategy
  - **Objective**: Decide on on-demand vs. hybrid batch+on-demand Arrow generation
  - **Tasks**:
    - Estimate computation cost for Arrow generation per survey
    - Consult deployment team on infrastructure availability
    - If hybrid: design version tracking and staleness detection mechanism
    - Document decision and implementation approach
  - **Outputs**:
    - Decision: on-demand vs. hybrid
    - If hybrid: version tracking schema and staleness detection algorithm
    - Batch generation schedule (if applicable)
  - **Deliverables**:
    - Decision document: `arrow_generation_strategy.md`
  - **Dependencies**: None

- [ ] Step 1.6: Resolve Q11 — Synchronous vs. Asynchronous API Execution
  - **Objective**: Decide on sync, async, or hybrid execution model
  - **Tasks**:
    - Establish performance baseline (typical query latency)
    - Consult stakeholders on acceptable timeout
    - If hybrid: design job queue, polling mechanism, response schema for 202 Accepted
    - Document decision and implementation approach
  - **Outputs**:
    - Decision: sync, async, or hybrid
    - Timeout value (default: 60 seconds)
    - If async: job queue design, polling schema, job status schema
  - **Deliverables**:
    - Decision document: `api_execution_model.md`
  - **Dependencies**: None

- [ ] Step 1.7: Resolve Q2 — Survey Metadata Storage & Loading
  - **Objective**: Decide whether to load from {pipdata} at startup or extract from Arrow schema
  - **Tasks**:
    - Test whether {pipdata} metadata can be reliably loaded as .qs2 files
    - Profile load time and in-memory size
    - Compare with Arrow schema extraction approach
    - Document decision and implementation strategy
  - **Outputs**:
    - Decision: {pipdata} vs. Arrow schema
    - If {pipdata}: metadata loading function and caching strategy
    - Survey metadata lookup table schema
  - **Deliverables**:
    - Decision document: `survey_metadata_loading.md`
  - **Dependencies**: None

- [ ] Step 1.8: Finalize MVP Feature Set and Response Schema
  - **Objective**: Lock down Q5, Q6, Q16 — response format and included metadata
  - **Tasks**:
    - Confirm output format for multiple poverty lines: separate rows (recommended) or columns
    - Confirm subgroup totals: always include (recommended) or optional
    - Confirm standard errors: include SE, include SE+CI, or omit
    - Design complete response schema (success, partial, error cases)
    - Document examples for each response type
  - **Outputs**:
    - Complete response schema in JSON with examples
    - Field descriptions and metadata specifications
    - Error response schema and error codes
  - **Deliverables**:
    - Response schema specification: `api_response_schema.md`
  - **Dependencies**: Steps 1.3, 1.4, 1.7

- [ ] Step 1.9: Design Input Validation Rules (Q19)
  - **Objective**: Establish comprehensive request validation rules
  - **Tasks**:
    - Define survey validity rules (exists in Arrow, has required welfare type, etc.)
    - Define measure validity rules (in supported list, poverty lines numeric/positive)
    - Define breakdown validity rules (max 3 dimensions, required variables exist per survey)
    - Define welfare variable rules (support PPP vs. LCU selection)
    - Design validation error messages with helpful hints
  - **Outputs**:
    - Validation specification document with rules matrix
    - Error messages and hints for each validation failure
  - **Deliverables**:
    - Validation rules specification: `request_validation_rules.md`
  - **Dependencies**: Steps 1.2, 1.3, 1.7

- [ ] Step 1.10: Design Caching and Rate Limiting Strategy (Q12, Q13, Q14)
  - **Objective**: Decide on caching strategy and authentication/rate limiting policy
  - **Tasks**:
    - Decide: smart cache with PIP release invalidation (recommended) or no caching
    - Design cache key format (request hash, parameter-based, or other)
    - Decide: public API with light rate limiting (recommended) or authenticated
    - If rate limiting: decide thresholds (10 req/min per IP for MVP)
    - Design monitoring metrics for cache hit rates, error rates
  - **Outputs**:
    - Caching strategy (with TTL, invalidation rules, monitoring)
    - Rate limiting policy (thresholds, enforcement method)
    - Authentication policy (public vs. authenticated)
  - **Deliverables**:
    - Strategy document: `caching_and_rate_limiting.md`
  - **Dependencies**: None

- [ ] Step 1.11: Finalize Architectural Design Document
  - **Objective**: Consolidate all decisions from Phase 1 into single comprehensive design spec
  - **Tasks**:
    - Integrate all sub-decisions (Q1–Q14, Q19) into cohesive design
    - Create system architecture diagram showing data flow with all decisions embedded
    - Define component interfaces and contracts
    - Establish naming conventions and coding standards
    - Create glossary of terms
  - **Outputs**:
    - Complete architectural design specification
    - System architecture diagrams
    - Component interface definitions
    - Coding standards document
  - **Deliverables**:
    - Comprehensive design document: `TABLE_MAKER_DESIGN_SPECIFICATION.md`
  - **Dependencies**: All Steps 1.1–1.10

---

## PHASE 2 — ARROW DATASET INFRASTRUCTURE

This phase establishes the Arrow dataset foundation, including partitioning, version tracking, and data loading.

- [ ] Step 2.1: Review and Document Current Arrow Setup
  - **Objective**: Understand existing Arrow dataset structure and configuration
  - **Tasks**:
    - Review current Arrow location, partitioning scheme, and file organization
    - Document partition dimensions (country_code, surveyid_year, welfare_type, reporting_level)
    - Identify metadata currently stored (if any)
    - Review `table_baker()` function to understand filtering logic
    - Document any limitations or gaps
  - **Outputs**:
    - Current Arrow setup documentation
    - Partition structure diagram
  - **Deliverables**:
    - Documentation: `arrow_current_setup.md`
  - **Dependencies**: None

- [ ] Step 2.2: Implement Version Tracking Mechanism (if hybrid generation)
  - **Objective**: Add version tracking to Arrow partitions for staleness detection
  - **Conditional**: Only if Q1 decision is "hybrid batch+on-demand"
  - **Tasks**:
    - Design version metadata schema (source hash, timestamps, versions, lineage)
    - Implement metadata file format (JSON or YAML) per partition
    - Create function to compute source data hash (SHA256 of .qs2 files)
    - Create function to check staleness (compare current hash to stored hash)
    - Create function to update metadata after generation
  - **Outputs**:
    - Version tracking module with functions:
      - `compute_source_hash(survey_qs2_path) -> character`
      - `check_partition_staleness(partition_dir) -> logical`
      - `update_partition_metadata(partition_dir, metadata_list)`
    - Metadata schema documentation
  - **Deliverables**:
    - R module: `R/arrow_version_tracking.R`
    - Documentation: `arrow_version_tracking.md`
  - **Dependencies**: Step 1.5 (Arrow generation strategy decision)

- [ ] Step 2.3: Implement Survey Metadata Loader
  - **Objective**: Create function to load and cache survey metadata
  - **Tasks**:
    - Implement metadata loading function (from {pipdata} or Arrow schema per Step 1.7 decision)
    - Cache metadata in package global (similar to `gls$TB_ARROW`)
    - Create function to validate requested breakdowns against available variables
    - Create function to check welfare type availability per survey
    - Add unit tests for metadata functions
  - **Outputs**:
    - Metadata loading module with functions:
      - `load_survey_metadata(source) -> list`
      - `validate_breakdown_dimensions(survey, breakdowns) -> logical`
      - `check_welfare_type_availability(survey, welfare_type) -> logical`
    - Unit tests for metadata validation
  - **Deliverables**:
    - R module: `R/metadata_loader.R`
    - Test file: `tests/testthat/test-metadata_loader.R`
  - **Dependencies**: Step 1.7 (survey metadata strategy decision)

- [ ] Step 2.4: Enhance table_baker() Function for API Use
  - **Objective**: Refactor `table_baker()` to support API queries with improved filtering
  - **Tasks**:
    - Simplify function signature: focus on (country_codes, years, welfare_type, reporting_level)
    - Update filtering logic to support welfare_type and reporting_level parameters
    - Add input validation for country codes, year ranges, welfare types
    - Add error messages for unavailable combinations
    - Preserve backward compatibility with legacy usage (if needed)
    - Add unit tests for filtering and edge cases
  - **Outputs**:
    - Refactored `table_baker()` function with improved signature and validation
    - Unit tests covering typical queries and edge cases
  - **Deliverables**:
    - Updated R module: `R/table_baker.R`
    - Test file: `tests/testthat/test-table_baker_enhanced.R`
  - **Dependencies**: Steps 2.1, 2.3

- [ ] Step 2.5: Implement Arrow Generation Function (if hybrid)
  - **Objective**: Create function to generate Arrow partitions on-demand
  - **Conditional**: Only if Q1 decision is "hybrid batch+on-demand"
  - **Tasks**:
    - Create function to load microdata from {pipdata} via pipload
    - Create function to convert microdata to Arrow Parquet format
    - Create function to write with appropriate partitioning
    - Create function to update version metadata
    - Add error handling for missing data or load failures
    - Add logging for generation progress
    - Add unit tests
  - **Outputs**:
    - Generation module with functions:
      - `generate_arrow_partition(country, year, welfare_type) -> logical`
      - `batch_generate_arrow_partitions(country_list) -> data.frame`
    - Unit tests for generation and error cases
  - **Deliverables**:
    - R module: `R/arrow_generation.R`
    - Test file: `tests/testthat/test-arrow_generation.R`
  - **Dependencies**: Step 2.2 (version tracking)

- [ ] Step 2.6: Integration Test for Arrow Data Workflow
  - **Objective**: Verify full Arrow loading and filtering workflow
  - **Tasks**:
    - Create integration test that loads sample Arrow data
    - Test filtering by country, year, welfare_type, reporting_level
    - Verify metadata availability and breakdown validation
    - Test edge cases (missing welfare types, unavailable breakdowns)
  - **Outputs**:
    - Integration test covering full Arrow workflow
  - **Deliverables**:
    - Test file: `tests/testthat/test-arrow_integration.R`
  - **Dependencies**: Steps 2.3, 2.4

---

## PHASE 3 — COMPUTATION ENGINE IMPLEMENTATION

This phase implements measure-specific computation functions in {piptb}, replacing legacy generic functions.

- [ ] Step 3.1: Design Measure-Specific Function Architecture
  - **Objective**: Define interface and implementation approach for all measure functions
  - **Tasks**:
    - Based on Step 1.2 decision (wrap {pipster} vs. custom), design function signatures
    - Define common function signature pattern for all measures:
      - Input: (microdata, welfare_var, weight_var, grouping_vars)
      - Output: data.frame with (group_vars, measure_value, n_unweighted, n_weighted, se)
    - Define error handling and validation for each measure
    - Create design document with function specifications
  - **Outputs**:
    - Function specification document with signatures, inputs, outputs, examples
    - Data structure specifications for measure results
  - **Deliverables**:
    - Design document: `measure_functions_specification.md`
  - **Dependencies**: Step 1.2 (measure computation strategy)

- [ ] Step 3.2: Implement Core Poverty Measure Functions
  - **Objective**: Implement poverty headcount, poverty gap, and poverty severity
  - **Tasks**:
    - Implement `compute_poverty_headcount(microdata, welfare_var, poverty_line, weight_var)` 
      - Either wraps {pipster} or custom implementation per Step 1.2
      - Handle weighted population computation
      - Return: data.frame with (group_vars, poverty_line, headcount, n_unweighted, n_weighted)
    - Implement `compute_poverty_gap(microdata, welfare_var, poverty_line, weight_var)`
      - Formula: `mean((poverty_line - welfare) * (welfare < poverty_line)) / weighted_pop`
      - Handle multiple poverty lines efficiently
    - Implement `compute_poverty_severity(microdata, welfare_var, poverty_line, weight_var)`
      - Foster-Greer-Thorbecke P2 measure
      - Formula: `mean(((poverty_line - welfare) / poverty_line)^2 * (welfare < poverty_line))`
    - Add input validation (poverty_line > 0, welfare_var exists, weight_var exists)
    - Add unit tests for each function with synthetic data
  - **Outputs**:
    - Three measure functions with full Roxygen2 documentation
    - Unit tests for each function covering normal cases and edge cases
  - **Deliverables**:
    - R module: `R/poverty_measures.R`
    - Test file: `tests/testthat/test-poverty_measures.R`
  - **Dependencies**: Step 3.1

- [ ] Step 3.3: Implement Welfare Measure Functions
  - **Objective**: Implement mean welfare, median welfare, percentiles
  - **Tasks**:
    - Implement `compute_mean_welfare(microdata, welfare_var, weight_var)`
      - Weighted mean using data.table or collapse
      - Return: data.frame with (group_vars, mean, n_unweighted, n_weighted, se)
    - Implement `compute_median_welfare(microdata, welfare_var, weight_var)`
      - Weighted percentile at 50th position
      - Use appropriate algorithm for weighted quantiles
    - Implement `compute_percentile(microdata, welfare_var, weight_var, percentile = c(10, 25, 75, 90))`
      - Vectorized computation for multiple percentiles
      - Return long format: (group_vars, percentile_level, value)
    - Add unit tests with known data distributions
  - **Outputs**:
    - Three measure functions with Roxygen2 documentation
    - Unit tests for each function
  - **Deliverables**:
    - R module: `R/welfare_measures.R`
    - Test file: `tests/testthat/test-welfare_measures.R`
  - **Dependencies**: Step 3.1

- [ ] Step 3.4: Implement Inequality Measure Functions
  - **Objective**: Implement Gini coefficient and population count
  - **Tasks**:
    - Implement `compute_gini(microdata, welfare_var, weight_var)`
      - Either wraps {wbpip} function or custom implementation
      - Handle weighted Gini computation
      - Return: data.frame with (group_vars, gini, n_unweighted, n_weighted, se)
    - Implement `compute_population(microdata, weight_var)`
      - Weighted population sum
      - Return: data.frame with (group_vars, population)
    - Add unit tests with known Gini values (e.g., uniform distribution = 0, extreme inequality = 1)
  - **Outputs**:
    - Two measure functions with Roxygen2 documentation
    - Unit tests for each function
  - **Deliverables**:
    - R module: `R/inequality_measures.R`
    - Test file: `tests/testthat/test-inequality_measures.R`
  - **Dependencies**: Step 3.1, Step 1.2 (Gini computation decision)

- [ ] Step 3.5: Implement Grouped Aggregation Helper
  - **Objective**: Create internal utility for efficient grouped computation across all measures
  - **Tasks**:
    - Design generic grouped aggregation function that all measures use
    - Implement `aggregate_by_groups(microdata, grouping_vars, measure_func)`
      - Handles data.table grouping
      - Loops over group combinations and calls measure_func
      - Combines results into single data.frame
    - Add utility for creating subgroup totals (grand total across all groups)
    - Add unit tests
  - **Outputs**:
    - Internal utility function for grouped computation
    - Subgroup totals utility function
    - Unit tests
  - **Deliverables**:
    - R module: `R/aggregation_helpers.R`
    - Test file: `tests/testthat/test-aggregation_helpers.R`
  - **Dependencies**: Steps 3.2–3.4

- [ ] Step 3.6: Implement Standard Error Computation
  - **Objective**: Add standard error estimation for all measures
  - **Tasks**:
    - Implement design-based standard error formulas for weighted statistics
    - For means: `SE = sqrt(var / eff_n)` where `eff_n = (sum(w))^2 / sum(w^2)`
    - For proportions (poverty headcount): `SE = sqrt(p * (1-p) / eff_n)`
    - Add optional finite population correction if survey metadata available
    - Implement as internal helper called by each measure function
    - Add unit tests comparing to known SE values
  - **Outputs**:
    - Standard error utility function
    - Unit tests for SE computation
  - **Deliverables**:
    - R module: `R/standard_errors.R`
    - Test file: `tests/testthat/test-standard_errors.R`
  - **Dependencies**: Steps 3.2–3.4

- [ ] Step 3.7: Implement Main Orchestrator Function
  - **Objective**: Create `table_maker_compute()` — the main computation engine
  - **Tasks**:
    - Implement orchestrator function with signature:
      ```r
      table_maker_compute(
        surveys,           # list of data.frames from table_baker()
        measures,          # c("poverty_headcount", "gini", ...)
        breakdowns,        # c("gender", "area")
        welfare_var,       # "welfare_ppp"
        poverty_lines = 1.9,
        weight_var = "weight",
        include_totals = TRUE
      ) -> data.frame
      ```
    - Implement validation of measure/breakdown compatibility
    - Loop over surveys and measures, calling appropriate measure functions
    - Handle multiple poverty lines (one row per line)
    - Add subgroup totals if requested (Step 3.5)
    - Combine results in long format matching response schema (Step 1.8)
    - Add comprehensive error handling and logging
    - Add unit tests with multi-survey, multi-measure queries
  - **Outputs**:
    - Main orchestrator function with Roxygen2 documentation
    - Unit tests for complex query scenarios
  - **Deliverables**:
    - R module: `R/table_maker_compute.R`
    - Test file: `tests/testthat/test-table_maker_compute.R`
  - **Dependencies**: Steps 3.2–3.6

- [ ] Step 3.8: Implement Computation Result Validation
  - **Objective**: Create validation functions for measure results
  - **Tasks**:
    - Implement `validate_measure_results()` function that checks:
      - All group combinations have results
      - Values are in expected ranges (e.g., Gini 0-1, headcount 0-1, etc.)
      - Sample sizes are non-negative
      - Standard errors are positive
    - Add informative error messages for validation failures
    - Integrate into orchestrator function (Step 3.7)
    - Add unit tests
  - **Outputs**:
    - Validation function with tests
  - **Deliverables**:
    - R module: `R/result_validation.R`
    - Test file: `tests/testthat/test-result_validation.R`
  - **Dependencies**: Steps 3.2–3.7

- [ ] Step 3.9: Performance Benchmarking and Optimization
  - **Objective**: Profile and optimize computation engine for typical queries
  - **Tasks**:
    - Create benchmark script with typical queries (3 surveys, 5 measures, 2 breakdowns)
    - Profile execution time and memory usage per measure function
    - Identify bottlenecks (Gini computation typically slowest)
    - Optimize measure functions using vectorization or parallelization (if appropriate)
    - Re-profile after optimization
    - Document performance characteristics and expected latencies
    - Create benchmark report
  - **Outputs**:
    - Benchmark script
    - Performance report with latency/memory by query type
    - Optimization recommendations
  - **Deliverables**:
    - Script: `tests/performance/computation_benchmark.R`
    - Report: `performance_benchmark_report.md`
  - **Dependencies**: Step 3.7

- [ ] Step 3.10: Unit Test Coverage Validation
  - **Objective**: Ensure comprehensive test coverage of computation engine
  - **Tasks**:
    - Run test coverage analysis on all computation modules
    - Aim for ≥90% line coverage on core functions
    - Add tests for edge cases:
      - Empty groups (n=0)
      - Single observation groups
      - All observations in one group (no variation)
      - Missing values in welfare or weight variables
      - Extreme poverty lines (very low, very high)
    - Document coverage report
  - **Outputs**:
    - Code coverage report (≥90%)
    - Edge case test suite
  - **Deliverables**:
    - Updated test files with additional edge case tests
    - Coverage report: `test_coverage_report.md`
  - **Dependencies**: Steps 3.2–3.8

---

## PHASE 4 — API LAYER IMPLEMENTATION

This phase implements the REST API using Plumber in {piptbapi} package.

- [ ] Step 4.1: Set Up Plumber Framework and Project Structure
  - **Objective**: Establish API framework and project structure
  - **Tasks**:
    - Add Plumber dependency to {piptbapi} DESCRIPTION
    - Create R/ directory structure for API routes
    - Create API entry point: `R/plumber.R` (main API router)
    - Create configuration module for API settings (port, host, max requests, etc.)
    - Set up environment variable loading (.Renviron)
    - Add logging framework (e.g., {logger})
    - Create startup script that initializes Plumber and loads global data
  - **Outputs**:
    - Plumber project structure with entry point
    - Configuration module with API settings
    - Startup script
  - **Deliverables**:
    - Updated DESCRIPTION with Plumber dependency
    - R module: `R/plumber.R`
    - R module: `R/api_config.R`
    - Script: `exec/start_api.R`
  - **Dependencies**: None (but ideally Phase 1 complete)

- [ ] Step 4.2: Implement Request Validation Middleware
  - **Objective**: Create comprehensive request validation layer
  - **Tasks**:
    - Implement request schema validator using jsonlite and assertions
    - Implement survey validator (check existence, welfare type availability)
    - Implement measure validator (check in supported list)
    - Implement breakdown validator (check variable availability per survey)
    - Implement poverty line validator (numeric, positive, reasonable range)
    - Create error response formatter with standardized error codes
    - Add logging for validation failures
    - Create unit tests for each validator
  - **Outputs**:
    - Validation module with functions:
      - `validate_request_schema(req_body) -> list | error`
      - `validate_surveys(surveys) -> list | error`
      - `validate_measures(measures) -> list | error`
      - `validate_breakdowns(surveys, breakdowns) -> list | error`
      - `validate_poverty_lines(poverty_lines) -> list | error`
      - `format_error_response(error_code, message) -> list`
    - Unit tests for each validator
  - **Deliverables**:
    - R module: `R/request_validation.R`
    - Test file: `tests/testthat/test-request_validation.R`
  - **Dependencies**: Step 1.9 (validation rules), Step 2.3 (metadata loader)

- [ ] Step 4.3: Implement Response Formatting Module
  - **Objective**: Create standardized response formatting
  - **Tasks**:
    - Implement success response formatter matching schema from Step 1.8
    - Implement partial success response formatter (with warnings)
    - Implement error response formatter
    - Add metadata injection (request_id, timestamp, query_time, etc.)
    - Implement JSON serialization with appropriate field types
    - Create unit tests with example responses
  - **Outputs**:
    - Response formatting module with functions:
      - `format_success_response(results, metadata) -> list`
      - `format_partial_response(results, warnings, metadata) -> list`
      - `format_error_response(error_code, message) -> list`
    - Unit tests with example JSON outputs
  - **Deliverables**:
    - R module: `R/response_formatter.R`
    - Test file: `tests/testthat/test-response_formatter.R`
  - **Dependencies**: Step 1.8 (response schema)

- [ ] Step 4.4: Implement Main API Endpoint
  - **Objective**: Create POST /api/table-maker endpoint
  - **Tasks**:
    - Create Plumber route handler for POST /api/table-maker
    - Implement request pipeline:
      1. Parse JSON request body
      2. Validate request schema (Step 4.2)
      3. Load Arrow data via table_baker() (Step 2.4)
      4. Call table_maker_compute() (Step 3.7) for computation
      5. Format response (Step 4.3)
      6. Return JSON response
    - Add error handling at each pipeline stage with appropriate HTTP status codes
    - Add request logging (survey list, measures, breakdowns, query time)
    - Add timeout handling (if async, return 202; else return 200 or error)
    - Create integration tests with sample requests
  - **Outputs**:
    - POST /api/table-maker endpoint implementation
    - Integration tests for typical and edge case requests
  - **Deliverables**:
    - R module: `R/api_endpoints.R`
    - Test file: `tests/testthat/test-api_endpoints.R`
  - **Dependencies**: Steps 2.4, 3.7, 4.2, 4.3

- [ ] Step 4.5: Implement Survey Metadata Endpoint
  - **Objective**: Create GET /api/surveys endpoint for discovery
  - **Tasks**:
    - Create Plumber route handler for GET /api/surveys
    - Return list of all available surveys with metadata:
      - country_code, survey_year, welfare_type, reporting_level, available_breakdowns
    - Add optional filters (by country, year, welfare_type)
    - Add pagination if list is large
    - Create unit tests
  - **Outputs**:
    - GET /api/surveys endpoint
    - Unit tests for filtering and pagination
  - **Deliverables**:
    - R module: `R/api_endpoints.R` (updated from Step 4.4)
    - Test file: `tests/testthat/test-api_discovery.R`
  - **Dependencies**: Step 2.3 (metadata loader)

- [ ] Step 4.6: Implement Supported Measures Endpoint
  - **Objective**: Create GET /api/measures endpoint for discovery
  - **Tasks**:
    - Create Plumber route handler for GET /api/measures
    - Return list of supported measures with metadata:
      - measure_name, description, poverty_line_required, applies_to_breakdowns
    - Return list of supported breakdown dimensions with metadata:
      - dimension_name, description, available_values_per_survey
    - Create unit tests
  - **Outputs**:
    - GET /api/measures endpoint
    - Unit tests
  - **Deliverables**:
    - R module: `R/api_endpoints.R` (updated)
    - Test file: `tests/testthat/test-api_discovery.R` (updated)
  - **Dependencies**: None

- [ ] Step 4.7: Implement Caching Layer (if decided in Phase 1)
  - **Objective**: Add response caching with invalidation strategy
  - **Conditional**: Only if Step 1.10 decision is "smart cache"
  - **Tasks**:
    - Design cache key function (hash of request parameters)
    - Implement cache storage (in-memory or Redis, depending on deployment model)
    - Implement cache invalidation on PIP release dates
    - Implement cache statistics tracking (hit rate, size)
    - Add cache control headers to HTTP responses
    - Create unit tests for cache hit/miss scenarios
  - **Outputs**:
    - Caching module with functions:
      - `compute_cache_key(request) -> character`
      - `get_cached_result(cache_key) -> list | NULL`
      - `set_cached_result(cache_key, result) -> logical`
      - `invalidate_cache() -> logical`
      - `get_cache_stats() -> list`
    - Unit tests for caching behavior
  - **Deliverables**:
    - R module: `R/api_caching.R`
    - Test file: `tests/testthat/test-api_caching.R`
  - **Dependencies**: Step 1.10 (caching strategy)

- [ ] Step 4.8: Implement Rate Limiting (if decided in Phase 1)
  - **Objective**: Add rate limiting to protect API
  - **Conditional**: Only if Step 1.10 decision includes rate limiting
  - **Tasks**:
    - Implement rate limiter by IP address (or user if authenticated)
    - Implement sliding window algorithm (e.g., 10 requests per 60 seconds)
    - Store rate limit state in-memory or Redis
    - Return 429 Too Many Requests with Retry-After header when limit exceeded
    - Add rate limit headers to all responses (X-RateLimit-Limit, X-RateLimit-Remaining)
    - Create unit tests
  - **Outputs**:
    - Rate limiting module with functions:
      - `check_rate_limit(client_id) -> logical`
      - `update_rate_limit(client_id) -> logical`
      - `get_rate_limit_status(client_id) -> list`
    - Unit tests for rate limiting logic
  - **Deliverables**:
    - R module: `R/api_rate_limiting.R`
    - Test file: `tests/testthat/test-api_rate_limiting.R`
  - **Dependencies**: Step 1.10 (rate limiting strategy)

- [ ] Step 4.9: Implement Comprehensive API Documentation
  - **Objective**: Create API documentation for developers
  - **Tasks**:
    - Document all endpoints (POST /api/table-maker, GET /api/surveys, GET /api/measures)
    - For each endpoint: description, request schema, response schema, error codes, examples
    - Create request/response examples as JSON files
    - Document authentication requirements (if applicable)
    - Document rate limiting (if applicable)
    - Document error handling and retry logic
    - Create OpenAPI/Swagger specification (optional but recommended)
  - **Outputs**:
    - API documentation markdown
    - Request/response example JSON files
    - OpenAPI specification (if applicable)
  - **Deliverables**:
    - Documentation: `docs/API_SPECIFICATION.md`
    - Examples: `docs/api_examples/`
    - Specification: `docs/openapi.yaml` (optional)
  - **Dependencies**: Steps 4.4–4.6

- [ ] Step 4.10: Implement Health Check and Status Endpoints
  - **Objective**: Create operational endpoints for monitoring
  - **Tasks**:
    - Create GET /health endpoint (returns 200 OK if healthy)
    - Create GET /status endpoint (returns detailed status: Arrow data loaded, metadata loaded, etc.)
    - Create GET /stats endpoint (returns operational stats: requests served, avg latency, cache hit rate, etc.)
    - Create unit tests
  - **Outputs**:
    - Health/status/stats endpoints
    - Unit tests
  - **Deliverables**:
    - R module: `R/api_endpoints.R` (updated)
    - Test file: `tests/testthat/test-api_operations.R`
  - **Dependencies**: None

---

## PHASE 5 — PERFORMANCE, SCALING & OPTIMIZATION

This phase optimizes the system for production performance and scaling.

- [ ] Step 5.1: End-to-End Performance Testing
  - **Objective**: Establish performance baseline for various query types
  - **Tasks**:
    - Create test scenarios:
      - Typical: 3 surveys, 5 measures, 1 breakdown, 1 poverty line
      - Medium: 8 surveys, 10 measures, 2 breakdowns, 3 poverty lines
      - Large: 15 surveys, 15 measures, 3 breakdowns, 5 poverty lines
    - Measure query latency, memory usage, and data size for each
    - Test with realistic data sizes
    - Document performance characteristics
    - Identify bottlenecks (typically Gini computation)
    - Create performance baseline report
  - **Outputs**:
    - Performance test scenarios
    - Baseline report with latencies and resource usage by query type
  - **Deliverables**:
    - Test script: `tests/performance/end_to_end_performance.R`
    - Report: `performance_baseline_report.md`
  - **Dependencies**: Steps 3.7, 4.4

- [ ] Step 5.2: Memory Profiling and Optimization
  - **Objective**: Profile and optimize memory usage
  - **Tasks**:
    - Profile memory allocation during typical queries
    - Identify memory hotspots (Arrow data loading, intermediate data.frames, etc.)
    - Implement memory-efficient strategies:
      - Streaming computation (process in batches if needed)
      - Garbage collection between large operations
      - In-place operations where possible
    - Test with max query size (15 surveys)
    - Document memory usage limits and safeguards
  - **Outputs**:
    - Memory profiling report
    - Memory optimization recommendations
    - Implementation of safeguards (max query size validation)
  - **Deliverables**:
    - Profiling script: `tests/performance/memory_profiling.R`
    - Report: `memory_profiling_report.md`
  - **Dependencies**: Step 5.1

- [ ] Step 5.3: Parallelization Evaluation
  - **Objective**: Assess potential for parallelization
  - **Tasks**:
    - Identify parallelizable operations (measure computation across groups, across surveys)
    - Evaluate using {furrr} or {future} for parallel grouping operations
    - Profile parallel vs. sequential performance
    - Consider memory trade-off (parallelization requires more memory)
    - Document findings and recommendations
    - If beneficial, implement parallel compute option (optional)
  - **Outputs**:
    - Parallelization assessment
    - Performance comparison (parallel vs. sequential)
  - **Deliverables**:
    - Analysis document: `parallelization_assessment.md`
  - **Dependencies**: Step 5.1

- [ ] Step 5.4: Arrow Query Optimization
  - **Objective**: Optimize Arrow dataset access patterns
  - **Tasks**:
    - Analyze Arrow access patterns in typical queries
    - Evaluate partition pruning efficiency (filter by country, year, welfare_type early)
    - Test impact of partition order (current: country → year → welfare_type)
    - Consider pre-computed aggregates for common queries (optional future work)
    - Document optimization strategies
  - **Outputs**:
    - Arrow optimization analysis
    - Recommendations for partition structure (if any changes needed)
  - **Deliverables**:
    - Analysis document: `arrow_optimization_report.md`
  - **Dependencies**: Step 2.4

- [ ] Step 5.5: Load Testing and Concurrency Evaluation
  - **Objective**: Test API behavior under concurrent load
  - **Tasks**:
    - Create load testing script using {loadtest} or similar
    - Simulate 10, 50, 100 concurrent users
    - Measure response times, error rates, resource usage under load
    - Identify concurrency issues (race conditions, resource contention)
    - Test with typical and large query mixes
    - Document concurrency limits and recommendations
  - **Outputs**:
    - Load testing report
    - Concurrency limits and scalability assessment
  - **Deliverables**:
    - Load testing script: `tests/performance/load_testing.R`
    - Report: `load_testing_report.md`
  - **Dependencies**: Step 4.4

- [ ] Step 5.6: Deployment Scaling Plan
  - **Objective**: Design deployment architecture for production
  - **Tasks**:
    - Document deployment options (single instance, containerized, cloud)
    - Design load balancing strategy (if needed)
    - Design data refresh strategy (Arrow updates)
    - Document required infrastructure (CPU, RAM, disk)
    - Create deployment configuration files (Docker, docker-compose, or K8s)
    - Document horizontal scaling approach (if needed)
  - **Outputs**:
    - Deployment architecture design
    - Infrastructure requirements specification
    - Scaling strategies
  - **Deliverables**:
    - Design document: `deployment_architecture.md`
    - Configuration files: `docker/Dockerfile`, `docker-compose.yml` (if applicable)
  - **Dependencies**: Step 5.5

---

## PHASE 6 — VALIDATION & INTEGRATION TESTING

This phase establishes comprehensive test coverage and validates system correctness.

- [ ] Step 6.1: Implement Computation Correctness Tests
  - **Objective**: Validate all measure functions against known values
  - **Tasks**:
    - Create synthetic datasets with known properties:
      - Uniform distribution (Gini = 0)
      - Two-class distribution (poverty headcount can be calculated analytically)
      - Normal distribution (mean and percentiles known)
    - For each measure, create test cases comparing computed to known values
    - Test with various weight distributions (uniform, proportional)
    - Test edge cases:
      - All observations below poverty line
      - All observations above poverty line
      - Zero variance
    - Document correctness test suite
  - **Outputs**:
    - Synthetic test data with known properties
    - Correctness test cases for all measures
    - Test suite covering edge cases
  - **Deliverables**:
    - Test file: `tests/testthat/test-measure_correctness.R`
    - Test data: `tests/fixtures/` directory with synthetic datasets
  - **Dependencies**: Steps 3.2–3.4

- [ ] Step 6.2: Implement Multi-Survey Integration Tests
  - **Objective**: Test queries combining multiple surveys
  - **Tasks**:
    - Create test queries with 2, 5, 10, 15 surveys
    - Verify results combine correctly across surveys
    - Test with different welfare types and reporting levels
    - Test handling of missing variables across surveys
    - Verify response schema compliance
  - **Outputs**:
    - Integration test suite for multi-survey queries
  - **Deliverables**:
    - Test file: `tests/testthat/test-multi_survey_integration.R`
  - **Dependencies**: Steps 3.7, 4.4

- [ ] Step 6.3: Implement Multi-Measure Integration Tests
  - **Objective**: Test queries with multiple measures
  - **Tasks**:
    - Create test queries with various measure combinations
    - Verify all measures computed correctly in single query
    - Test with multiple poverty lines
    - Verify subgroup totals computed correctly
    - Verify output format compliance
  - **Outputs**:
    - Integration test suite for multi-measure queries
  - **Deliverables**:
    - Test file: `tests/testthat/test-multi_measure_integration.R`
  - **Dependencies**: Steps 3.7, 4.4

- [ ] Step 6.4: Implement Breakdown Dimension Tests
  - **Objective**: Test all breakdown dimension combinations
  - **Tasks**:
    - Create test queries with each dimension (gender, age, education, area, etc.)
    - Create test queries with dimension combinations (gender × area, gender × education, etc.)
    - Verify subgroup totals computed correctly
    - Test with maximum dimensions (3-way breakdown)
    - Test edge cases (single-value dimension, dimension with missing values)
  - **Outputs**:
    - Integration test suite for breakdown dimensions
  - **Deliverables**:
    - Test file: `tests/testthat/test-breakdown_dimensions.R`
  - **Dependencies**: Steps 3.7, 4.4

- [ ] Step 6.5: Implement Request Validation Tests
  - **Objective**: Comprehensive tests for request validation
  - **Tasks**:
    - Test invalid request schemas (missing fields, wrong types)
    - Test invalid survey codes, non-existent surveys
    - Test invalid measure codes, unsupported measures
    - Test invalid breakdowns (non-existent dimensions, dimensions not in survey)
    - Test invalid poverty lines (negative, non-numeric, extreme values)
    - Test rate limiting (if implemented)
    - Verify appropriate error codes and messages for each case
  - **Outputs**:
    - Comprehensive validation test suite
  - **Deliverables**:
    - Test file: `tests/testthat/test-request_validation_comprehensive.R`
  - **Dependencies**: Step 4.2

- [ ] Step 6.6: Implement Response Schema Validation Tests
  - **Objective**: Validate response format compliance
  - **Tasks**:
    - Create JSON schema validator
    - Test success responses match schema from Step 1.8
    - Test partial success responses (with warnings)
    - Test error responses (with error codes)
    - Verify required fields present
    - Verify data types correct
    - Verify metadata fields populated
  - **Outputs**:
    - Response validation test suite
    - JSON schema validators
  - **Deliverables**:
    - Test file: `tests/testthat/test-response_schema_validation.R`
    - Schema files: `tests/fixtures/response_schemas.json`
  - **Dependencies**: Step 4.3

- [ ] Step 6.7: Implement Regression Tests
  - **Objective**: Create suite of regression tests for future changes
  - **Tasks**:
    - Create snapshot tests for common query types
      - Typical query: 3 surveys, 2 measures, 1 breakdown
      - Medium query: 5 surveys, 5 measures, 2 breakdowns
      - Large query: 10 surveys, 10 measures, 3 breakdowns
    - Store expected outputs as reference data
    - Create regression test harness that compares current output to reference
    - Set up automated regression testing in CI/CD
  - **Outputs**:
    - Regression test suite
    - Reference output snapshots
  - **Deliverables**:
    - Test file: `tests/testthat/test-regression.R`
    - Reference data: `tests/fixtures/regression_snapshots/`
  - **Dependencies**: Steps 3.7, 4.4

- [ ] Step 6.8: Implement System Integration Test
  - **Objective**: Test full system from request to response
  - **Tasks**:
    - Create end-to-end test that exercises full pipeline:
      1. Send HTTP request to API
      2. Verify request validation
      3. Verify Arrow data loading
      4. Verify computation
      5. Verify response formatting
      6. Verify response schema compliance
    - Test typical, medium, and large queries
    - Test error scenarios (invalid survey, missing variable, etc.)
    - Test caching (if implemented)
    - Test rate limiting (if implemented)
    - Document test results and coverage
  - **Outputs**:
    - End-to-end integration test suite
    - System test results report
  - **Deliverables**:
    - Test file: `tests/testthat/test-system_integration.R`
    - Report: `system_integration_test_report.md`
  - **Dependencies**: All of Phase 4

- [ ] Step 6.9: Test Coverage Analysis
  - **Objective**: Measure and verify test coverage
  - **Tasks**:
    - Run code coverage analysis on all modules (piptb and piptbapi)
    - Target ≥85% overall coverage, ≥90% for critical paths
    - Identify untested code paths
    - Add tests for uncovered edge cases
    - Generate coverage report with statistics by module
  - **Outputs**:
    - Code coverage report
    - Covered/uncovered code analysis
  - **Deliverables**:
    - Report: `test_coverage_report.md`
  - **Dependencies**: All test steps (6.1–6.8)

- [ ] Step 6.10: Documentation of Test Artifacts
  - **Objective**: Document test approach and results
  - **Tasks**:
    - Create test strategy document (what is tested, how, why)
    - Document test data sources and creation process
    - Create test scenario catalog (typical, medium, large queries)
    - Document known test limitations
    - Create test execution guide for future developers
  - **Outputs**:
    - Test strategy and execution documentation
  - **Deliverables**:
    - Documentation: `docs/TEST_STRATEGY.md`
    - Documentation: `docs/TEST_EXECUTION_GUIDE.md`
  - **Dependencies**: All test steps (6.1–6.9)

---

## PHASE 7 — COMPREHENSIVE DOCUMENTATION

This phase creates all user-facing and developer documentation.

- [ ] Step 7.1: Complete Package Documentation (piptb)
  - **Objective**: Document all {piptb} functions and usage
  - **Tasks**:
    - Ensure all exported functions have complete Roxygen2 documentation
    - Create function hierarchy document (which functions call which)
    - Create quick-start guide for users of {piptb} functions
    - Document error messages and troubleshooting
    - Create examples for common use cases
  - **Outputs**:
    - Complete function documentation with examples
    - Roxygen2 documentation processed into man pages
    - Quick-start guide
  - **Deliverables**:
    - Updated `man/` directory with all .Rd files
    - Guide: `docs/PIPTB_USER_GUIDE.md`
  - **Dependencies**: Steps 3.2–3.7

- [ ] Step 7.2: Complete Package Documentation (piptbapi)
  - **Objective**: Document all {piptbapi} functions and API endpoints
  - **Tasks**:
    - Document all API endpoints with request/response examples
    - Create API reference guide
    - Document configuration options
    - Create deployment guide
    - Document error handling and debugging
  - **Outputs**:
    - API reference documentation
    - Deployment guide
    - Troubleshooting guide
  - **Deliverables**:
    - Guide: `docs/API_REFERENCE.md`
    - Guide: `docs/DEPLOYMENT_GUIDE.md`
    - Guide: `docs/TROUBLESHOOTING.md`
  - **Dependencies**: Steps 4.1–4.10

- [ ] Step 7.3: Create Computation Architecture Documentation
  - **Objective**: Document how computation works internally
  - **Tasks**:
    - Create detailed computation flow diagram
    - Document each measure function (inputs, outputs, algorithm)
    - Document grouped aggregation approach
    - Document standard error computation method
    - Create examples showing step-by-step computation
    - Document performance characteristics
  - **Outputs**:
    - Computation architecture documentation with diagrams
    - Measure function reference
    - Performance documentation
  - **Deliverables**:
    - Documentation: `docs/COMPUTATION_ARCHITECTURE.md`
    - Documentation: `docs/MEASURE_REFERENCE.md`
  - **Dependencies**: Steps 3.2–3.7

- [ ] Step 7.4: Create Data Architecture Documentation
  - **Objective**: Document Arrow dataset structure and Arrow data flow
  - **Tasks**:
    - Document Arrow partition structure with examples
    - Document data loading pipeline (raw → harmonized → Arrow)
    - Document version tracking mechanism
    - Document metadata management
    - Document data refresh process
    - Create examples of Arrow queries
  - **Outputs**:
    - Data architecture documentation
    - Arrow operations guide
  - **Deliverables**:
    - Documentation: `docs/DATA_ARCHITECTURE.md`
    - Guide: `docs/ARROW_OPERATIONS.md`
  - **Dependencies**: Steps 2.1–2.6

- [ ] Step 7.5: Create System Architecture Documentation
  - **Objective**: Document complete system design and data flow
  - **Tasks**:
    - Update original `table_maker_architecture.md` with final decisions from Phase 1
    - Create system component diagram showing all modules
    - Create request flow diagram (request → validation → computation → response)
    - Document system constraints (max surveys, max measures, latency targets)
    - Document operational requirements (dependencies, environment setup)
  - **Outputs**:
    - Complete system architecture documentation with all decisions
    - System diagrams
  - **Deliverables**:
    - Documentation: `docs/TABLE_MAKER_SYSTEM_ARCHITECTURE.md` (updated)
  - **Dependencies**: Phase 1 (all design decisions complete)

- [ ] Step 7.6: Create Getting Started Guides
  - **Objective**: Create guides for different user types
  - **Tasks**:
    - Create guide for API users (how to call endpoints, example requests)
    - Create guide for {piptb} users (how to use computation functions)
    - Create guide for developers (how to extend/modify system)
    - Create guide for operators (how to deploy, configure, monitor)
  - **Outputs**:
    - Getting started guides for each user type
  - **Deliverables**:
    - Guide: `docs/GETTING_STARTED_API_USERS.md`
    - Guide: `docs/GETTING_STARTED_PIPTB_USERS.md`
    - Guide: `docs/GETTING_STARTED_DEVELOPERS.md`
    - Guide: `docs/GETTING_STARTED_OPERATORS.md`
  - **Dependencies**: Steps 7.1–7.4

- [ ] Step 7.7: Create Release Notes and Changelog
  - **Objective**: Document changes and releases
  - **Tasks**:
    - Create changelog documenting all new functions, endpoints, features
    - Document breaking changes (if any)
    - Document known limitations and future work
    - Update package versions and release information
    - Create release notes summarizing MVP deliverables
  - **Outputs**:
    - CHANGELOG.md
    - Release notes for MVP
  - **Deliverables**:
    - File: `CHANGELOG.md`
    - File: `RELEASE_NOTES_v1.0.md`
  - **Dependencies**: All previous phases

- [ ] Step 7.8: Create Troubleshooting and FAQ
  - **Objective**: Document common issues and solutions
  - **Tasks**:
    - Collect common error messages and create solutions
    - Create FAQ for API users (how do I request X measure, how do I combine surveys, etc.)
    - Create FAQ for developers (how do I add a new measure, how do I debug computation, etc.)
    - Create performance troubleshooting guide
    - Create deployment troubleshooting guide
  - **Outputs**:
    - FAQ and troubleshooting documentation
  - **Deliverables**:
    - Documentation: `docs/FAQ.md`
    - Documentation: `docs/TROUBLESHOOTING.md`
  - **Dependencies**: Phase 6 (testing identifies common issues)

---

## PHASE 8 — FINAL INTEGRATION, VALIDATION & DEPLOYMENT PREPARATION

This phase prepares the system for production deployment.

- [ ] Step 8.1: Code Review and Quality Assurance
  - **Objective**: Conduct comprehensive code review of all implementation
  - **Tasks**:
    - Conduct peer code review of all modules (piptb and piptbapi)
    - Check for code style consistency (tidyverse style for R)
    - Verify adherence to coding standards from Step 1.11
    - Check for security issues (input validation, injection risks)
    - Check for performance issues (memory leaks, inefficient loops)
    - Document review findings and required fixes
    - Re-review after fixes
  - **Outputs**:
    - Code review checklist
    - Review findings and corrections
    - Final sign-off on code quality
  - **Deliverables**:
    - Report: `code_review_report.md`
  - **Dependencies**: All implementation phases (2–7)

- [ ] Step 8.2: Dependency Management and Version Pinning
  - **Objective**: Ensure reproducible builds with pinned dependencies
  - **Tasks**:
    - Review all package dependencies in {piptb} and {piptbapi}
    - Verify {pipster} and {wbpip} versions are compatible
    - Verify {pipload} version requirement is correctly specified
    - Pin dependency versions in DESCRIPTION for reproducibility
    - Document minimum required versions for each dependency
    - Test with locked dependency set
  - **Outputs**:
    - Updated DESCRIPTION with pinned versions
    - Dependency compatibility matrix
  - **Deliverables**:
    - Updated `piptb/DESCRIPTION`
    - Updated `piptbapi/DESCRIPTION`
    - Documentation: `DEPENDENCIES.md`
  - **Dependencies**: All implementation phases

- [ ] Step 8.3: Security Review and Hardening
  - **Objective**: Ensure system is secure for production
  - **Tasks**:
    - Review request validation for injection attacks (SQL, command)
    - Review response formatting for information leakage
    - Review API for authentication/authorization gaps (if applicable)
    - Review logging for sensitive data exposure
    - Test with adversarial inputs
    - Document security considerations and best practices
  - **Outputs**:
    - Security review report
    - Security hardening recommendations
  - **Deliverables**:
    - Report: `security_review_report.md`
  - **Dependencies**: Steps 4.1–4.10

- [ ] Step 8.4: Configuration and Environment Setup
  - **Objective**: Create production configuration templates
  - **Tasks**:
    - Create .Renviron template with all required variables
    - Create configuration file template (API port, host, timeout, etc.)
    - Document all configuration options
    - Create Docker/container configuration files
    - Test configuration in clean environment
  - **Outputs**:
    - Configuration templates and examples
    - Docker configuration
    - Configuration documentation
  - **Deliverables**:
    - File: `.Renviron.template`
    - File: `config_template.yml`
    - Files: `docker/Dockerfile`, `docker-compose.yml`
    - Documentation: `docs/CONFIGURATION.md`
  - **Dependencies**: Step 4.1

- [ ] Step 8.5: Create Deployment Checklist
  - **Objective**: Create step-by-step deployment procedure
  - **Tasks**:
    - Document pre-deployment checks (dependencies, configuration, data)
    - Document deployment steps (package installation, API startup, data loading)
    - Document post-deployment validation (health checks, smoke tests)
    - Document rollback procedure
    - Create deployment runbook for operators
  - **Outputs**:
    - Deployment checklist
    - Deployment runbook
  - **Deliverables**:
    - Documentation: `docs/DEPLOYMENT_CHECKLIST.md`
    - Documentation: `docs/DEPLOYMENT_RUNBOOK.md`
  - **Dependencies**: Step 7.2

- [ ] Step 8.6: Monitoring and Observability Setup
  - **Objective**: Create monitoring infrastructure
  - **Tasks**:
    - Design metrics to monitor:
      - API: requests/sec, latency, error rate, status codes
      - Computation: latency per query type, memory usage
      - Data: Arrow load success, metadata freshness
      - Caching: hit rate, eviction rate (if applicable)
    - Create logging configuration (structured logs with request_id, latency, etc.)
    - Create alerting thresholds (error rate > 5%, p95 latency > 30s, etc.)
    - Document monitoring setup and dashboards
  - **Outputs**:
    - Monitoring plan
    - Alert definitions
    - Logging configuration
  - **Deliverables**:
    - Documentation: `docs/MONITORING_PLAN.md`
    - Configuration: `config/logging.yml`
  - **Dependencies**: Step 7.2

- [ ] Step 8.7: User Acceptance Testing (UAT)
  - **Objective**: Conduct final validation with stakeholders
  - **Tasks**:
    - Prepare UAT scenarios representing real user workflows
    - Conduct UAT with product team, operations, data users
    - Test across multiple browsers/clients (if web frontend)
    - Collect feedback and document issues
    - Fix critical issues before release
    - Obtain sign-off from stakeholders
  - **Outputs**:
    - UAT test scenarios
    - UAT results and sign-off
  - **Deliverables**:
    - Report: `uat_report.md`
    - Sign-off document: `uat_signoff.md`
  - **Dependencies**: All implementation phases

- [ ] Step 8.8: Production Data Preparation
  - **Objective**: Prepare production Arrow dataset
  - **Tasks**:
    - Verify all required survey data is available
    - Generate production Arrow partitions (if pre-generation approach)
    - Validate Arrow data integrity
    - Create backup procedures for Arrow data
    - Document data refresh schedule and procedures
    - Create data validation tests (checksums, row counts, etc.)
  - **Outputs**:
    - Production Arrow dataset
    - Data validation report
    - Backup and refresh procedures
  - **Deliverables**:
    - Arrow data: (deployment-specific location)
    - Report: `production_data_validation_report.md`
    - Documentation: `docs/DATA_MANAGEMENT.md`
  - **Dependencies**: Phase 2

- [ ] Step 8.9: Documentation Review and Finalization
  - **Objective**: Ensure all documentation is complete and accurate
  - **Tasks**:
    - Review all documentation for accuracy, clarity, completeness
    - Update examples with real data
    - Ensure documentation reflects final implementation
    - Check for broken links, outdated information
    - Create master documentation index
    - Prepare documentation for release
  - **Outputs**:
    - Reviewed and finalized documentation
    - Documentation index
  - **Deliverables**:
    - Updated all `docs/` files
    - File: `docs/README.md` (documentation index)
  - **Dependencies**: Phase 7

- [ ] Step 8.10: Prepare Release Package
  - **Objective**: Create final release artifacts
  - **Tasks**:
    - Build {piptb} package (R CMD DESCRIPTION, code verification)
    - Build {piptbapi} package
    - Create GitHub releases with version tags
    - Create release artifacts (source tarballs, binaries if applicable)
    - Create release notes summarizing MVP features and known limitations
    - Archive all documentation
  - **Outputs**:
    - Release packages for both piptb and piptbapi
    - GitHub releases
    - Release notes and documentation archive
  - **Deliverables**:
    - Tagged release: `v1.0.0` on GitHub
    - Release artifacts in GitHub releases
    - Archived documentation
  - **Dependencies**: Step 8.9

- [ ] Step 8.11: Final Deployment Dry Run
  - **Objective**: Conduct full deployment in staging environment
  - **Tasks**:
    - Deploy packages to staging environment
    - Load production data (Arrow)
    - Run deployment checklist (Step 8.5)
    - Run smoke tests and health checks
    - Test all critical API endpoints
    - Verify monitoring and logging
    - Document issues and fixes
    - Conduct rollback test
  - **Outputs**:
    - Deployment dry-run report
    - Fixes for any issues found
  - **Deliverables**:
    - Report: `staging_deployment_report.md`
  - **Dependencies**: Steps 8.4, 8.8

- [ ] Step 8.12: Production Deployment
  - **Objective**: Deploy Table Maker system to production
  - **Tasks**:
    - Execute deployment checklist (Step 8.5) on production
    - Verify system health (health endpoints, monitoring alerts)
    - Run smoke tests against production API
    - Monitor for errors and performance issues in first 24 hours
    - Document deployment completion
    - Create post-deployment runbook
  - **Outputs**:
    - Production system deployed and operational
    - Deployment report
  - **Deliverables**:
    - Report: `production_deployment_report.md`
    - Documentation: `docs/POST_DEPLOYMENT_OPERATIONS.md`
  - **Dependencies**: Step 8.11

- [ ] Step 8.13: Project Wrap-Up and Handoff
  - **Objective**: Complete project and transfer to operations
  - **Tasks**:
    - Document lessons learned during implementation
    - Identify technical debt and future improvements
    - Create handoff documentation for operations team
    - Conduct knowledge transfer session with ops team
    - Create post-launch support plan (bug fixes, maintenance)
    - Archive project artifacts and decisions
  - **Outputs**:
    - Lessons learned document
    - Handoff documentation
    - Support plan
    - Project archive
  - **Deliverables**:
    - Report: `LESSONS_LEARNED.md`
    - Documentation: `docs/OPERATIONS_HANDOFF.md`
    - Plan: `POST_LAUNCH_SUPPORT_PLAN.md`
  - **Dependencies**: Step 8.12

---

## IMPLEMENTATION NOTES

### Dependencies Between Phases

- **Phase 1** (Architecture Validation): No dependencies; must complete before other phases
- **Phase 2** (Arrow Infrastructure): Depends on Phase 1 decisions (especially Q1, Q2)
- **Phase 3** (Computation Engine): Depends on Phase 1 (Q8 measure strategy) and Phase 2 (Arrow access)
- **Phase 4** (API): Depends on Phases 1, 2, 3 (uses all previous components)
- **Phase 5** (Performance): Depends on Phases 3, 4 (optimization requires working system)
- **Phase 6** (Testing): Dependent on Phases 2, 3, 4 (tests all components)
- **Phase 7** (Documentation): Can begin after Phase 1 design; completes as implementation proceeds
- **Phase 8** (Deployment): Depends on all previous phases

### Parallel Work Streams

These task groups can proceed in parallel (within their own phase dependencies):

- **Phase 2**: Steps 2.1, 2.2, 2.3 can start in parallel once Phase 1 complete
- **Phase 3**: Steps 3.2, 3.3, 3.4 can proceed in parallel; 3.5, 3.6 can start once measure functions defined
- **Phase 4**: Steps 4.2, 4.3 can proceed in parallel; Steps 4.5, 4.6 can start before 4.4 completes
- **Phase 6**: Different test suites (6.1, 6.2, 6.3, etc.) can proceed in parallel

### Effort Estimation

- **Phase 1**: ~2–3 weeks (critical design decisions)
- **Phase 2**: ~2 weeks (Arrow infrastructure)
- **Phase 3**: ~4–6 weeks (computation engine with measure functions)
- **Phase 4**: ~4–5 weeks (API with validation and response formatting)
- **Phase 5**: ~2 weeks (performance optimization and benchmarking)
- **Phase 6**: ~3–4 weeks (comprehensive testing)
- **Phase 7**: ~2 weeks (documentation)
- **Phase 8**: ~3–4 weeks (final validation and deployment)

**Total**: ~22–31 weeks (5–7 months) for complete implementation from start to production deployment.

### Risk Mitigation

- **{pipster} Availability**: Step 1.1 investigates early; if functions unavailable, pivot to custom implementation
- **Performance Bottlenecks**: Step 5.1 identifies issues; Step 5.2–5.4 optimize before production
- **Data Quality**: Step 8.8 validates production data; Step 2.2 tracks versions for freshness
- **Scope Creep**: Phase 1 finalizes MVP feature set; Phase 2+ only includes MVP features
- **Deployment Issues**: Step 8.11 dry-run catches problems before production