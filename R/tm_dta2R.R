
tm_dta2R <- function(country = NA,
                     year = NULL,
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

  pattern <- "\\.dta$"

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

  fr <- purrr::map(a, tm_dta2R_save)

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

      attr(tb, "filename") <- filename
      attr(tb, "survid") <- survid
      attr(tb, "module") <- module
      attr(tb, "id1") <- id1
      attr(tb, "id2") <- id2


      feather::write_feather(tb, paste0(y, ".feather"))
      save(tb, file = paste0(y, ".RData"))
      saveRDS(tb, paste0(y, ".Rds"))

      output <- tibble::tibble(id = id1,
                               status = "OK")
      return(output)

    }, # end of expr section

    error = function(e) {
      output <- tibble::tibble(id = id1,
                               status = paste("Error:",e$message))
      return(output)
    }, # end of error section

    warning = function(w) {
      output <- tibble::tibble(id = id1,
                               status = "OK")
      return(output)
    } # end of warning section

  ) # End of trycatch


}
