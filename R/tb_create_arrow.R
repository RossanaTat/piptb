#' Create Arrow files of precalculated table Maker indicators
#'
#' @param country_code character: vector with country codes
#' @param surveyid_year numeric: Survey years
#' @param survey_acronym character: Survey acronym when there is more than one
#'   survey per year. It only works if `length(country_code) == 1`
#' @param data_level character: either "D1" for national, "D2" for urban/rural,
#'   "D3" for subnational
#' @param arrow_format character: either "parquet" of "feather". Former default.
#' @param root_dir character: directory path. Default
#'   `Sys.getenv("PIP_root_dir")`
#' @param welfare_type character: Either "CON" for consumption or "INC" for
#'   income
#'
#' @return
#' @export
tb_create_arrow <- function(country_code   = NULL,
                            surveyid_year  = NULL,
                            survey_acronym = NULL,
                            data_level     = NULL,
                            welfare_type   = NULL,
                            arrow_format   = c("parquet", "feather"),
                            root_dir       = Sys.getenv("PIP_DATA_ROOT_FOLDER"),
                            verbose        = TRUE) {


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check arguments --------
  arrow_format <- match.arg(arrow_format)

  # globals
  gls <- create_globals(root_dir)

  # get countries in Table maker
  inv <- fst::read_fst(paste0(gls$CACHE_SVY_TB_DIR,
                              "_crr_inventory/crr_inventory.fst"),
                       as.data.table = TRUE)

  countries_tb <-
    inv[,
        country_code := data.table::tstrsplit(cache_id, "_", fixed = TRUE, keep = 1)
        ][,unique(country_code)]

  # Defenses -----------

  # all countries are ok
  ctr    <- !(country_code %in% countries_tb)
  if (any(ctr)) {
    bad_ctr <- country_code[ctr]
    cli::cli_abort(c("{length(bad_ctr)} countr{?y/ies} {?is/are} not allowed",

                     "i" = "Make sure all your country codes are available in
                     {.code getOption('piptb.all_countries')}",

                     "x" = "Bad country code: {.field {bad_ctr}}"))
  }

  # Acronym with more than one country

  if (!is.null(survey_acronym) && length(country_code) >1) {

    cli::cli_abort(c("{.var survey_acronym} can't be specified if
                     {.code length(country_code) > 1}",

                     "x" = "{.code length(country_code)} = {.field {length(country_code)}}"))
  }


  if (verbose) {
    cli::cli_progress_step("working on {country_code}")
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Load data and make calculations  --------
  # Working directory
  arrow_dir <- paste0(gls$TB_ARROW, arrow_format, "/")

  .data <- pipload::pip_load_cache(country        = country_code,
                                   year           = surveyid_year,
                                   survey_acronym = survey_acronym,
                                   data_level     = data_level,
                                   welfare_type   = welfare_type,
                                   tool           = "TB",
                                   pipedir        = gls$PIP_PIPE_DIR,
                                   verbose        = verbose)

  # make calculations
  if (verbose) {
    cli::cli_progress_step("performing calculations for all files")
  }
  dt <- tb_heap(.data = .data)

  # ID vars in cache ID
  idvars <-
    c(
      "country_code",
      "surveyid_year",
      "survey_acronym",
      "max_domain",
      "welfare_type",
      "source"
    )


  dt[,
     (idvars) := data.table::tstrsplit(ID, "_", fixed = TRUE)]


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## create arrow files --------
  if (verbose) {
    cli::cli_progress_step("Saving arrow files")
  }
  res <- tryCatch(
    expr = {
      # Your code...
      dt %>%
        dplyr::as_tibble() %>%  # arrow does not accept data.table format
        dplyr::mutate(surveyid_year = as.numeric(surveyid_year)) %>%
        dplyr::group_by(country_code, surveyid_year, welfare_type) %>%
        # group_by(country_code) %>%
        dplyr::select(-ID) %>%
        arrow::write_dataset(arrow_dir, format = arrow_format)

      TRUE
    }, # end of expr section

    error = function(e) {
      e$message

    }, # end of error section

    warning = function(w) {
      w$message
    }
  ) # End of trycatch

  # Return -------------
  return(res)
}
