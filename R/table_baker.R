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
table_baker <- function(vars       = NULL,
                        weight     = NULL,
                        col        = NULL,
                        row        = NULL,
                        scol       = NULL,
                        srow       = NULL,
                        by_vars    = c(col, row, scol, srow),
                        stats      = "mean",
                        format     = c("long", "wide"),
                        povline    = 1.9,
                        by_survey  = getOption("by_survey.tb"),
                        id_var     = c("cache_id", "survey_id"),
                        ...) {

  dots             <- list(...)
  dots_names       <- names(dots)
  country_codes    <- grep("^[A-Z]{3}",
                      dots_names,
                      value = TRUE)
  countries_values <- dots[country_codes]

  purrr::pmap(list(country = country_codes,
                   year    = countries_values),
                   fake_load)
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

#' Fake load function
#'
#' @param country
#' @param year
#'
#' @return
#' @export
#'
#' @examples
fake_load <- function(country, year) {

  callf <- rlang::call2("pip_load_cache",
                        country = country,
                        year    = year,
                        .ns = "pipload")

  callf
}
# qq <- fake_load("PRY", c(2007:2009))
# df <- eval(qq)
