
tm_DT_output <- function(countries,
                               years        = NA  ,
                               povlines     = 1.9 ,
                               colvar       = NULL,
                               rowvar       = NULL,
                               super_rowvar = NULL,
                               super_colvar = NULL,
                               calc_vars    = "pov_status",
                               stats        = "mean") {


  DT <- tm_build_DT(countries = countries,
                 years = years)

  # remove poverty status in case it is selected
  calc_vars_npov <- calc_vars[!calc_vars %in% "pov_status"]


  # Selected variables and final variables to make DT smaller

  svars  <- c(colvar, rowvar, super_colvar, super_rowvar, calc_vars_npov)
  fvars <- unique(c("weight", "welfare", "welfare_ppp",  "surveyid", svars))
  DT <- DT[,..fvars]

  # Poverty status
  for (i in povlines) {
    nvar <- paste0("poor_",i)
    DT[, (nvar) :=  welfare_ppp < i ]
  }


  # calculation variables
  cv <- paste(as.character(calc_vars), collapse  = "|")
  # cv <- paste0("(", cv, ")")
  # pattern <- paste0(cv, ".*", pattern)


  # Summarise several columns by group
  DT <- DT[, lapply(.SD, weighted.mean, na.rm = TRUE),
     .SDcols = patterns(cv),
     keyby = .(surveyid, get(colvar), get(rowvar))]

  return(DT)
}




DT <- tm_DT_output(countries = c("COL","COL", "PRY", "PRY"),
                   years = c(2012, 2012, 2014, 2014),
                   colvar = "urban",
                   rowvar = "male",
                   povlines = c(1.9, 3.2),
                   calc_vars = c("welfare_ppp", "pov_status"))


DT[, .(headcount = weighted.mean(poor_1.9,
                               weight,
                               na.rm = TRUE)),
   keyby = .(surveyid, urban)]


# Summarise several columns by group
DT[, lapply(.SD, weighted.mean, na.rm = TRUE),
    .SDcols = patterns("poor"),
    keyby = .(surveyid, urban, male)]










###################################################
a <- DT[surveyid == "PRY_2014_EPH_v01_M_v02_A_GMD"]
nvar <- paste0("poor_",1.9)
a[, (nvar):= welfare_ppp < 1.9]




DT1 <- readRDS("p:/03.ProjectX/data/_aux/WLD/WLD.Rds")



povline <- c(1.9, 3.2)
for (i in povlines) {
  nvar <- paste0("poor_",i)
  DT1[, (nvar) :=  welfare_ppp < i ]
}



DT1[, lapply(.SD, weighted.mean, na.rm = TRUE),
    .SDcols = patterns("poor"),
    keyby = .(surveyid, urban)]

