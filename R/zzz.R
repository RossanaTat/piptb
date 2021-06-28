pip_pipedir = '//w1wbgencifs01/pip/pip_ingestion_pipeline/'
pipuax_default_options <- list(
  pip.pipedir     = pip_pipedir,
  pip.cachedir.tb = paste0(pip_pipedir, 'tb_data/cache/clean_survey_data/'),
  by_survey.tb    = TRUE,
  piptb.max_country = 5,
  piptb.max_survey  = 15,
  piptb.all_countries = c("AGO", "ALB", "ARE", "ARG", "ARM", "AUS", "AUT", "AZE", "BDI", "BEL", "BEN", "BFA", "BGD", "BGR", "BIH", "BLR", "BLZ", "BOL", "BRA", "BTN", "BWA", "CAF", "CAN", "CHE", "CHL", "CHN", "CIV", "CMR", "COD", "COG", "COL", "COM", "CPV", "CRI", "CYP", "CZE", "DEU", "DJI", "DNK", "DOM", "DZA", "ECU", "EGY", "ESP", "EST", "ETH", "FIN", "FJI", "FRA", "FSM", "GAB", "GBR", "GEO", "GHA", "GIN", "GMB", "GNB", "GRC", "GTM", "GUY", "HND", "HRV", "HTI", "HUN", "IDN", "IND", "IRL", "IRN", "IRQ", "ISL", "ISR", "ITA", "JAM", "JOR", "JPN", "KAZ", "KEN", "KGZ", "KIR", "KOR", "LAO", "LBN", "LBR", "LCA", "LKA", "LSO", "LTU", "LUX", "LVA", "MAR", "MDA", "MDG", "MDV", "MEX", "MKD", "MLI", "MLT", "MMR", "MNE", "MNG", "MOZ", "MRT", "MUS", "MWI", "MYS", "NAM", "NER", "NGA", "NIC", "NLD", "NOR", "NPL", "NRU", "PAK", "PAN", "PER", "PHL", "PNG", "POL", "PRT", "PRY", "PSE", "ROU", "RUS", "RWA", "SDN", "SEN", "SLB", "SLE", "SLV", "SOM", "SRB", "SSD", "STP", "SUR", "SVK", "SVN", "SWE", "SWZ", "SYC", "SYR", "TCD", "TGO", "THA", "TJK", "TKM", "TLS", "TON", "TTO", "TUN", "TUR", "TUV", "TWN", "TZA", "UGA", "UKR", "URY", "USA", "UZB", "VEN", "VNM", "VUT", "WSM", "XKX", "YEM", "ZAF", "ZMB", "ZWE")
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(pipuax_default_options) %in% names(op))
  if (any(toset)) options(pipuax_default_options[toset])

  invisible()
}
