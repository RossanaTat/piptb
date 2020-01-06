#' Load GMD special collection for Project X
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
#' @return data frame
#' @export
#'
#' @importFrom magrittr %>%
#'
#'
#' @examples
#' df <- tm_load(country = "COL", year = 2015)
#'
tm_load <- function(country,
                    year = NA,
                    survey = NA,
                    vermast = NA,
                    veralt = NA,
                    type = "PX",
                    maindir = ":/03.ProjectX/data/",
                    drive = "p") {


  #--------- Initial conditions

  # drive and main dir

  maindir <- paste0(drive, maindir)

  if (!dir.exists(maindir)) {
    maindir <- "//wbntpcifs/povcalnet/03.ProjectX/data"
  }
  if (!dir.exists(maindir)) {
    st_msg <- paste0("main directory `", maindir,
                     "` not reachable. Check connection")
    stop(st_msg)
  }

  # Country dir
  dir_c <- paste0(maindir, country)
  direxists <- dir.exists(dir_c)

  if (!direxists) {
    warning(paste0("dir ", country, " not found"))
  }


  #--------- Last year available if not selected

  if (is.na(year)) {
    dirs <- tibble::enframe(dir(dir_c))
    years <- stringr::str_extract(dirs[["value"]], "\\d+")
    year <-  max(years)
  }

  #--------- if survey is not selected

  if (is.na(survey)) {
    pattern <- paste0(".*", year, "_*")
    dirs <- tibble::enframe(dir(dir_c, pattern = pattern))

    p <- "([A-Z]+)_(\\d+)_(.+)$"


    surveys <- dirs[["value"]]
    surveys <- stringr::str_subset(surveys, p)
    surveys <- stringr::str_replace(surveys, p, "\\3")

    if (length(surveys) == 1) {
      survey <- surveys[[1]]
    } else {
      a <- utils::menu(surveys, title = "Select a survey to load")
      survey <- surveys[[a]]
    }
  }  # end survey condition


  #--------- load version
  dir_cys <- paste0(dir_c, "/", country, "_", year, "_", survey)

  if (is.na(vermast)) {
    # Master version
    pattern = ".*GMD"
    dirs <- tibble::enframe(dir(dir_cys, pattern = pattern))

    p <- "(.+)_[Vv]([0-9]+)_[Mm]_(.+)"

    vms <- dirs[["value"]]
    vms <- stringr::str_subset(vms, p)
    vms <- stringr::str_replace(vms, p, "\\2")

    vermast <- max(vms)
  } else {  # if vermast is defined
    vermast <- stringr::str_replace(vermast, "(^[Vv])([0-9]+)", "\\2")
  }

  if (nchar(vermast) == 1) {
    vermast <- paste0("0", vermast)
  }

  if (is.na(veralt)) {
    # Alternative version
    pattern = paste0(".*", vermast, "_M_.*_A_GMD")
    dirs <- tibble::enframe(dir(dir_cys, pattern = pattern))

    p <- "(.+)_[Vv]([0-9]+)_[Aa]_(.+)"

    vas <- dirs[["value"]]
    vas <- stringr::str_subset(vas, p)
    vas <- stringr::str_replace(vas, p, "\\2")

    veralt <- max(vas)

  } else {  # if veralt is defined
    veralt <- stringr::str_replace(veralt, "(^[Vv])([0-9]+)", "\\2")
  }

  if (nchar(veralt) == 1) {
    veralt <- paste0("0", veralt)
  }

  #----------------------------------------------------------
  #   Loading according to type
  #----------------------------------------------------------

  #--------- parameters

  survid = paste(
    country, year, survey, paste0("v", vermast),
    "M", paste0("v", veralt), "A", "GMD", sep = "_"
  )

  id1 = paste(country, year, sep = "_")
  id2 = paste(country, year, survey, sep = "_")


  module <- "PX"
  filename <- paste(survid, module, sep = "_")

  dtadir <- paste(dir_cys, survid, "Data", paste0(filename, ".dta"), sep = "/")

  cat("Loading ", filename, "\n")

  tb <- haven::read_dta(dtadir)

  attr(tb, "filename") <- filename
  attr(tb, "survid") <- survid
  attr(tb, "module") <- module
  attr(tb, "id1") <- id1
  attr(tb, "id2") <- id2

  return(tb)

} # end of pcn_load()

