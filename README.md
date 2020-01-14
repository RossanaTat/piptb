
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tablemaker

### This README.md is justa place holder... it does reflect the real progress of the project. 

<!-- badges: start -->

<!-- badges: end -->

The goal of tablemaker is to load the data and make the calculations for
the UI Table Maker of Project X

## Installation

You can install the released version of tablemaker from
[CRAN](https://CRAN.R-project.org) with **Not working yet**:

``` r
#install.packages("tablemaker")
```

And the development version from [GitHub](https://github.com/) with **not ready yet**:

``` r
# install.packages("devtools")
devtools::install_github("randrescastaneda/tablemaker")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(tablemaker)

## basic example code
tm_load(country = "COL", year = 2014)
#> Loading  COL_2014_GEIH_v01_M_v03_A_GMD_GPWG
#> # A tibble: 783,317 x 29
#>    countrycode  year hhid  welfare subnatid subnatid2 subnatid3 welfarenom
#>    <chr>       <dbl> <chr>   <dbl> <chr>    <chr>     <chr>          <dbl>
#>  1 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  2 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  3 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  4 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  5 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  6 COL          2014 3374… 3865394 2 - Ori… 15 -  Bo… ""           3865394
#>  7 COL          2014 3374… 7024188 2 - Ori… 15 -  Bo… ""           7024188
#>  8 COL          2014 3374… 7024188 2 - Ori… 15 -  Bo… ""           7024188
#>  9 COL          2014 3374… 7024188 2 - Ori… 15 -  Bo… ""           7024188
#> 10 COL          2014 3374… 7024188 2 - Ori… 15 -  Bo… ""           7024188
#> # … with 783,307 more rows, and 21 more variables: welfaredef <dbl>,
#> #   welfareother <dbl>, welfareothertype <chr>, pid <dbl>, weight <dbl>,
#> #   age <dbl>, male <dbl+lbl>, urban <dbl+lbl>, hsize <dbl>,
#> #   welfshprosperity <dbl>, code <chr>, cpi2011 <dbl>, icp2011 <dbl>,
#> #   cpi_domain <dbl+lbl>, cpi_domain_value <dbl>, cpi2011_unadj <dbl>,
#> #   cpi2011_SM19 <dbl>, icp2011_SM19 <dbl>, cpi2011_unadj_SM19 <dbl>,
#> #   cpi2005_SM19 <dbl>, icp2005_SM19 <dbl>
```
