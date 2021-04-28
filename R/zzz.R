pip_pipedir = '//w1wbgencifs01/pip/pip_ingestion_pipeline/'
pipuax_default_options <- list(
  pip.pipedir     = pip_pipedir,
  pip.cachedir.tb = paste0(pip_pipedir, 'tb_data/cache/clean_survey_data/'),
  by_survey.tb    = TRUE
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(pipuax_default_options) %in% names(op))
  if (any(toset)) options(pipuax_default_options[toset])

  invisible()
}
