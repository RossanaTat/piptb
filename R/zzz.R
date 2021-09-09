
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Initial values --------

pipuax_default_options <- list(
  by_survey.tb    = TRUE,
  piptb.max_country = 5,
  piptb.max_survey  = 15,
  piptb.all_countries = c("AGO", "ALB", "ARE", "ARG", "ARM", "AUS", "AUT", "AZE", "BDI", "BEL", "BEN", "BFA", "BGD", "BGR", "BIH", "BLR", "BLZ", "BOL", "BRA", "BTN", "BWA", "CAF", "CAN", "CHE", "CHL", "CHN", "CIV", "CMR", "COD", "COG", "COL", "COM", "CPV", "CRI", "CYP", "CZE", "DEU", "DJI", "DNK", "DOM", "DZA", "ECU", "EGY", "ESP", "EST", "ETH", "FIN", "FJI", "FRA", "FSM", "GAB", "GBR", "GEO", "GHA", "GIN", "GMB", "GNB", "GRC", "GTM", "GUY", "HND", "HRV", "HTI", "HUN", "IDN", "IND", "IRL", "IRN", "IRQ", "ISL", "ISR", "ITA", "JAM", "JOR", "JPN", "KAZ", "KEN", "KGZ", "KIR", "KOR", "LAO", "LBN", "LBR", "LCA", "LKA", "LSO", "LTU", "LUX", "LVA", "MAR", "MDA", "MDG", "MDV", "MEX", "MKD", "MLI", "MLT", "MMR", "MNE", "MNG", "MOZ", "MRT", "MUS", "MWI", "MYS", "NAM", "NER", "NGA", "NIC", "NLD", "NOR", "NPL", "NRU", "PAK", "PAN", "PER", "PHL", "PNG", "POL", "PRT", "PRY", "PSE", "ROU", "RUS", "RWA", "SDN", "SEN", "SLB", "SLE", "SLV", "SOM", "SRB", "SSD", "STP", "SUR", "SVK", "SVN", "SWE", "SWZ", "SYC", "SYR", "TCD", "TGO", "THA", "TJK", "TKM", "TLS", "TON", "TTO", "TUN", "TUR", "TUV", "TWN", "TZA", "UGA", "UKR", "URY", "USA", "UZB", "VEN", "VNM", "VUT", "WSM", "XKX", "YEM", "ZAF", "ZMB", "ZWE"),
  pip.dimensions = c("gender",
                     "area",
                     "educat4",
                     "educat5",
                     "literacy",
                     "subnational_id1"),
  pip.int_vars   = c("pov_status", "welfare_ppp", "welfare_lcu"),
  pip.pov_lines  = c(1.9, 3.2, 5.5, 10, 15),
  pip.stats      = c("mean", "sum", "min", "max", "mode", "median"),
  pip.weight     = "weight"
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(pipuax_default_options) %in% names(op))
  if (any(toset)) options(pipuax_default_options[toset])

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## defined values --------
  # if you don't the official value in `Sys.getenv("PIP_ROOT_DIR")` you can
  # provide the object `root_dir  <- "<you directory>"` before executing the first
  # fucntion pipaux. In this way, object `gls`, which is a promise, will be
  # created using with you `root_dir`. Otherwise, you can especify the complete
  # directory path for each function.


  # current objects
  pipload::add_gls_to_env()

  invisible()
}
