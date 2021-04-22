#' Title
#'
#' @param .data dataframe with microdata information
#' @param vars variables to analyze
#' @param weight sampling weight variable
#' @param col column variable
#' @param row row variables
#' @param scol super column variable
#' @param srow super row variable
#' @param by_vars combination of `c(col, row, scol, srow)`
#' @param stats Statistics to estimate
#'
#' @return
#' @export
#'
#' @import collapse
#' @import data.table
#'
#' @examples
tb <- function(.data,
               vars,
               weight  = NULL,
               col     = NULL,
               row     = NULL,
               scol    = NULL,
               srow    = NULL,
               by_vars = c(col, row, scol, srow),
               stats   = c("mean", "sum", "min", "max", "mode", "median", "nth", "Nobs", "Ndistinct"),
               format  = c("long", "wide"),
               povline = 1.9
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

  stats  <- match.arg(stats, several.ok = TRUE)
  format <- match.arg(format)

  if (length(stats) == 1) {
    format = "wide"
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## poverty lines --------

  if ("pov_status" %in% vars) {

  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## weights --------

  if (is.null(weight)) {
    weights <- rep(1, nrow(df))
  } else {
    weights <- df[[weight]]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## stats --------

  wstats <- c("mean", "sum", "median", "mode", "nth") # weighted stats
  rstats <- c("min", "max", "Nobs", "Ndistinct")      # no weighted stats

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

  setcolorder(dt, c("estimate", by_vars))

  return(dt)

}


