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
  make_sure_data_is_loaded("KSJMetadata_code_correspondence_tables")

  colnames_orig <- colnames(x)

  # Get candidates for the colnames -------------------------

  code_filtered <- KSJMetadata_code %>%
    dplyr::group_by(.data$identifier, .data$item_id) %>%
    dplyr::filter(any(.data$code %in% !! colnames_orig)) %>%
    dplyr::ungroup() %>%
    # TODO: remove this workaround when yutannihilation/kokudosuuchiUtils#29 is fixed
    dplyr::distinct()

  if (nrow(code_filtered) == 0L) {
    if (!quiet) warning("No corresponding colnames are found for the codes.")
    return(x)
  }

  # try to choose the right one from the number of matched colnames
  if (any(duplicated(code_filtered$code))) {
    if (any(is.na(code_filtered$item_id)) ||
        length(unique(code_filtered$item_id)) == 1) {
      # abort if code_filtered cannot be split
      if (!quiet) warning("Cannot determine which colnames to use for the codes")
      return(x)
    }

    code_split <- split(code_filtered, code_filtered$item_id)

    # More matches and less nrows are better.
    # TODO: for some cases like L03-a, this assumption fails.
    matches <- purrr::map_int(code_split, ~ sum(.$code %in% colnames_orig))
    code_most_matches <- code_split[matches == max(matches)]

    nrows <- purrr::map_int(code_most_matches, nrow)
    code_least_nrows <- code_most_matches[nrows == min(nrows)]

    if (length(code_least_nrows) > 1) {
      # abort if there are more-than-one candidates
      if (!quiet) warning("Cannot determine which colnames to use for the codes")
      return(x)
    }

    code_filtered <- code_least_nrows[[1]]
  }

  # Translate data if there are correspondence tables -----------------------------
  cts <- code_filtered %>%
    dplyr::filter(!is.na(.data$correspondence_table)) %>%
    dplyr::mutate(matched_col = dplyr::coalesce(match(.data$code, !! colnames_orig),
                                                match(.data$name, !! colnames_orig))) %>%
    dplyr::filter(!is.na(.data$matched_col))

  if (nrow(cts) > 0) {
    x[, cts$matched_col] <- purrr::pmap(cts,
                                       function(matched_col, correspondence_table, ...) {
                                          data <- as.character(x[[matched_col]])
                                          table <- KSJMetadata_code_correspondence_tables[[correspondence_table]]
                                          table[data]
                                        })
  }

  # Translate colnames -------------------------

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
