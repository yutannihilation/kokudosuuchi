#' Read JPGIS2.1 Data
#'
#' `readKSJData()` is an utility to read data downloaded from 'Kokudo Suuchi' service.
#'
#' @param x
#'   A path to a ZIP file or to a directory that contains the extracted files.
#' @param encoding
#'   Encoding of the data.
#'
#' @examples
#' \dontrun{
#' # Download a ZIP file from kokudosuuchi website
#' zip_file <- tempfile(fileext = ".zip")
#' url <- "https://nlftp.mlit.go.jp/ksj/gml/data/W07/W07-09/W07-09_3641-jgd_GML.zip"
#' download.file(url, zip_file)
#'
#' # Load all data as sf objects
#' d <- readKSJData(zip_file)
#'
#' # Translate colnames and 'codelist' type columns
#' translateKSJData(d)
#' }
#'
#' @export
readKSJData <- function(x, encoding = "CP932") {
  if (!is_scalar_character(x)) {
    abort("`zip_file` must be length one of character vector")
  }

  if (!file.exists(x)) {
    abort(glue::glue("{x} doesn't exist"))
  }

  id <- tools::file_path_sans_ext(basename(x))

  # If x is a ZIP file, extract it, otherwise raise an error
  if (is_file(x)) {
    if (!endsWith(x, ".zip")) {
      abort(glue::glue("{x} must be a path to a ZIP file or to a directory."))
    }

    exdir <- tempfile()
    on.exit(unlink(exdir, recursive = TRUE))
    utils::unzip(x, exdir = exdir)
    rename_to_utf8_recursively(exdir)
    x <- exdir
  }

  shp_files <- list.files(x, pattern = ".*\\.shp$", recursive = TRUE, full.names = TRUE)

  # set names to make each layer named
  shp_files <- set_names(
    shp_files,
    tools::file_path_sans_ext(basename(shp_files))
  )

  # read all data
  res <- lapply(shp_files,
                sf::read_sf,
                # All data is encoded with Shift_JIS as described here:
                # http://nlftp.mlit.go.jp/ksj/old/old_data.html
                options = glue::glue("ENCODING={encoding}")
  )

  id_short <- extract_KSJ_id(id)

  # If ZIP file is renamed to another one, try to guess from XML file
  if (is.na(id_short)) {
    meta_xml_files <- list.files(x, pattern = "KS-META.*\\.xml$", recursive = TRUE)
    id_short <- unique(extract_KSJ_id(meta_xml_files))
    if (is.na(id_short) || length(id_short) != 1) {
      # TODO
      abort("Cannot determine ID")
    }
  }

  attr(res, "id") <- id_short

  if (identical(id_short, "A03")) {
    attr(res, "variant") <- tolower(stringr::str_extract(id, "SYUTO|CHUBU|KINKI"))
  }

  res
}

rename_to_utf8_recursively <- function(path, max_depth = 10L) {
  if (max_depth <= 0) {
    rlang::abort("Reached to max depth")
  }

  path <- normalizePath(path)

  # Convert only the child path, because parent paths might be
  # already converted to UTF-8
  orig_names <- list.files(path)
  if (length(orig_names) == 0) {
    return()
  }

  utf8_names <- iconv(orig_names, from = "CP932", to = "UTF-8")

  # file.path() doesn't work for this...
  orig_names <- paste(path, orig_names, sep = .Platform$file.sep)
  utf8_names <- paste(path, utf8_names, sep = .Platform$file.sep)

  # Rename
  for (i in seq_along(orig_names)) {
    src <- orig_names[i]
    dst <- utf8_names[i]
    if (identical(src, dst)) {
      next
    }

    file.rename(src, dst)
    if (!file.exists(dst)) {
      msg <- glue::glue("Failed to rename to {dst}")
      abort(msg)
    }
  }

  # If it's a directory, apply recursively
  utf8_names <- utf8_names[file.info(utf8_names)$isdir]
  if (length(utf8_names) > 0) {
    for (nm in utf8_names) {
      rename_to_utf8_recursively(nm, max_depth = max_depth - 1L)
    }
  }
}

extract_KSJ_id <- function(x) {
  # A19s-a is a variant of A19s
  if (stringr::str_detect(x, "A19s-a")) {
    return("A19s")
  }

  # filename of A18s-a is "A18s_a"
  if (stringr::str_detect(x, "A18s_a")) {
    return("A18s-a")
  }

  x <- stringr::str_extract(x, "^(KS-META-)?[A-Z][0-9]{2}[a-z]?[0-9]?(-[a-z])?(-[cu])?")
  x <- stringr::str_remove(x, "^KS-META-")

  x
}
