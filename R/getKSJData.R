#' Get JPGIS2.1 Data
#'
#' \code{getKSJData} tries to download and load spatial data from Kokudo Suuchi service. Note that this function
#' does not use API; directly download ZIP file and load the data by \link[sf]{read_sf}.
#' \code{translateKSJColnames} translates the column names of data (e.g. W05_001) into human readable ones.
#' By default, this is automatically done in \code{getKSJData}.
#'
#' @param zip_file
#'   Either a URL, a path to a zip file, or a path to a directory which contains shape files.
#' @param try_translate_colnames
#'   If \code{TRUE}, try to use human-readable column names.
#'   See \link{KSJShapeProperty} for more information about the corresponding table.
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
#' l_translated <- translateKSJColnames(l)
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

  shp_files <- list.files(temp_data_dir, pattern = ".*\\.shp", recursive = TRUE, full.names = TRUE)

  # CP932 layer names cannot be handled on non-CP932 systems so we need to rename them
  shp_files_utf8 <- rename_shp_files_to_utf8(shp_files)

  # set names to make each layer named
  shp_files_utf8 <- rlang::set_names(shp_files_utf8,
                                     tools::file_path_sans_ext(basename(shp_files_utf8)))

  # read all data
  result <- purrr::map(shp_files_utf8,
                       sf::read_sf,
                       # All data is encoded with Shift_JIS as described here:
                       # http://nlftp.mlit.go.jp/ksj/old/old_data.html
                       options = glue::glue("ENCODING={encoding}"))

  # suggest useful links
  suggest_useful_links(basename(shp_files_utf8))

  result
}



download_KSJ_zip <- function(zip_url, cache_dir) {
  # if it doesn't esist, create it.
  if (!file.exists(cache_dir)) dir.create(cache_dir)
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


rename_shp_files_to_utf8 <- function(shp_files) {
  if (all(stringi::stri_enc_isutf8(shp_files))) return(shp_files)

  shp_files_dirname <- dirname(shp_files)
  shp_files_basename <- basename(shp_files)
  # assume the original names are cp932
  shp_files_utf8 <- file.path(shp_files_dirname,
                              iconv(shp_files_basename, from = "CP932", to = "UTF-8"))

  # nothing happens here on windows because a CP932 string without encoding and its UTF-8 version
  # marked as UTF-8 are identical for the OS. (e.g. file.rename(x, enc2utf8(x)) does nothing).
  file.rename(shp_files, shp_files_utf8)

  # return renamed names
  shp_files_utf8
}


#' @rdname getKSJData
#' @param x Object of class \link[sf]{sf}
#' @param layer_name Layer name to filter codes.
#' @param quiet If \code{TRUE}, suppress messages.
#' @export
translateKSJColnames <- function(x, layer_name = NULL, quiet = TRUE) {
  if (inherits(x, "sf")) {
    translateKSJColnames_one(x, layer_name, quiet)
  } else {
    purrr::imap(result,
                translateKSJColnames_one,
                quiet = quiet)

  }
}

translateKSJColnames_one <- function(x, layer_name = NULL, quiet = TRUE) {
  # when called by :: and package is not loaded to namespace, we have to make sure the data is loaded
  if (!exists("KSJMetadata_code")) {
    data("KSJMetadata_code", package = "kokudosuuchi")
  }

  colnames_orig <- colnames(x)

  code_filtered <- dplyr::filter(KSJMetadata_code, .data$code %in% !! colnames_orig)

  if (nrow(code_filtered) == 0L) {
    if (!quiet) {
      warning("No corresponding names are found for theese codes: ",
              paste(colnames_orig, collapse = ", "))
    }
    return(x)
  }

  # try to filter codes with the tag extracted from the layer name
  code_duplicated_indices <- duplicated(code_filtered$code) | duplicated(code_filtered$code, fromLast = TRUE)
  if (any(code_duplicated_indices) && !is.null(layer_name)) {
    # construct regex pattern from the possible tags
    tag_pattern <- paste(unique(code_filtered$tag), collapse = "|")
    # extract the tag from the layer name
    tag_from_layer_name <- stringi::stri_extract_first_regex(layer_name, tag_pattern)
    # filter by tag
    code_filtered <- dplyr::filter(code_filtered,
                                   # if the code is not duplicated, no problem
                                   # if the code is duplicated use only ones of the extracted tag
                                   code_duplicated_indices || (.data$tag %in% !! tag_from_layer_name))

    # if some codes are still ambiguous, show warnings and remove them
    code_duplicated_indices <- duplicated(code_filtered$code) | duplicated(code_filtered$code, fromLast = TRUE)
    if (any(code_duplicated_indices) && !quiet) {
      code_duplicated <- code_filtered[code_duplicated_indices, ] %>%
        group_by(.data$code) %>%
        summarise(candidates = paste0(.data$name, collapse = ", "))

      warn_msg <- sprintf("\tcode: %s (candidates: %s)\n", code_duplicated$code, code_duplicated$candidates)
      warning("Cannot determine the layer name with these codes :\n", warn_msg)

      code_filtered <- code_filtered[!code_duplicated_indices, ]
    }
  }

  KSJ_code_to_name <- purrr::set_names(code_filtered$name, code_filtered$code)

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

suggest_useful_links <- function(x) {
  # when called by :: and package is not loaded to namespace, we have to make sure the data is loaded
  if (!exists("KSJMetadata_description_url")) {
    data("KSJMetadata_description_url", package = "kokudosuuchi")
  }

  # extract codes from x
  identifiers <- x %>%
    stringi::stri_extract_first_regex(identifier_regex) %>%
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
