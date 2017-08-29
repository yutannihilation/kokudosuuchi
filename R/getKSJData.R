#' Get JPGIS2.1 Data
#'
#' \code{getKSJData} tries to download and load spatial data from Kokudo Suuchi service. Note that this function
#' does not use API; directly download ZIP file and load the data by \link[sf]{read_sf}.
#' \code{translateKSJColnames} translates the column names of data (e.g. W05_001) into human readable ones.
#' By default, this is automatically done in \code{getKSJData}.
#'
#' @param zip_file
#'   Either a URL, a path to a zip file, or a path to a directory which contains shape files.
#' @param translate_colnames
#'   If \code{TRUE}, try to use human-readable column names.
#'   See \link{KSJShapeProperty} for more information about the corresponding table.
#' @param reencode_attributes_to_native
#'   If \code{TRUE}, convert attributes into the native encoding.
#'
#' @seealso \url{http://nlftp.mlit.go.jp/ksj/api/about_api.html}
#' @examples
#' \dontrun{
#' l <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip")
#' names(l)
#' str(l, max.level = 1)
#'
#' l_raw <- getKSJData("http://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip",
#'                     translate_colnames = FALSE)
#' translateKSJColnames(l_raw)
#' }
#'
#' @export
getKSJData <- function(zip_file,
                       translate_colnames = TRUE,
                       reencode_attributes_to_native = TRUE) {
  # if zip_file is a URL, download it
  if (is_url(zip_file)) {
    zip_file <- download_KSJ_zip(zip_file, use_cached = TRUE)
  }

  if (is_file(zip_file)) {
    # extract the zip file
    data_dir_orig <- paste0(zip_file, ".tmp")
    on.exit(unlink(data_dir_orig, recursive = TRUE))

    extract_KSJ_zip(zip_file, data_dir_orig)
    data_dir <- rebase_KSJ_data_dir(data_dir_orig)
  } else {
    data_dir_orig <- rebase_KSJ_data_dir(zip_file)
    data_dir <- tempfile()
    on.exit(unlink(data_dir, recursive = TRUE))

    message(glue::glue("Copying data from {data_dir_orig} to {data_dir}..."))
    copy_files_recursively(data_dir_orig, data_dir)
  }

  # CP932 layer names cannot be handled on non-CP932 systems so we need to rename them
  purify_KSJ_non_utf8_layers(data_dir)

  layers <- sf::st_layers(data_dir)
  layer_names <- purrr::set_names(layers$name)

  # read all data
  result <- purrr::map(layer_names,
                       sf::read_sf,
                       dsn = data_dir)

  result_colnames <- result %>%
    purrr::map(colnames) %>%
    purrr::flatten_chr()

  # suggest useful links
  suggest_useful_links(result_colnames)

  # translate colnames to human readable ones
  if (translate_colnames) {
    result <- purrr::map(result,
                         translateKSJColnames,
                         quiet = TRUE)
  }

  # try to set the correct encoding of the attributes
  if (reencode_attributes_to_native) {
    result <- purrr::map(result,
                         reencode_KSJ_data_to_native)
  }

  result
}


download_KSJ_zip <- function(zip_url, use_cached = TRUE) {
  tmp_dir_parent <- tempdir()
  url_hash <- digest::digest(zip_url)
  zip_file <- file.path(tmp_dir_parent, glue::glue('{url_hash}.zip'))

  if (file.exists(zip_file) && use_cached) {
    message("Using the cached zip file")
  } else {
    curl::curl_download(zip_url, destfile = zip_file)
  }

  zip_file
}


extract_KSJ_zip <- function(zip_file, data_dir) {
  if (file.exists(data_dir)) stop(glue::glue("{data_dir} is not empty."))

  utils::unzip(zip_file, exdir = data_dir)

  data_dir
}


rebase_KSJ_data_dir <- function(data_dir) {
  # check if the KS-META-*.xml is located at the top of data_dir
  meta_file <- list.files(data_dir, pattern = "KS-META.*\\.xml", full.names = TRUE)
  # no need to rebase
  if (length(meta_file) == 1L) return(data_dir)

  message("It seems the data is nested; try to rebase the directory...")
  meta_file <- list.files(data_dir, pattern = "KS-META.*\\.xml", recursive = TRUE, full.names = TRUE)

  if (length(meta_file) >  1L) {
    stop("Multiple META file are found; cannot determine which directory to use!")
  }

  if (length(meta_file) == 0L) {
    warning("No META file is found; give up rebasing.")
    return(meta_file)
  }

  dirname(meta_file)
}


purify_KSJ_non_utf8_layers <- function(data_dir) {
  file_names_orig <- list.files(data_dir)

  if (all(stringi::stri_enc_isutf8(file_names_orig))) return()

  # assume the original names are cp932
  file_names_utf8 <- iconv(file_names_orig, from = "CP932", to = "UTF-8")
  # nohting happens here on windows because a CP932 string without encoding and its UTF-8 version
  # marked as UTF-8 are identical for the OS. (e.g. file.rename(x, enc2utf8(x)) does nothing).
  file.rename(file.path(data_dir, file_names_orig),
              file.path(data_dir, file_names_utf8))
}


#' @rdname getKSJData
#' @param x Object of class \link[sf]{sf}
#' @param quiet If \code{TRUE}, suppress messages.
#' @export
translateKSJColnames <- function(x, quiet = FALSE) {
  colnames_orig <- colnames(x)

  KSJ_code_to_name <- purrr::set_names(KSJShapeProperty$name, KSJShapeProperty$code)

  # some column names cannot be converted, so fill it with the original name
  colnames_readable_not_tidy <- dplyr::coalesce(KSJ_code_to_name[colnames_orig], colnames_orig)
  # TODO: some codes share the same name (e.g. P12_003 and P12_004)
  colnames_readable <- tibble::tidy_names(colnames_readable_not_tidy, quiet = TRUE)

  if (!quiet) {
    message("The colnames are translated:")
    message(paste(colnames_orig, colnames_readable, sep = " => ", collapse = "\n"))
  }

  colnames(x) <- colnames_readable
  x
}

# TODO: This function assumes that, if the data is CP932, it contains at least one invalid
# UTF-8 chracter. This assumption may not be true...
reencode_KSJ_data_to_native <- function(x) {
  dplyr::mutate_if(x,
                   is_non_utf8_character,
                   iconv, from = "CP932")
}


suggest_useful_links <- function(x) {
  # extract codes from x
  codes <- x %>%
    stringi::stri_extract_first_regex("[A-Z][0-9]+") %>%
    purrr::discard(is.na) %>%
    unique

  useful_links <- KSJCodeDescriptionURL %>%
    dplyr::filter(.data$code %in% codes) %>%
    dplyr::pull(.data$url) %>%
    unique

  message(sprintf("\nDetails about this data may be found at %s\n", paste(useful_links, collapse = ", ")))
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

is_file <- function(x) {
  file_info <- file.info(x)
  if (is.na(file_info$isdir)) stop(glue::glue("{x} doesn't exist!"))
  !file_info$isdir
}

# can be converted to CP932
is_non_utf8_character <- function(x) {
  is.character(x) && any(!stringi::stri_enc_isutf8(x), na.rm = TRUE)
}
