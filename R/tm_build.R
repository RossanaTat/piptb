#' Builds list of data sets for calculations
#'
#' @param country character: list of country iso3 code (accepts multiple) or
#' `all`.
#' @param year numeric:  list of years.
#' @param survey charecter: In case there are more than one surveys for the same year
#' @param vermast numeric: Master version. Default is the latest version
#' @param veralt numeric: Alternative version. Default is the latest version
#' @param type character: Collection. Default is GPWG
#' @param maindir character: Main directory where data is stored
#' @param drive character: Drive letter when data is stored. Default is P
#'
#' @return list
#' @export
#' @import assertthat
#'
#' @examples
#' df <- tm_build(country = "COL", year = 2015)
tm_build <- function(country = NA,
                     year = NA,
                     survey = NA,
                     vermast = NA,
                     veralt = NA,
                     type = "PX",
                     maindir = ":/03.ProjectX/data/",
                     drive = "p") {

  # check country is provided
  assert_that(length(country) > 0 & !(is.na(country)) ,
              msg = "Please submit at least ONE country")

  #----------------------------------------------------------
  # when country's length == 1
  #----------------------------------------------------------

  if (length(country) == 1) {

    svar <- c(year,
              survey,
              vermast,
              veralt,
              type,
              maindir,
              drive)

    ones <- purrr::map_int(svar, length)
    if (all(ones == 1)) {
      to_load <- as.list(expand.grid(country = country  ,
                                     year    = year     ,
                                     survey  = survey   ,
                                     vermast = vermast  ,
                                     veralt  = veralt   ,
                                     type    = type     ,
                                     maindir = maindir  ,
                                     drive   = drive
                                 ))
      # get independnet vectors
      for (i in seq_along(a)) {
        assign(names(a[i]), a[[i]])
      }
    } # end of all() condition
  } # end of length(country) == 1 condition







  # CHECK inputs
  tm_check_inputs(country,
                  year,
                  survey,
                  vermast,
                  veralt,
                  type,
                  maindir,
                  drive)

}

tm_check_inputs <- function(country,
                            year,
                            survey,
                            vermast,
                            veralt,
                            type,
                            maindir,
                            drive) {

  # check that vectors are the same size.
  assert_that(length(country) == length(year) ,
              msg = paste0("if length of `country` is > 1, all parameter in\n",
                          "`tm_build` should be of the size as `country`. \n" ,
                          "Now, length(country) is ",
                          length(country),
                          ", whereas length(year) is ",
                          length(year),
                          "."))

  # check years selected are available in country


}



# code that returns the years available
tm_check_year <- function(country,
                          maindir  = ":/03.ProjectX/data/",
                          drive = "p") {
  a <- dir(path = paste0(drive, maindir, country))
  a <- stringr::str_extract(a, "([0-9]+)")
  return(a)
}


countries <- c("COL", "ARG", "BRA")
av_year <- purrr::map(countries, tm_check_year) %>% # available years
  setNames(countries)
