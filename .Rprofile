
if (Sys.info()["nodename"] == "WBGMSDDG001") {
  root_dir     <- Sys.getenv("PIP_DATA_ROOT_FOLDER_SERVER")
} else {
  root_dir     <- Sys.getenv("PIP_DATA_ROOT_FOLDER")
}
gls          <- pipload::pip_create_globals(root_dir)
arrow_format <- "parquet"
arrow_dir    <- paste0(gls$TB_ARROW, arrow_format, "/")
data_connect <- arrow::open_dataset(arrow_dir, format = arrow_format)

message("Hey, welcome to R. Ready to work")

