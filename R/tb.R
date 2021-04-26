#' Table Baker: cross-tabulate statistics for PIP microdata
#'
#' @param .data dataframe with microdata information
#' @param vars variables to analyze. If "pov_status" selected, estimates will be
#'   done for poverty status for each value in `povline`
#' @param weight sampling weight variable
#' @param col column variable
#' @param row row variables
#' @param scol super column variable
#' @param srow super row variable
#' @param by_vars combination of `c(col, row, scol, srow)`
#' @param stats Statistics to estimate
#' @param format character: Either "long" or "wide". Default is "long"
#' @param povline numeric: vector with poverty lines at daily 2011 ppp values.
#'   Default is 1.9
#'
#' @return
#' @export
#'
#' @import collapse
#' @import data.table
#'
#' @examples
#' dt <- pipload::pip_load_cache("PRY", 2019, tool = "TB")
#' tb(dt,
#' vars = "welfare_ppp",
#' weight = "weight")[]
tb <- function(.data,
               vars,
               weight     = NULL,
               col        = NULL,
               row        = NULL,
               scol       = NULL,
               srow       = NULL,
               by_vars    = c(col, row, scol, srow),
               stats      = "mean",
               format     = c("long", "wide"),
               povline    = 1.9,
               by_survey  = FALSE
               ) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Check inputs   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  check_input_tb(.data   = .data,
                 vars    = vars,
                 weight  = weight,
                 col     = col,
                 row     = row,
                 scol    = scol,
                 srow    = srow,
                 by_vars = by_vars,
                 stats   = stats)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # process parameters   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  stats  <-
    match.arg(
      stats,
      c(
        "mean",
        "sum",
        "min",
        "max",
        "mode",
        "median",
        "nth",
        "Nobs",
        "Ndistinct"
      ),
      several.ok = TRUE
    )

  format <- match.arg(format)

  if (length(stats) == 1) {
    format = "wide"
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## By vars --------

  if (!is.null(by_vars) && isTRUE(by_survey)) {

    by_vars <- c("survey_id", by_vars)

  } else if (is.null(by_vars) && isTRUE(by_survey)) {

    by_vars <- "survey_id"

  } else if (is.null(by_vars) && isFALSE(by_survey)) {

      by_vars <- 1

  }



  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## poverty lines --------

  if ("pov_status" %in% vars) {

    for (i in seq_along(povline)) {
      name_var <- paste0("poor_", povline[i])
      .data[, (name_var) := as.numeric(welfare_ppp < povline[i]) ]
    }

    poor_vars <- grep("^poor_", names(.data), value = TRUE)
    vars <- vars[!(vars %in% "pov_status")]
    vars <- c(vars, poor_vars)

  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## weights --------

  if (is.null(weight)) {
    weights <- rep(1, nrow(.data))
  } else {
    weights <- .data[[weight]]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## stats --------
  # wstats <- c("mean", "sum", "median", "mode", "nth") # weighted stats
  # rstats <- c("min", "max", "Nobs", "Ndistinct")      # no weighted stats

  fs <- paste0("f", stats)


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # calculations using collapse   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  suppressWarnings({
    dt <- collapv(.data,
                   cols   = vars,
                   by     = by_vars,
                   w      = weights,
                   FUN    = fs,
                   return = format)
  })

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## format data --------
  if (length(stats) == 1) {

    setDT(dt)
    dt[, estimate := (stats)]

  } else {

    setDT(dt)
    setnames(dt, c("Function", "weights"), c("estimate", "population"))
    dt[, estimate := gsub("^f", "", estimate)]

  }

  if (is.character(by_vars)) {
    setcolorder(dt, c("estimate", by_vars))
  } else {
    setcolorder(dt, "estimate")
  }

  return(dt)

}


