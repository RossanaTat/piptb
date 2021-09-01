#' Table baker to interact with API
#'
#' @inheritParams tb
#' @param data_connect object of class "FileSystemDataset",  "Dataset",
#'   "ArrowObject", and  "R6". It holds the connection to the pre-computed
#'   indicators of the table baker
#' @param ... arguments with survey years for each country. Argument name should
#'   be three-letter country code in upper cases. For instance, it should be of
#'   the form `COL = c(2010, 2012)` to get household survey data for Colombia
#'   (COL) for 2010 and 2012.
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' dw <- table_baker(COL = c(2010, 2012),
#'   HND = c(2006:2010),
#'   PRY = c(2006,2010),
#'   BRA = 2018)
#' }
table_baker <- function(vars          = NULL,
                        weight        = NULL,
                        col           = NULL,
                        row           = NULL,
                        scol          = NULL,
                        srow          = NULL,
                        by_vars       = c(col, row, scol, srow),
                        stats         = "mean",
                        format        = c("long", "wide"),
                        povline       = 1.9,
                        by_survey     = getOption("by_survey.tb"),
                        id_var        = c("cache_id", "survey_id"),
                        max_country   = getOption("piptb.max_country"),
                        max_survey    = getOption("piptb.max_survey"),
                        arrow_format  = c("parquet", "feather"),
                        root_dir      = Sys.getenv("PIP_ROOT_DIR"),
                        arrow_root    = gls$TB_ARROW,
                        data_connect  = NULL,
                        ...) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Get country codes --------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check arguments --------
  arrow_format <- match.arg(arrow_format)

  # get all arguments
  argus <- c(as.list(environment()), list(...))
  # argus <- c(as.list(environment()))


  # Get county/year relation in dots
  dots             <- list(...)
  dots_names       <- names(dots)
  country_codes    <- grep("^[A-Z]{3}",
                      dots_names,
                      value = TRUE)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check countries belong to country list --------

  if (!all(country_codes %in% getOption("piptb.all_countries"))) {
    err_msg_country_codes()
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Defenses --------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Countries
  if (length(country_codes) >= max_country) {
    err_msg_max_countries()
  }

  # surveys
  countries_values <- dots[country_codes]

  nsurveys <- vector(mode = "numeric",
                     length = length(countries_values))

  for(i in seq_along(countries_values)) {
    nsurveys[i] <- length(countries_values[i])
  }

  nsurveys <- sum(nsurveys)

  if (nsurveys >= max_survey) {
    err_msg_max_surveys()
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create filter   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  filters <- glue::glue('(country_code == "{country_codes}"
                        & surveyid_year %in% {countries_values})')
  filters <- glue::glue_collapse(filters, sep = " | ")

  # filters <- parse(text = filters)

  #----------------------------------------------------------
  #   Open connection and filter data
  #----------------------------------------------------------
  toeval <- rlang::parse_expr(filters)

  # Working directory

  if (is.null(data_connect)) {
    arrow_dir    <- paste0(arrow_root, arrow_format, "/")
    data_connect <- arrow::open_dataset(arrow_dir, format = arrow_format)
  }

  # return(toeval)
  # Computations -------

  dt <- data_connect %>%
    dplyr::filter(rlang::eval_tidy(toeval)) %>%
    dplyr::collect()

  return(dt)

}

# debugonce(table_baker)
# dd <- table_baker(COL = c(2010, 2012),
#                   HND = c(2006:2010),
#                   PRY = c(2006,2010),
#                   x = c(4,5), y = 8, "ff")
# dd
# eval(dd[[3]])
#
#
#
#
#   # Basic use. mean default
#   tb(dt,
#      vars = "welfare_ppp",
#      weight = "weight")[]

#----------------------------------------------------------
#   error messages
#----------------------------------------------------------

err_msg_max_countries <- function() {
  pf <- parent.frame()
  msg     <- "Number of countries exceeded"
  problem <- glue::glue("You specified {length(pf$country_codes)} countries,
                          but you're allowed only {pf$max_country}.")
  rlang::abort(c(
    msg,
    x = problem
  ),
  class = "piptb_error"
  )
}


err_msg_country_codes <- function() {
  pf <- parent.frame()

  msg     <- "Country codes selected do not belong to countries list"
  hint    <- "Make sure you spelled the country codes correctly"
  rlang::abort(c(
    msg,
    i = hint
  ),
  class = "piptb_error"
  )
}



err_msg_max_surveys  <- function() {
  pf <- parent.frame()

  msg     <- "Number of surveys exceeded"
  problem <- glue::glue("You specified {pf$nsurveys} surveys,
                          but you're allowed only {pf$max_survey}.")
  rlang::abort(c(
    msg,
    x = problem
  ),
  class = "piptb_error"
  )

}

