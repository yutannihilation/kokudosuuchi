#' Get JPGIS2.1 Data
#'
#' `getKSJData()` is deprecated.
#'
#' @param zip_file
#'   Either a URL, a path to a zip file, or a path to a directory which contains shape files.
#' @param cache_dir
#'   Path to a directory for caching zip files.
#' @param encoding
#'   Encoding of the data.
#'
#' @keywords internal
#' @export
getKSJData <- function(zip_file,
                       cache_dir = tempdir(),
                       encoding = "CP932") {
  .Deprecated("readKSJData")

  readKSJData(zip_file, encoding = encoding)
}
