#' Table Baker heap: cross-tabulate combining all possibilities in one single
#' household survey
#'
#' @param .data dataframe with microdata information
#' @param int_vars variables of interest to analyze and combine. Include welfare
#'   and poverty status
#' @param weight sampling weight variable
#' @param dimensions all dimensions variables to combine
#' @param stats all possible statistics
#' @param format character: Either "long" or "wide". Default is "long"
#' @param povlines numeric: vector with poverty lines at daily 2011 ppp values.
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
tb_heap <- function(.data,
               int_vars   = getOption("pip.int_vars"),
               weight     = getOption("pip.weight"),
               dimensions = getOption("pip.dimensions"),
               stats      = getOption("pip.stats"),
               format     = c("long", "wide"),
               povlines   = getOption("pip.pov_lines")
) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # set upt   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  format <- match.arg(format)


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # dimensions combinatory   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # at most 4 combinations
  i = 1:4
  cms <- purrr::map(.x = i,
                    .f = ~{
                      # create combination
                      cc <- utils::combn(x = dimensions, m = .x)
                      # convert matrix into list
                      as.list(as.data.frame(cc))
                     }
                    )

  # Remove one level of list to get just the combinations
  cms <- unlist(cms, recursive = FALSE)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # calculations   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  dl  <- purrr::map(.x = cms,
                    .f = ~tb(
                      .data    = .data,
                      vars     = int_vars,
                      weight   = weight,
                      by_vars  = .x,
                      stats    = stats,
                      format   = format,
                      povlines = povlines))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Format data   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Convert to data frame
  dt <- data.table::rbindlist(dl,
                              use.names = TRUE,
                              fill = TRUE)

  # number of dimensions
  lcols <- length(dimensions)

  # Calculate number of no NAs columns in each observations to
  # know the number of dimensions used

  dt[,
     nvars := lcols - Reduce("+", lapply(.SD, is.na)),
     .SDcols = dimensions]

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Re name variables   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # dt <- dt[, !"ID"]

  ## prefix dim to dimensions variables
  data.table::setnames(dt,
                       dimensions,
                       paste0("dim_", dimensions))

  ## preffix int for variables of interest

  intvars <- grep("^(welfare|poor)", names(dt), value = TRUE)
  data.table::setnames(dt,
                       intvars,
                       paste0("int_", intvars))

  return(dt)

}


