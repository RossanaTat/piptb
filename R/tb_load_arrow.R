#' Load pre-computed  estimation of Table Maker
#'
#' @inheritParams tb_create_arrow
#' @inheritParams tb
#' @param ... additional parameters
#'
#' @return
#' @export
#'
#' @examples
tb_load_arrow <-
  function(country_code   ,
           surveyid_year  = NULL,
           domain         = NULL,
           welfare_type   = NULL,
           vars           = NULL,
           weight         = NULL,
           col            = NULL,
           row            = NULL,
           scol           = NULL,
           srow           = NULL,
           by_vars        = c(col, row, scol, srow),
           stats          = "mean",
           povlines       = 1.9,
           arrow_format   = c("parquet", "feather"),
           root_dir       = Sys.getenv("PIP_DATA_ROOT_FOLDER"),
           ...
  ) {

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Check arguments --------
    arrow_format <- match.arg(arrow_format)

    # get all arguments
    # argus <- c(as.list(environment()), list(...))
    argus <- c(as.list(environment()))

    # globals
    gls <- create_globals(root_dir)



    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## filter  --------

    # Build the filter

    vars_toeval <- c("country_code", "surveyid_year", "welfare_type")
    argus       <- argus[vars_toeval]
    toeval      <- vector(mode = "list")
    i           <- 0

    for(n in seq_along(argus)) {

      if (!is.null(argus[[n]])) {
        i <- i + 1

        # Name of the variable
        varname  <- names(argus[n])

        # Value to evaluate
        varvalue <- paste0("varvalue",i)
        assign(varvalue, argus[[n]])

        toeval[i] <- paste(varname, "%in%", varvalue)
      }
    }

    toeval <- paste(toeval, collapse = " & ")
    toeval <- rlang::parse_expr(toeval)

    # Working directory
    arrow_dir <- paste0(gls$TB_ARROW, arrow_format, "/")
    da <- arrow::open_dataset(arrow_dir, format = arrow_format)

    # return(toeval)
    # Computations -------

    dt <- da %>%
      dplyr::filter(rlang::eval_tidy(toeval)) %>%
      dplyr::collect()

    # Return -------------
    return(dt)

  }
