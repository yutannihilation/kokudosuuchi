#' @rdname getKSJData
#' @param x Object of class \link[sf]{sf}
#' @param quiet If \code{TRUE}, suppress messages.
#' @export
translateKSJData <- function(x, quiet = TRUE) {
  if (inherits(x, "sf")) {
    translateKSJData_one(x, quiet)
  } else {
    purrr::map(x,
               translateKSJData_one,
               quiet = quiet)

  }
}

translateKSJData_one <- function(x, quiet = TRUE) {
  # when called by :: and package is not loaded to namespace, we have to make sure the data is loaded
  make_sure_data_is_loaded("KSJMetadata_code")
  make_sure_data_is_loaded("KSJMetadata_code_year_cols")

  colnames_orig <- colnames(x)

  code_filtered <- dplyr::filter(KSJMetadata_code, .data$code %in% !! colnames_orig)

  if (nrow(code_filtered) == 0L) {
    if (!quiet) warning("No corresponding colnames are found for the codes.")
    return(x)
  }

  # try to choose the right one from the number of matched colnames
  if (any(duplicated(code_filtered$code))) {
    if (any(is.na(code_filtered$item_id)) ||
        length(unique(code_filtered$item_id)) == 1) {
      # abort if code_filtered cannot be split
      if (!quiet) warning("Cannot determine which colnames to use for  the codes")
      return(x)
    }

    code_split <- split(code_filtered, code_filtered$item_id)
    # if colnames_orig does not contain any of the codes, that set of colnames is probably wrong.
    code_with_all_colnames <- purrr::discard(code_split, ~ any(! .$code %in% colnames_orig))

    if (length(code_with_all_colnames) == 0) {
      # abort if there are no candidates
      if (!quiet) warning("Cannot determine which colnames to use for  the codes")
      return(x)
    }

    # the set of colnames that has most rows are most probable.
    index_most_probable_colnames <- which.max(
      purrr::map_int(code_with_all_colnames, nrow)
    )
    code_filtered <- code_with_all_colnames[[index_most_probable_colnames]]
  }

  KSJ_code_to_name <- purrr::set_names(code_filtered$name, code_filtered$code)

  # some column names cannot be converted, so fill it with the original name
  colnames_readable_not_tidy <- dplyr::coalesce(KSJ_code_to_name[colnames_orig], colnames_orig)
  # TODO: some codes share the same name (e.g. P12_003 and P12_004)
  colnames_readable <- tibble::tidy_names(colnames_readable_not_tidy, quiet = TRUE)

  if (!quiet) {
    message("The colnames are translated as bellow:")
    message(paste(colnames_orig, colnames_readable, sep = " => ", collapse = "\n"))
  }

  # colnames like A22_012000 can be translated into names like "foo 2000 year"
  colnames_readable_w_years <- translate_year_cols(colnames_readable)

  colnames(x) <- colnames_readable_w_years
  x
}


translate_year_cols <- function(x) {
  purrr::reduce(purrr::transpose(KSJMetadata_code_year_cols),
                ~ stringr::str_replace(.x, .y$pattern, .y$replacement),
                .init = x)
}
