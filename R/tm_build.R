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
  assert_that(length(country) > 0 & any(!(is.na(country))) ,
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
    } # end of all() condition
  } else { # end of length(country) == 1 condition
    to_load <- list(country = country  ,
                       year    = year     ,
                       survey  = survey   ,
                       vermast = vermast  ,
                       veralt  = veralt   ,
                       type    = type     ,
                       maindir = maindir  ,
                       drive   = drive
                       )
  } # end of length(country) != 1

  #----------------------------------------------------------
  # Check inputs
  #----------------------------------------------------------

  # get independnet vectors
  # here, the original vectors are modifies to make of the same length

  tm_check_inputs(lt = to_load)

  # dataframe with parameters expanded and rectangulized
  df <- tibble::tibble(country = country  ,
                       year    = year     ,
                       survey  = survey   ,
                       vermast = vermast  ,
                       veralt  = veralt   ,
                       type    = type     ,
                       maindir = maindir  ,
                       drive   = drive
                       )


  #--------- make sure that the years selected are available

  # get available years in selected countries
  countries <- unique(country)
  av_year <- purrr::map(countries, tm_get_year) %>% # available years
    setNames(countries)

  # get selected years as list
  se_year <- purrr::map(countries, tm_select_year, df = df) %>% # selected years
    setNames(countries)

  # check that selected years are available
  a <- purrr::map(countries,
                  tm_check_year,
                  se = se_year,
                  av = av_year) %>%
    setNames(countries)

  assert_that(!(is.numeric(unlist(a))),
              msg = "Some of the combinations of country and year are not available\n(err. message to improve)")

  #----------------------------------------------------------
  #   Load data
  #----------------------------------------------------------


  lt <- purrr::pmap(to_load, tm_load)

  # get names for list
  nn <- purrr::map_chr(seq_along(lt), ~attributes(lt[[.x]])$id1)
  lt <- setNames(lt, nn)

  return(lt)
}  # end of tm_build main function


#----------------------------------------------------------
#   Auxiliaty functions to tm_build
#----------------------------------------------------------


tm_check_inputs <- function(lt) {

  # check that vectors are the same size.
  assert_that(length(lt$country) == length(lt$year) ,
              msg = paste0("if length of `country` is > 1, all parameter in\n",
                          "`tm_build` should be of the size as `country`. \n" ,
                          "Now, length(country) is ",
                          length(country),
                          ", whereas length(year) is ",
                          length(year),
                          "."))

  # check years selected are available in country


}

#----------------------------------------------------------
#   check years compatibility
#----------------------------------------------------------


# code that returns the years available
tm_get_year <- function(country,
                          maindir  = ":/03.ProjectX/data/",
                          drive = "p") {
  a <- dir(path = paste0(drive, maindir, country))
  a <- stringr::str_extract(a, "([0-9]+)")
  return(a)
}

tm_select_year <- function(x, df) {
  a <- df[df$country == x, "year"]
}

tm_check_year <- function(x, se, av) {
  a <- !(se[[x]][[1]]  %in% av[[x]])

  if (any(a == TRUE)) {
    b <- se[[x]][a,]
  } else {
    b <- NULL
  }
}
