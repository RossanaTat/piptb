#' Build a data.table with all the countries or  the countries selected
#'
#' @param countries
#' @param years
#' @param maindir
#' @param drive
#'
#' @return
#' @export
#'
#' @examples
tm_build_DT <- function(countries,
                         years = NA,
                         maindir = ":/03.ProjectX/data",
                         drive = "p",
                        savename = NA) {



  te <- tm_build(country = countries, year = years)

  for (i in seq_along(te)) {
    te[[i]]$surveyid <- names(te)[[i]]
  }

  te <- data.table::rbindlist(te, use.names=TRUE)

  if (!(is.na(savename))) {

    fname <- paste0(drive, "/", maindir, "/", "_aux/WLD/", savename)

    feather::write_feather(te, paste0(fname, ".feather"))
    save(te, file = paste0(fname, ".RData"))
    saveRDS(te, paste0(fname, ".Rds"))
  }

  return(te)
}


