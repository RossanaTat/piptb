#' Build a data.table with all the countries or  the countries selected
#'
#' Pending: create trycatch
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
#' DT <- tm_build_DT(countries = c("HND","HND", "PRY", "PRY"),
#'                    years = c(2012, 2012, 2014, 2014))
tm_build_DT <- function(countries,
                         years = NA,
                         maindir = ":/03.ProjectX/data",
                         drive = "p",
                         savename = NA,
                         default = TRUE) {



  te <- tm_build(country = countries, year = years, default = default)


  varnames <- names(te[[1]]) # variable names
  vattr <- purrr::map_chr(varnames, ~class(te[[1]][[.x]])) # variable attributes

  for (i in seq_along(te)) {
    # create variables with survey id info
    te[[i]]$surveyid <- names(te)[[i]]

    # assign the same attributes of list 1 to the rest of the lists
    for (j in seq_along(varnames)) {
      if (varnames[[j]]  %in% names(te[[i]])) {
        class(te[[i]][[varnames[[j]]]]) <- vattr[[j]]
      }
    }
  }

  te <- data.table::rbindlist(te, use.names=TRUE , fill=TRUE)

  if (!(is.na(savename))) {

    fname <- paste0(drive, maindir, "/", "_aux/WLD/", savename)

    feather::write_feather(te, paste0(fname, ".feather"))
    save(te, file = paste0(fname, ".RData"))
    saveRDS(te, paste0(fname, ".Rds"))
  }

  return(te)
}

