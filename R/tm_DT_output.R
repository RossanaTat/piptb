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
#' (DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                     years = c(2012, 2014, 2012, 2014),
#'                     povlines = c(1.9, 3.2),
#'                     calc_vars = c("welfare_ppp", "pov_status")))
#'
#' (DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                     years = c(2012, 2012, 2014, 2014),
#'                     colvar = "urban",
#'                     rowvar = "male",
#'                     povlines = c(1.9, 3.2),
#'                     calc_vars = c("welfare_ppp", "pov_status")))
#'
#' (DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                     years = c(2012, 2012, 2014, 2014),
#'                     colvar = "urban",
#'                     rowvar = "male",
#'                     super_colvar = "hsize",
#'                     povlines = c(1.9, 3.2),
#'                     calc_vars = c("welfare_ppp", "pov_status")))
#'
#' (DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                     years = c(2012, 2014, 2012, 2014),
#'                     povlines = c(1.9, 3.2),
#'                     calc_vars = c("welfare_ppp", "pov_status"),
#'                     stats = c("sum", "mean")))
#'
#' (DT <- tm_DT_output(countries = c("HND","HND", "PRY", "PRY"),
#'                     years = c(2012, 2012, 2014, 2014),
#'                     colvar = "urban",
#'                     rowvar = "male",
#'                     super_colvar = "hsize",
#'                     povlines = c(1.9, 3.2),
#'                     calc_vars = c("welfare_ppp", "pov_status"),
#'                     stats = c("sum", "mean")))
tm_DT_output <- function(countries,
                         years        = NA  ,
                         povlines     = 1.9 ,
                         colvar       = NULL,
                         rowvar       = NULL,
                         super_rowvar = NULL,
                         super_colvar = NULL,
                         calc_vars    = "pov_status",
                         stats        = "mean") {

  #----------------------------------------------------------
  #   Load and prepare data
  #----------------------------------------------------------


  # Load data
  DT <- tm_build_DT(countries = countries,
                 years = years)

  # Poverty status
  for (i in povlines) {
    nvar <- paste0("pov_status",i)
    DT[, (nvar) :=  welfare_ppp < i ]
  }

  # Expand poverty status for all povlines in case it is selected
  if ("pov_status"  %in% calc_vars) {
    calc_vars <- calc_vars[!calc_vars %in% "pov_status"]
    calc_vars <- c(calc_vars, grep( "^pov_status", names(DT), value = TRUE))
  }


  # Selected and final variables to make DT smaller
  svars  <- c(colvar, rowvar, super_colvar, super_rowvar, calc_vars) # Selected vars
  fvars <- unique(c("weight", "welfare", "welfare_ppp",  "surveyid", svars)) # final vars
  DT <- DT[, ..fvars]


  #--------- Summarise several columns by group

  # get variable by which data will be filtered
  keyby_var <- "list(surveyid"
  new_names <- NULL
  nk <- 1    # counter. [1] == surveyid

  # (Sction to softcode)
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


  #--------- Lines of estimation
  # (Sction to softcode)

  stats_text <- NULL
  stats_ord <- NULL
  for (i in seq_along(stats)) {
    if (stats[i] == "mean") {
      stats_text <- paste("lapply(.SD, weighted.mean, w = weight , na.rm = TRUE)",
                          stats_text, sep = ",")
      stats_ord <- c(stats[i], stats_ord)
    }
    if (stats[i] == "sum") {
      stats_text <- paste("lapply(.SD, weighted.sum, w = weight, na.rm = TRUE)",
                          stats_text, sep = ",")
      stats_ord <- c(stats[i], stats_ord)
    }
    if (stats[i] == "max") {
      stats_text <- paste("lapply(.SD, max, na.rm = TRUE)", stats_text, sep = ",")
      stats_ord <- c(stats[i], stats_ord)
    }

    if (stats[i] == "min") {
      stats_text <- paste("lapply(.SD, min, na.rm = TRUE)", stats_text, sep = ",")
      stats_ord <- c(stats[i], stats_ord)
    }

  } # end of loop
  stats_text <- gsub("(.*),$" ,"\\1" ,stats_text)
  stats_text <- parse(text = paste0("c(",stats_text, ")"))


  #----------------------------------------------------------
  #   Parsing info to data.table an make calculations
  #----------------------------------------------------------

  #--------- parse in Data Table

  # calculation variables pattern
  cv <- paste(as.character(calc_vars), collapse  = "|")

  DT <- DT[, eval(stats_text),
     .SDcols = patterns(cv),
     keyby = eval(keyby_text)]


  #--------- Format output
  # if there are variables besides surveyid are used in by
  if (nk > 1) {
    data.table::setnames(DT, 2:nk, new_names)
  }

  # include stats name in variable output
  a <- expand.grid(x = calc_vars, y = stats_ord, stringsAsFactors = FALSE)
  new_calc_var <- paste0(a$x, "(", a$y, ")" )

  data.table::setnames(DT,  make.names(names = names(DT), unique=TRUE)) # make unique names
  data.table::setnames(DT, grep(cv, names(DT), value = TRUE),
                       new_calc_var)

  return(DT)
}

weighted.sum <- function(x, w = 1, na.rm = FALSE) {
  sum(x*w, na.rm = na.rm)
}
