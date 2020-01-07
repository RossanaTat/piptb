
library("feather")

tm_dta2R <- function(type = "PX",
                    maindir = ":/03.ProjectX/data/",
                    drive = "p") {


  #--------- Initial conditions

  # drive and main dir

  maindir <- paste0(drive, maindir)

  if (!dir.exists(maindir)) {
    maindir <- "//wbntpcifs/povcalnet/03.ProjectX/data"
  }
  if (!dir.exists(maindir)) {
    st_msg <- paste0("main directory `", maindir,
                     "` not reachable. Check connection")
    stop(st_msg)
  }

  a <- list.files(path = paste(maindir, "COL", sep = "/"), pattern = "COL_201[56].*\\.dta$", recursive = TRUE)

  tb <- haven::read_dta(paste(maindir, "COL", a[1], sep = "/"))

  #--------- parameters

  survid = paste(
    country, year, survey, paste0("v", vermast),
    "M", paste0("v", veralt), "A", "GMD", sep = "_"
  )

  id1 = paste(country, year, sep = "_")
  id2 = paste(country, year, survey, sep = "_")


  module <- "PX"
  filename <- paste(survid, module, sep = "_")

  dtadir <- paste(dir_cys, survid, "Data", paste0(filename, ".dta"), sep = "/")

  cat("Loading ", filename, "\n")

  tb <- haven::read_dta(dtadir)

  attr(tb, "filename") <- filename
  attr(tb, "survid") <- survid
  attr(tb, "module") <- module
  attr(tb, "id1") <- id1
  attr(tb, "id2") <- id2

  return(tb)

} # end of pcn_load()

