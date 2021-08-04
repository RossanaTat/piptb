#' Table Baker: cross-tabulate statistics for PIP microdata
#'
#' @param .data dataframe with microdata information
#' @param vars variables to analyze. If "pov_status" selected, estimates will be
#'   done for poverty status for each value in `povlines` If NULL, size
#'   population of population in each group is calculated
#' @param weight sampling weight variable
#' @param col column variable
#' @param row row variables
#' @param scol super column variable
#' @param srow super row variable
#' @param by_vars combination of `c(col, row, scol, srow)`
#' @param stats Statistics to estimate
#' @param format character: Either "long" or "wide". Default is "long"
#' @param povlines numeric: vector with poverty lines at daily 2011 ppp values.
#'   Default is 1.9
#' @param by_survey logical: If TRUE include variable "cache_id" as part of the
#'   grouping variables.
#' @param id_var characger: variable used to uniquely identify surveys. It could
#'   be "cache_id" or "survey_id". Default is "cache_id".
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
               vars       = NULL,
               weight     = NULL,
               col        = NULL,
               row        = NULL,
               scol       = NULL,
               srow       = NULL,
               by_vars    = c(col, row, scol, srow),
               stats      = "mean",
               format     = c("long", "wide"),
               povlines    = 1.9,
               by_survey  = getOption("by_survey.tb"),
               id_var     = c("cache_id", "survey_id")
               ) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Check inputs   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   check_input_tb(.data   = .data,
#                  vars    = vars,
#                  weight  = weight,
#                  col     = col,
#                  row     = row,
#                  scol    = scol,
#                  srow    = srow,
#                  by_vars = by_vars,
#                  stats   = stats)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # process parameters   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  data.table::setDT(.data)
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## vars --------
  if (is.null(vars)) {
    .data[, ones.. := 1]
    vars <- "ones.."
  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## stats --------
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

  fs <- paste0("f", stats)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## format --------

  format <- match.arg(format)

  if (length(stats) == 1) {
    format = "wide"
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## By vars --------
  id_var <- match.arg(id_var)

  if (!is.null(by_vars) && isTRUE(by_survey)) {

    by_vars <- c(id_var, by_vars)

  } else if (is.null(by_vars) && isTRUE(by_survey)) {

    by_vars <- id_var

  } else if (is.null(by_vars) && isFALSE(by_survey)) {

      by_vars <- 1

  }


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## poverty lines --------

  if ("pov_status" %in% vars) {

    for (i in seq_along(povlines)) {
      name_var <- paste0("poor_", povlines[i])

      # .data[[name_var]] <- as.numeric(.data$welfare_ppp < povlines[i])
      .data[, (name_var) := as.numeric(welfare_ppp < povlines[i]) ]
    }

    poor_vars <- grep("^poor_", names(.data), value = TRUE)
    vars <- vars[!(vars %in% "pov_status")]
    vars <- c(vars, poor_vars)

  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## weights --------

  if (is.null(weight)) {
    population <- rep(1, nrow(.data))
  } else {
    population <- .data[[weight]]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # calculations using collapse   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  suppressWarnings({
    dt <- collapse::collapv(.data,
                            cols   = vars,
                            by     = by_vars,
                            w      = population,
                            FUN    = fs,
                            return = format)
  })

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## format data --------
  if (length(stats) == 1) {

    setDT(dt)
    dt[, statistics := (stats)]

  } else {

    setDT(dt)
    setnames(dt, "Function", "statistics")
    dt[, statistics := gsub("^f", "", statistics)]

  }

  if (is.character(by_vars)) {
    setcolorder(dt, c("statistics", by_vars))
  } else {
    setcolorder(dt, "statistics")
  }

  if ("ones.." %in% vars) {
    dt[, ones..:= NULL]
  }

  ### change names of by variables ---------
  args <- c("col", "row", "scol", "srow")

  for (i in seq_along(args)) {

    if (!is.null(get(args[i]))) {
      nname <- paste0(args[i], ".", get(args[i]))

      oname <- paste0(get(args[i]))
      setnames(dt, oname, nname)
    }
  }

  ## id variable
  if (id_var %in% by_vars) {
    setnames(dt, id_var, "ID")
  }


  return(dt)

}


