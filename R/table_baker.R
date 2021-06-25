fake_load <- function(country, year) {
  callf <- paste0('pipload::pip_load_cache(country = ' ,
                 country,
                 ', year = ', year,') ')
  print(callf)
}
fake_load("COL", 2009)

table_baker <- function(vars       = NULL,
                        weight     = NULL,
                        col        = NULL,
                        row        = NULL,
                        scol       = NULL,
                        srow       = NULL,
                        by_vars    = c(col, row, scol, srow),
                        stats      = "mean",
                        format     = c("long", "wide"),
                        povline    = 1.9,
                        by_survey  = getOption("by_survey.tb"),
                        id_var     = c("cache_id", "survey_id"),
                        ...) {

  dots        <- match.call(expand.dots = FALSE)$...
  dots        <- lapply(dots, deparse)
  dots_names  <- names(dots)
  y.countries <- grep("y\\.[a-zA-Z]{3}",
                      dots_names,
                      value = TRUE)
  countries_values <- dots[y.countries]

  country_codes <- toupper(gsub("y\\.", "", y.countries))

  # names(countries_values) <- country_codes

  year_call <- vector(mode = "list",
                      length = length(country_codes))

  for (i in seq_along(country_codes)) {
    year_call[[i]] <- countries_values[[i]]
  }
  purrr::pwalk(list(country = country_codes,
                    year    = year_call),
               fake_load)
}
# debugonce(table_baker)
dd <- table_baker(y.col = c(2010, 2012),
                  y.pry = c(2006:2010),
                  x = c(4,5), y = 8, "ff")





  # Basic use. mean default
  tb(dt,
     vars = "welfare_ppp",
     weight = "weight")[]
