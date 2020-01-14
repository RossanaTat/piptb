#' Data.Table with results of estimations for table maker
#'
#' @param countries
#' @param years
#' @param povlines
#' @param colvar
#' @param rowvar
#' @param super_rowvar
#' @param super_colvar
#' @param calc_vars
#' @param stats
#'
#' @return
#' @export
#'
#' @examples
#' DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                    years = c(2012, 2014, 2012, 2014),
#'                    povlines = c(1.9, 3.2),
#'                    calc_vars = c("welfare_ppp", "pov_status"))
#'
#' DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                    years = c(2012, 2012, 2014, 2014),
#'                    colvar = "urban",
#'                    rowvar = "male",
#'                    povlines = c(1.9, 3.2),
#'                    calc_vars = c("welfare_ppp", "pov_status"))
#'
#' DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                    years = c(2012, 2012, 2014, 2014),
#'                    colvar = "urban",
#'                    rowvar = "male",
#'                    super_colvar = "hsize",
#'                    povlines = c(1.9, 3.2),
#'                    calc_vars = c("welfare_ppp", "pov_status"))
tm_DT_output <- function(countries,
                               years        = NA  ,
                               povlines     = 1.9 ,
                               colvar       = NULL,
                               rowvar       = NULL,
                               super_rowvar = NULL,
                               super_colvar = NULL,
                               calc_vars    = "pov_status",
                               stats        = "mean") {


  DT <- tm_build_DT(countries = countries,
                 years = years)

  # remove poverty status in case it is selected
  calc_vars_npov <- calc_vars[!calc_vars %in% "pov_status"]


  # Selected variables and final variables to make DT smaller

  svars  <- c(colvar, rowvar, super_colvar, super_rowvar, calc_vars_npov)
  fvars <- unique(c("weight", "welfare", "welfare_ppp",  "surveyid", svars))
  DT <- DT[,..fvars]

  # Poverty status
  for (i in povlines) {
    nvar <- paste0("pov_status",i)
    DT[, (nvar) :=  welfare_ppp < i ]
  }


  # calculation variables
  cv <- paste(as.character(calc_vars), collapse  = "|")

  #--------- Summarise several columns by group

  # get variable by which data will be filtered
  keyby_var <- "list(surveyid"
  new_names <- NULL
  nk <- 1    # starting point. [1] == surveyid


  if (length(colvar) == 1) {
    keyby_var <- paste0(keyby_var, ", get(colvar)")
    new_names <- c(new_names, substitute(colvar))
    nk <- nk + 1
  }

  if (length(rowvar) == 1) {
    keyby_var <- paste0(keyby_var, ", get(rowvar)")
    new_names <- c(new_names, substitute(rowvar))
    nk <- nk + 1
  }

  if (length(super_colvar) == 1) {
    keyby_var <- paste0(keyby_var, ", get(super_colvar)")
    new_names <- c(new_names, substitute(super_colvar))
    nk <- nk + 1
  }

  if (length(super_rowvar) == 1) {
    keyby_var <- paste0(keyby_var, ", get(super_rowvar)")
    new_names <- c(new_names, substitute(super_rowvar))
    nk <- nk + 1
  }
  keyby_var <- paste0(keyby_var, ")")
  keyby_text <- parse(text = keyby_var)


  # parse in Data Table


  # DT <- DT[, lapply(.SD, weighted.mean, na.rm = TRUE),
  #    .SDcols = patterns(cv),
  #    keyby = .(surveyid, get(colvar), get(rowvar))]

  DT <- DT[, lapply(.SD, weighted.mean, na.rm = TRUE),
     .SDcols = patterns(cv),
     keyby = eval(keyby_text)]

  # if variables besides surveyid are used in by
  if (nk > 1) {
    data.table::setnames(DT, 2:nk, new_names)
  }


  return(DT)
}


