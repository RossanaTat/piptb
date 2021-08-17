#' Create Arrow files of precalculated table Maker indicators
#'
#' @param country character: vector with country codes
#' @param year numeric: Survey years
#' @param survey_acronym character: Survey acronym when there is more than one
#'   survey per year. It only works if `length(country) == 1`
#' @param data_level charater: Data domain. it could be D1 for national, D2 for
#'   urban/rural, or D3 for subnational
#'
#' @return
#' @export
#'
#' @examples
tb_create_arrow <- function(country        = NULL,
                            year           = NULL,
                            survey_acronym = NULL,
                            data_level     = NULL,
                            arrow_format   = c("parquet", "feather"),
                            root_dir       = Sys.getenv("PIP_root_dir")) {

  # on.exit ------------
  on.exit({
    if (requireNamespace("pushoverr", quietly = TRUE)) {
      pushoverr::pushover("Done creating Arrow files")
    }
  })

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## Check arguments --------
  arrow_format <- match.arg(arrow_format)


  # Defenses -----------

  stopifnot(
    all(country  %in% getOption("piptb.all_countries"))
  )

  # Early returns ------
  if (TRUE) {
    return(TRUE)
  }

  # Computations -------


  # Return -------------


}
