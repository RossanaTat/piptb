
fth <- tm_load(country = "PRY", year = 2013, formt = "feather")
RDa <- tm_load(country = "PRY", year = 2013, formt = "RData")
Rds <- tm_load(country = "PRY", year = 2013, formt = "Rds")
dta <- tm_load(country = "PRY", year = 2013)

test_that("dta is equal to Rds", {
  expect_equal(dta, Rds)
})
test_that("dta is equal to feather", {
  all.equal(dta, fth)
})
test_that("dta is equal to RData", {
  expect_equal(dta, RDa)
})

