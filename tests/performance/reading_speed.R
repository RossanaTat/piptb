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
library(ggpubr)


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

autoplot(mbm2_p)
autoplot(mbm3_p)
autoplot(mbm4_p)

#--------- SSD drive in the server
cty <- sample(av_country, size = 50, replace = FALSE)

mbm_e <- mbm_fn(cty, 1, drive = "e")

cty <- "COL"
mbm2_e  <-  mbm_fn(cty, 50, drive = "e")


cty <- "IND"
mbm3_e <-  mbm_fn(cty, 50, drive = "e")


cty  <- "BRA"
mbm4_e <-  mbm_fn(cty, 50, drive = "e")


autoplot(mbm2_e)
autoplot(mbm3_e)
autoplot(mbm4_e)

#------------------------
# Better charts
#-----------------------

viochart <- function(mth) {

  vc <- ggplot(mth, aes(x=expr,
                     y=time,
                     fill = expr)) +
    geom_violin(trim=FALSE) +
    coord_flip() +
    stat_summary(fun.y=median, geom="point",
                 size=1,
                 color="black") +
    theme(legend.position="none") +
    labs(y="Time (seconds)",
         x = "File Format")

  return(vc)

}


a <- c(2:4)
b <- c("e", "p")
lmbm <- lmbm <- vector(mode="list",
                       length=length(a)*length(b))
lmbm

n <- 0
for (j in b) {
  for (i in a) {
    n <- n + 1
    nname <- paste0("vmbm",i,j)
    oname <- paste0("mbm",i,"_", j)
    names(lmbm)[n] <- nname
    lmbm[[nname]] <- get(oname)
  }
}

for (i in seq_along(lmbm)) {
  a <- viochart(lmbm[[i]])
  assign(names(lmbm[i]), a)
}

figure <- ggarrange( ggarrange(vmbm2e,vmbm3e, vmbm4e,
                               nrow = 3,
                               labels = c("COL", "IND", "BRA"),
                               font.label = list(size = 11, color = "#00AFBB")),
                     ggarrange(vmbm2p,vmbm3p, vmbm4p,
                               nrow = 3,
                               labels = c("COL", "IND", "BRA"),
                               font.label = list(size = 11, color =  "#E7B800")),
                     ncol = 2)

annotate_figure(figure,
                top = text_grob(paste0("SSD", stringr::str_dup(" ", 35), "Network Drive"),
                                face = "bold", size = 16))

