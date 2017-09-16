#' Get JPGIS2.1 Data
#'
#' \code{getKSJData} tries to download and load spatial data from Kokudo Suuchi service. Note that this function
#' does not use API; directly download ZIP file and load the data by \link[sf]{read_sf}.
#' \code{translateKSJColnames} translates the column names of data (e.g. W05_001) into human readable ones.
#' By default, this is automatically done in \code{getKSJData}.
#'
#' @param zip_file
#'   Either a URL, a path to a zip file, or a path to a directory which contains shape files.
#' @param cache_dir
#'   Path to a directory for caching zip files.
#' @param encoding
#'   Encoding of the data.
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @examples
#' \dontrun{
#' l <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip")
#' names(l)
#' str(l, max.level = 1)
#'
#' l_translated <- translateKSJData(l)
#' names(l)
#' }
#'
#' @export
getKSJData <- function(zip_file,
                       cache_dir = tempdir(),
                       encoding = "CP932") {

  if (!rlang::is_scalar_character(zip_file)) {
    stop("zip_file must be eighter a character of URL, path to file, or path to directory!")
  }

  # if zip_file is a URL, download it
  if (is_url(zip_file)) {
    zip_file <- download_KSJ_zip(zip_file, cache_dir)
  }

  if (!file.exists(zip_file)) {
    stop(glue::glue("{zip_file} doesn't exist"))
  }

  temp_data_dir <- tempfile()
  on.exit(unlink(temp_data_dir, recursive = TRUE))
  if (is_file(zip_file)) {
    # when zip file is a file, extract it to a temp directory.
    utils::unzip(zip_file, exdir = temp_data_dir)
  } else {
    # when zip_file is a directory, copy files within it to a temp directory
    message(glue::glue("Copying data from {zip_file} to {temp_data_dir}..."))
    copy_files_recursively(zip_file, temp_data_dir)
  }

  shp_files <- list.files(temp_data_dir, pattern = ".*\\.shp$", recursive = TRUE, full.names = TRUE)

  # set names to make each layer named
  shp_files <- rlang::set_names(shp_files,
                                tools::file_path_sans_ext(basename(shp_files)))

  # read all data
  result <- purrr::map(shp_files,
                       sf::read_sf,
                       # All data is encoded with Shift_JIS as described here:
                       # http://nlftp.mlit.go.jp/ksj/old/old_data.html
                       options = glue::glue("ENCODING={encoding}"))

  # suggest useful links
  suggest_useful_links(basename(shp_files))

  result
}



download_KSJ_zip <- function(zip_url, cache_dir) {
  # if it doesn't esist, create it.
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  # if it is not directory, something is wrong...
  if (!is_dir(cache_dir)) stop(glue::glue("{cache_dir} is not directory!"))

  zip_file <- file.path(cache_dir, basename(zip_url))

  if (file.exists(zip_file)) {
    message(glue::glue("Using the cached zip file: {zip_file}"))
  } else {
    tmp_zip_file <- tempfile(fileext = ".zip")
    curl::curl_download(zip_url, destfile = tmp_zip_file)
    file.rename(tmp_zip_file, zip_file)
  }

  zip_file
}


suggest_useful_links <- function(x) {
  # when called by :: and package is not loaded to namespace, we have to make sure the data is loaded
  make_sure_data_is_loaded("KSJMetadata_description_url")

  # extract codes from x
  identifiers <- x %>%
    stringr::str_extract(identifier_regex) %>%
    purrr::discard(is.na) %>%
    unique

  useful_links <- KSJMetadata_description_url %>%
    dplyr::filter(.data$identifier %in% identifiers) %>%
    dplyr::pull(.data$url) %>%
    unique

  if (length(useful_links) > 0) {
    msg <- sprintf("\nDetails about this data can be found at %s\n", paste(useful_links, collapse = ", "))
    message(msg)
  }
}


copy_files_recursively <- function(from, to) {
  # to must not exist
  if (file.exists(to)) stop(glue::glue("{to} already exists."))

  tmp_to <- tempfile()
  on.exit(unlink(tmp_to, recursive = TRUE))
  dir.create(tmp_to)

  # e.g) file.copy("a/", "b/", recursive = TRUE) creates "a/b/", but we need "b/"...
  file.copy(from = from, to = tmp_to, recursive = TRUE)

  to_dir <- list.files(tmp_to, full.names = TRUE)
  if (length(to_dir) != 1) stop("something is wrong.")

  file.rename(to_dir, to)
}


is_installed <- function(pkg) {
  system.file(package = pkg) != ""
}

is_url <- function(x) grepl("^https?:", x)

is_file <- function(x) file.exists(x) && !dir.exists(x)
is_dir  <- function(x) dir.exists(x)
