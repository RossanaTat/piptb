#' Builds list of data sets for calculations
#'
#' @param country
#' @param year
#' @param survey
#' @param vermast
#' @param veralt
#' @param type
#' @param maindir
#' @param drive
#'
#' @return
#' @export
#' @import assertthat
#'
#' @examples
tm_build <- function(country = NA,
                     year = NA,
                     survey = NA,
                     vermast = NA,
                     veralt = NA,
                     type = "PX",
                     maindir = ":/03.ProjectX/data",
                     drive = "p") {

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

  assertthat::assert_that(length(country) > 0 | !(is.na(country)) ,
                          msg = "Please submit at least ONE country")

  # check that vectors are the same size.



  # check years selected are available in country


}



# code that returns the years available
