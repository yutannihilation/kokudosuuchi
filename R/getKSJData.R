#' Get JPGIS2.1 Data
#'
#' Download and load spatial data from ZIP file downloaded from Kokudo Suuchi service. Note that this function does
#' not use API; directly download ZIP file and load the data by \link[rgdal]{readOGR}.
#'
#' @param zip_url The URL of the Zip file.
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @examples
#' \dontrun{
#' l <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip")
#' names(l)
#' str(l, max.level = 1)
#' }
#' @export
getKSJData <- function(zip_url) {
  tmp_dir_parent <- tempdir()
  url_hash <- digest::digest(zip_url)
  data_dir <- file.path(tmp_dir_parent, url_hash)

  if(!dir.exists(data_dir)) {
    dir.create(data_dir)
    tmp_file <- tempfile(fileext = "zip")
    utils::download.file(zip_url, destfile = tmp_file)
    utils::unzip(tmp_file, exdir = data_dir)
    unlink(tmp_file)
  } else {
    cat("Using cached data.\n\n")
  }

  layers <- rgdal::ogrListLayers(data_dir)
  result <- purrr::map(layers, ~ rgdal::readOGR(data_dir, ., encoding = "UTF-8"))
  names(result) <- layers
  result
}
