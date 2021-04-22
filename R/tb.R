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
#' @examples
tb <- function(.data,
               vars,
               weight  = NULL,
               col     = NULL,
               row     = NULL,
               scol    = NULL,
               srow    = NULL,
               by_vars = c(col, row, scol, srow),
               stats   = c("mean", "sum", "min", "max")
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




}
