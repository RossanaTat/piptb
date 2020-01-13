# ==================================================
# project:       calculations with tm_build data
# Author:        Andres Castaneda
# Dependencies:  The World Bank
# ----------------------------------------------------
# Creation Date:    01/10/2020
# Modification Date:
# Script version:    01
# References:
#
#
# Output:             output
# ==================================================

#----------------------------------------------------------
#   Load libraries
#----------------------------------------------------------

library("tidyverse")
library(microbenchmark)
library(ggplot2)


#----------------------------------------------------------
#   subfunctions
#----------------------------------------------------------

maindir <- ":/03.ProjectX/data"
drive   <- "p"
wrkdir <- paste0(drive, maindir)


av_country <- list.dirs(path = wrkdir, recursive = FALSE, full.names = FALSE)
av_country <- av_country[!(grepl(pattern = "^_", av_country))] # remove folders starting with _


cty <- sample(av_country, size = 50, replace = TRUE)

mbm = microbenchmark(
  feather = purrr::walk(cty, tm_build, formt = "feather", default = TRUE),
  RData = purrr::walk(cty, tm_build, formt = "RData", default = TRUE),
  Rds = purrr::walk(cty, tm_build, formt = "Rds", default = TRUE),
  dta = purrr::walk(cty, tm_build, formt = "dta", default = TRUE),
  times = 2
)
mbm


cty <- "COL"
mbm2 = microbenchmark(
  feather = purrr::walk(cty, tm_build, formt = "feather", default = TRUE),
  RData = purrr::walk(cty, tm_build, formt = "RData", default = TRUE),
  Rds = purrr::walk(cty, tm_build, formt = "Rds", default = TRUE),
  dta = purrr::walk(cty, tm_build, formt = "dta", default = TRUE),
  times = 50
)
mbm2

cty <- "IND"
mbm3 = microbenchmark(
  feather = purrr::walk(cty, tm_build, formt = "feather", default = TRUE),
  RData = purrr::walk(cty, tm_build, formt = "RData", default = TRUE),
  Rds = purrr::walk(cty, tm_build, formt = "Rds", default = TRUE),
  dta = purrr::walk(cty, tm_build, formt = "dta", default = TRUE),
  times = 50
)
mbm3

cty <- "BRA"
mbm4 = microbenchmark(
  feather = purrr::walk(cty, tm_build, formt = "feather", default = TRUE),
  RData = purrr::walk(cty, tm_build, formt = "RData", default = TRUE),
  Rds = purrr::walk(cty, tm_build, formt = "Rds", default = TRUE),
  dta = purrr::walk(cty, tm_build, formt = "dta", default = TRUE),
  times = 50
)
mbm4

autoplot(mbm)
autoplot(mbm2)
autoplot(mbm3)
autoplot(mbm4)
