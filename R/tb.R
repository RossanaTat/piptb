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
               format  = c("wide", "long")
               ) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Check inputs   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  stats  <- match.arg(stats, several.ok = TRUE)
  format <- match.arg(format)

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


  ws <- intersect(stats, wstats)
  if (length(ws) > 0) {
    wfs <- paste0("f", ws)
  }


  rs <- intersect(stats, rstats)
  if (length(rs) > 0) {
    rfs <- paste0("f", rs)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # calculations using collapse   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  if (length(ws) > 0) {

    wdt <- collapv(.data,
                    cols   = vars,
                    by     = by_vars,
                    w      = weights,
                    FUN    = wfs,
                    return = format)
  }

  # Unweighted stats
  if (length(rs) > 0) {

    rdt <- collapv(.data,
                    cols   = vars,
                    by     = by_vars,
                    FUN    = rfs,
                    return = format)
  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # bind   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  if (length(rs) > 0 && length(ws) > 0) {

    dt <- data.table::rbindlist(list(wdt, rdt),
                                use.names = TRUE,
                                fill      = TRUE)
  } else if (length(rs) == 0) {
    dt <- wdt
  } else {
    dt <- rdt
  }

  return(dt)

}


