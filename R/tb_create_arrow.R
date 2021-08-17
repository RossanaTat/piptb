#' Create Arrow files of precalculated table Maker indicators
#'
#' @param country character: vector with country codes
#' @param year numeric: Survey years
#' @param survey_acronym character: Survey acronym when there is more than one
#'   survey per year. It only works if `length(country) == 1`
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
#'
#' @examples
tb_create_arrow <- function(country        = NULL,
                            year           = NULL,
                            survey_acronym = NULL,
                            data_level     = NULL,
                            welfare_type   = NULL,
                            arrow_format   = c("parquet", "feather"),
                            root_dir       = Sys.getenv("PIP_root_dir")) {


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check arguments --------
  arrow_format <- match.arg(arrow_format)

  # globals
  gls <- create_globals(root_dir)

  # Defenses -----------

  # all countries are ok
  ctr    <- !(country %in% getOption("piptb.all_countries"))
  if (any(ctr)) {
    bad_ctr <- country[ctr]
    cli::cli_abort(c("{length(bad_ctr)} countr{?y/ies} {?is/are} not allowed",

                     "i" = "Make sure all your country codes are available in
                     {.code getOption('piptb.all_countries')}",

                     "x" = "Bad country code: {.field {bad_ctr}}"))
  }

  # Acronym with more than one country

  if (!is.null(survey_acronym) && length(country) >1) {

    cli::cli_abort(c("{.var survey_acronym} can't be specified if
                     {.code length(country) > 1}",

                     "x" = "{.code length(country)} = {.field {length(country)}}"))
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Load data and make calculations  --------
  # Working directory
  arrow_dir <- paste0(gls$TB_ARROW, arrow_format, "/")

  .data <- pipload::pip_load_cache(country        = country,
                                   year           = year,
                                   survey_acronym = survey_acronym,
                                   data_level     = data_level,
                                   welfare_type   = welfare_type,
                                   tool           = "TB",
                                   pipedir        = gls$PIP_PIPE_DIR)

  # make calculations
  dt <- tb_heap(.data = .data)

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

  res <- tryCatch(
    expr = {
      # Your code...
      dt %>%
        dplyr::as_tibble() %>%  # arrow does not accept data.table format
        dplyr::group_by(country_code, surveyid_year, survey_acronym,
                        max_domain, welfare_type) %>%
        # group_by(country_code) %>%
        dplyr::select(-ID) %>%
        arrow::write_dataset(arrow_dir, format = arrow_format)
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
