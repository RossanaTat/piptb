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

library(microbenchmark)
library(ggplot2)


#----------------------------------------------------------
#   subfunctions
#----------------------------------------------------------
mbm_fn <- function(cty, times = 50, drive = "p") {

  mbm <-  microbenchmark(
    feather  = purrr::walk(cty, tm_build_DT, formt = "feather", drive = drive),
    RData    = purrr::walk(cty, tm_build_DT, formt = "RData",   drive = drive),
    Rds      = purrr::walk(cty, tm_build_DT, formt = "Rds",     drive = drive),
    dta      = purrr::walk(cty, tm_build_DT, formt = "dta",     drive = drive),
    fst      = purrr::walk(cty, tm_build_DT, formt = "fst",     drive = drive),
    times    = times
  )
  return(mbm)
}

#----------------------------------------------------------
#   parameters
#----------------------------------------------------------

maindir <- ":/03.ProjectX/data"
drive   <- "p"
wrkdir <- paste0(drive, maindir)

av_country <- list.dirs(path = wrkdir, recursive = FALSE, full.names = FALSE)
av_country <- av_country[!(grepl(pattern = "^_", av_country))] # remove folders starting with _


#----------------------------------------------------------
#   execution
#----------------------------------------------------------

cty <- sample(av_country, size = 2, replace = FALSE)
cty <- sample(av_country, size = 50, replace = FALSE)

#--------- network drive

mbm_p <- mbm_fn(cty, 1)

cty <- "COL"
mbm2_p  <-  mbm_fn(cty, 50)


cty <- "IND"
mbm3_p <-  mbm_fn(cty, 50)


cty  <- "BRA"
mbm4_p <-  mbm_fn(cty, 50)

autoplot(mbm_p)
autoplot(mbm2_p)
autoplot(mbm3_p)
autoplot(mbm4_p)

#--------- SSD drive in the server

mbm_e <- mbm_fn(cty, 1, drive = "e")

cty <- "COL"
mbm2_e  <-  mbm_fn(cty, 50, drive = "e")


cty <- "IND"
mbm3_e <-  mbm_fn(cty, 50, drive = "e")


cty  <- "BRA"
mbm4_e <-  mbm_fn(cty, 50, drive = "e")

autoplot(mbm_e)
autoplot(mbm2_e)
autoplot(mbm3_e)
autoplot(mbm4_e)





