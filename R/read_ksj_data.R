#' Read JPGIS2.1 Data
#'
#' @param zip_file
#'   A path to ZIP file downloaded from Kokudo Suuchi service.
#' @param cache_dir
#'   Path to a directory for caching zip files.
#' @param encoding
#'   Encoding of the data.
#'
#' @export
read_ksj_data <- function(zip_file, cache_dir = NULL, encoding = "CP932") {
  if (!is_scalar_character(zip_file)) {
    stop("zip_file must be length one of character vector")
  }

  if (!file.exists(zip_file)) {
    stop(glue::glue("{zip_file} doesn't exist"))
  }

  id <- tools::file_path_sans_ext(basename(zip_file))

  cache <- file.path(cache_dir, id)

  if (file.exists(cache)) {
    if (!dir.exists(cache)) {
      rlang::abort(cache, " is a file")
    }
  } else {
    dir.create(cache)
    unzip(zip_file, exdir = cache)
    rename_to_utf8_recursively(cache)
  }

  shp_files <- list.files(cache, pattern = ".*\\.shp$", recursive = TRUE, full.names = TRUE)

  # set names to make each layer named
  shp_files <- rlang::set_names(
    shp_files,
    tools::file_path_sans_ext(basename(shp_files))
  )

  # read all data
  res <- purrr::map(shp_files,
                    sf::read_sf,
                    # All data is encoded with Shift_JIS as described here:
                    # http://nlftp.mlit.go.jp/ksj/old/old_data.html
                    options = glue::glue("ENCODING={encoding}")
  )

  id_short <- stringr::str_extract(id, "^[A-Z][0-9]{2}[a-z]?[0-9]?(-[a-z])?(-[cu])?")
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
  purrr::walk2(orig_names, utf8_names, function(src, dst) {
    if (identical(src, dst)) {
      return()
    }

    msg <- glue::glue("Renaming {src} to {dst}")
    rlang::inform(msg)

    file.rename(src, dst)
    if (!file.exists(dst)) {
      msg <- glue::glue("Failed to rename to {dst}")
      rlang::abort(msg)
    }
  })

  # If it's a directory, apply recursively
  utf8_names <- utf8_names[file.info(utf8_names)$isdir]
  if (length(utf8_names) > 0) {
    purrr::walk(utf8_names, rename_to_utf8_recursively, max_depth = max_depth - 1L)
  }
}
