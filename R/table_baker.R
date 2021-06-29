#' Table baker to interact with API
#'
#' @inheritParams tb
#' @param ... arguments with survey years for each country.
#' Argument name should be three-letter country code in upper cases.
#' For instance, it should be of the form `COL = c(2010, 2012)`
#' to get household survey data for Colombia (COL) for 2010
#' and 2012.
#'
#' @return
#' @export
#'
#' @examples
table_baker <- function(vars        = NULL,
                        weight      = NULL,
                        col         = NULL,
                        row         = NULL,
                        scol        = NULL,
                        srow        = NULL,
                        by_vars     = c(col, row, scol, srow),
                        stats       = "mean",
                        format      = c("long", "wide"),
                        povline     = 1.9,
                        by_survey   = getOption("by_survey.tb"),
                        id_var      = c("cache_id", "survey_id"),
                        max_country = getOption("piptb.max_country"),
                        max_survey  = getOption("piptb.max_survey"),
                        ...) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Get country codes --------

  dots             <- list(...)
  dots_names       <- names(dots)
  country_codes    <- grep("^[A-Z]{3}",
                      dots_names,
                      value = TRUE)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check countries belong to country list --------

  if (!all(country_codes %in% getOption("piptb.all_countries"))) {
    msg     <- "Country codes selected do not belong to countries list"
    hint    <- "Make sure you spelled the country codes correctly"
    rlang::abort(c(
                  msg,
                  i = hint
                  ),
                  class = "piptb_error"
                  )
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## count number of countries and surveys --------

  # Countries
  if (length(country_codes) >= max_country) {
    msg     <- "Number of countries exceeded"
    problem <- glue::glue("You specified {length(country_codes)} countries,
                          but you're allowed only {max_country}.")
    rlang::abort(c(
                  msg,
                  x = problem
                  ),
                  class = "piptb_error"
                  )
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
    msg     <- "Number of surveys exceeded"
    problem <- glue::glue("You specified {nsurveys} surveys,
                          but you're allowed only {max_survey}.")
    rlang::abort(c(
      msg,
      x = problem
    ),
    class = "piptb_error"
    )
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create filter   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  filters <- glue::glue('(country_code == "{country_codes}"
                        & surveyid_year %in% {countries_values})')
  filters <- glue::glue_collapse(filters, sep = " | ")

  filters <- parse(text = filters)

  # THen use with eval(filters)
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
