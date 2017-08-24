#' Get JPGIS2.1 Data
#'
#' Tries to download and load spatial data from Kokudo Suuchi service. Note that this function
#' does not use API; directly download ZIP file and load the data by \link[maptools]{readShapeSpatial}.
#' (This is experimental and might not work well for all data.)
#'
#' @param zip_url
#'   The URL of the Zip file.
#' @param translate_columns
#'   If \code{TRUE}, try to use human-readable column names.
#'   See \link{KSJShapeProperty} for more information about the corresponding table.
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @examples
#' \dontrun{
#' l <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip")
#' names(l)
#' str(l, max.level = 1)
#' }
#'
#' @export
getKSJData <- function(zip_url, translate_columns = TRUE) {
  if (!is_installed("sf")) stop("Please install sf if you want to use this feature.")

  tmp_dir_parent <- tempdir()
  url_hash <- digest::digest(zip_url)
  data_dir <- file.path(tmp_dir_parent, url_hash)

  use_cached <- FALSE
  if(!dir.exists(data_dir)) {
    dir.create(data_dir)
    tmp_file <- tempfile(fileext = "zip")
    curl::curl_download(zip_url, destfile = tmp_file)
    utils::unzip(tmp_file, exdir = data_dir)
    unlink(tmp_file)
  } else {
    use_cached <- TRUE
    message("Using cached data.\n")
  }

  # rebase data_dir
  meta_file <- list.files(data_dir, pattern = "KS-META.*\\.xml", recursive = TRUE, full.names = TRUE)
  if (length(meta_file) == 0) stop("The data contains no META file!")
  if (length(meta_file) > 1) stop("The data contains multiple META file!")
  data_dir <- dirname(meta_file)

  # CP932 filenames cannot be handled on non-CP932 systems. Rename them.
  if (!identical(.Platform$OS.type, "windows") && !use_cached) {
    file_names_cp932 <- list.files(data_dir)
    file_names_utf8 <- iconv(file_names_cp932, from = "CP932", to = "UTF-8")
    file.rename(file.path(data_dir, file_names_cp932),
                file.path(data_dir, file_names_utf8))
  }

  layers <- sf::st_layers(data_dir)
  layer_names <- purrr::set_names(layers$name)

  result <- purrr::map(layer_names,
                       read_shape_spatial, dsn = data_dir, translate_columns = translate_columns)
  result
}

read_shape_spatial <- function(dsn, layer, translate_columns = TRUE) {
  d <- sf::read_sf(dsn = dsn, layer = layer)

  suggest_useful_links(colnames(d))

  if (translate_columns) {
    translate_KSJ_colnames(d)
  } else {
    d
  }
}

translate_KSJ_colnames <- function(d) {
  colnames_orig <- colnames(d)

  KSJ_code_to_name <- purrr::set_names(KSJShapeProperty$name, KSJShapeProperty$code)

  # some column names cannot be converted, so fill it with the original name
  colnames_readable <- dplyr::coalesce(KSJ_code_to_name[colnames_orig], colnames_orig)

  message("converted:")
  message(paste(colnames_orig, colnames_readable, sep = " => ", collapse = "\n"))

  colnames(d) <- colnames_readable
  d
}

suggest_useful_links <- function(codes) {
  categories <- KSJShapeProperty %>%
    dplyr::filter(.data$code %in% codes) %>%
    dplyr::pull(category) %>%
    unique

  urls <- sprintf("http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-%s.html", categories)
  message(sprintf("\nDetails about this data may be found at %s\n", paste(urls, collapse = ", ")))
}

is_installed <- function(pkg) {
  system.file(package = pkg) != ""
}
