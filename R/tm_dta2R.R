#' Convert dta GMD files to R binary files
#'
#' Pending: add option to check if the file already exists, so it is skipped
#' Pending: add conditions if user select name of survey
#' pending: check that paramters `year` or `survey` can only be specified if
#' parameter `country` is also specified.
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
#' @return A dataframe with two columns, one for the id of the survey and one for the status
#' of the saving procedure.
#' @export
#'
#' @examples
#' e <- tm_dta2R(country = "PRY", year = c(2013, 2014))
tm_dta2R <- function(country = NA,
                     year = NULL,
                     survey = NA,
                     vermast = NA,
                     veralt = NA,
                     formt = "all",
                     module = "PX",
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

  pattern <- paste0(module, "\\.dta$")

  if (!(is.na(country))) {
    maindir <- paste(maindir, country, sep = "/")

    if (length(year) > 0) {
      yy <- paste(as.character(year), collapse  = "|")
      yy <- paste0("(", yy, ")")
      pattern <- paste0(yy, ".*", pattern)
    }

  }

  a <- list.files(path = maindir,
                  pattern = pattern,
                  recursive = TRUE,
                  full.names = TRUE)

  fr <- purrr::map_df(a, tm_dta2R_save)

  print("Done with everything.")

  return(fr)

} # end of pcn_load()


#----------------------------------------------------------
#   individual function
#----------------------------------------------------------

tm_dta2R_save <- function(x) {

  tryCatch(
    expr = {

      y <- stringr::str_replace(x, "(.*)\\.dta$", "\\1") # others

      #--------- parameters
      survid <- stringr::str_replace(x, "(.*)/(.*)_PX\\.dta$", "\\2")
      id1 <- stringr::str_replace(survid, "([A-Z]{3}_[0-9]{4})_.*", "\\1")
      id2 <- stringr::str_replace(survid, "([A-Z]{3}_[0-9]{4}.*)_[vV][0-9]{2}_M.*", "\\1")

      module <- "PX"
      filename <- paste0(survid, "_", module)


      tb <- haven::read_dta(x)
      tb <- data.table::as.data.table(tb)

      attr(tb, "filename") <- filename
      attr(tb, "survid") <- survid
      attr(tb, "module") <- module
      attr(tb, "id1") <- id1
      attr(tb, "id2") <- id2


      #--------- Save files according to format select

      if (formt  %in% c("fst", "all")) {
        fst::write_fst(tb, paste0(y, ".fst"))
      }
      if (formt  %in% c("feather", "all")) {
        feather::write_feather(tb, paste0(y, ".feather"))
      }
      if (formt  %in% c("RData", "all")) {
        save(tb, file = paste0(y, ".RData"))
      }
      if (formt  %in% c("Rds", "all")) {
        saveRDS(tb, paste0(y, ".Rds"))
      }

      output <- tibble::tibble(id = survid,
                               status = "OK")
      return(output)

    }, # end of expr section

    error = function(e) {
      output <- tibble::tibble(id = survid,
                               status = paste("Error:",e$message))
      return(output)
    }, # end of error section

    warning = function(w) {
      output <- tibble::tibble(id = survid,
                               status = "OK")
      return(output)
    }, # end of warning section
    finally = {
      print(paste("done with", survid))
    }

  ) # End of trycatch


}
