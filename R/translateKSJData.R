#' Translate JPGIS2.1 Data
#'
#' `translateKSJData()` translates colnames and 'codelist'-type of columns to
#' human-readable labels.
#'
#' @param x
#'   A list of [sf][sf::sf] objects.
#' @param id
#'   An ID of the dataset (e.g. `A03`). This can be `NULL` if `x` is loaded
#'   by [`readKSJData()`].
#' @param variant
#'   A type of variant in case the translation cannot be determined only by `id`.
#' @param quiet
#'   If `TRUE`, suppress messages.
#' @param translate_colnames
#'   If `TRUE`, translate colnames to human-readable labels.
#' @param translate_codelist
#'   If `TRUE`, translate codes to human-readable labels.
#' @export
translateKSJData <- function(x, id = NULL, variant = NULL, quiet = TRUE,
                             translate_colnames = TRUE, translate_codelist = TRUE) {
  id <- id %||% attr(x, "id")
  if (is.null(id)) {
    abort("`id` must be supplied either as `id` argument or as an attribute of `x`")
  }

  variant <- variant %||% attr(x, "variant")

  matching_fun <- get0(paste0("match_", id), ifnotfound = NULL)

  if (is.null(matching_fun)) {
    matching_fun <- switch (.matching_types[id],
                            positional = match_by_position,
                            exact      = match_by_name
    )
  }

  if (is.null(matching_fun)) {
    abort("Not implemented")
  }

  x <- lapply(x, matching_fun,
              id = id, variant = variant,
              translate_colnames = translate_colnames,
              translate_codelist = translate_codelist)

  x
}

ok_with_no_translation <- list(
  A10 = c("OBJECTID", "Shape_Leng", "Shape_Area"),
  A11 = c("OBJECTID", "Shape_Leng", "Shape_Area"),
  A12 = c("OBJECTID", "Shape_Leng", "Shape_Area"),
  A13 = c("OBJECTID", "Shape_Leng", "Shape_Area", "ET_ID", "ET_Source"),
  A15 = c("ORIG_FID"),
  # unexpected columns...
  A19 = c("A19_010", "A19_011", "A19_012", "A19_013"),
  A19s = c("LINK"),
  A37 = c("A37_330002"),
  P20 = c("\u30ec\u30d9\u30eb", "\u5099\u8003", "\u7def\u5ea6", "\u7d4c\u5ea6", "NO"),
  P21 = c("\u691c\u67fbID"),
  P22 = c("IDO", "KEIDO", "TreeCode", "PosStat", "Origna", "ORigna"),
  W05 = c("W05_000")
)

assert_all_translated <- function(new_names, old_names, id) {
  no_translated_cols <- intersect(new_names, old_names)
  exclude_cols <- c(ok_with_no_translation[[id]], "geometry")
  no_translated_cols <- setdiff(no_translated_cols, exclude_cols)

  if (length(no_translated_cols) > 0) {
    msg <- glue::glue(
      "There are some columns yet to be translated: ",
      paste(no_translated_cols, collapse = ",")
    )
    warn(msg)
  }
}

match_by_position <- function(d, id,
                              dc = NULL, variant = NULL,
                              translate_colnames = TRUE,
                              translate_codelist = TRUE,
                              skip_check = FALSE) {
  if (is.null(dc)) {
    if (id %in% names(.col_info)) {
      dc <- .col_info[[id]]
    } else {
      dc <- .col_info$other[.col_info$other$id == id, ]
    }
  }

  readable_names <- dc$name
  codelist_id <- dc$codelist_id

  old_names <- colnames(d)

  # exlude columns that don't need to be translated
  old_names <- setdiff(old_names, c(ok_with_no_translation[[id]], "geometry"))

  ncol <- length(old_names)

  if (!isTRUE(skip_check) && length(readable_names) != ncol) {
    msg <- glue::glue(
      "The numbers of columns don't match. ",
      "expected: ", nrow(dc), ", actual: ", ncol
    )
    abort(msg)
  }

  if (!isTRUE(!translate_colnames)) {
    colnames(d)[seq_along(readable_names)] <- readable_names
  }

  if (!isTRUE(translate_codelist)) {
    return(d)
  }

  pos_codelist_id <- which(!is.na(codelist_id))
  for (i in seq_along(pos_codelist_id)) {
    pos <- pos_codelist_id[i]
    # Note: `+ i` is needed because the columns are shifted
    d <- translate_one_column(d, pos + i - 1L, codelist_id[pos])
  }

  d
}

match_by_name <- function(d, id,
                          variant = NULL, dc = NULL,
                          translate_colnames = TRUE,
                          translate_codelist = TRUE,
                          skip_check = FALSE) {
  if (is.null(dc)) {
    if (id %in% names(.col_info)) {
      dc <- .col_info[[id]]
    } else {
      dc <- .col_info$other[.col_info$other$id == id, ]
    }
  }

  old_names <- colnames(d)
  matched <- match(old_names, dc$code)

  pos_in_data <- which(!is.na(matched))
  pos_new <- matched[!is.na(matched)]


  if (!isTRUE(!translate_colnames)) {
    colnames(d)[pos_in_data] <- dc$name[pos_new]
  }

  if (!skip_check) {
    assert_all_translated(colnames(d), old_names, id)
  }

  if (!isTRUE(translate_codelist)) {
    return(d)
  }

  # Shrink the index to only those with non-NA codelist_id
  idx_codelist_exists <- which(!is.na(dc$codelist_id[pos_new]))
  pos_in_data <- pos_in_data[idx_codelist_exists]
  pos_new <- pos_new[idx_codelist_exists]

  # As new names will be inserted, the index will shift, so preserve names at this point
  colnames_codelist <- colnames(d)[pos_in_data]

  for (i in seq_along(colnames_codelist)) {
    target <- colnames_codelist[i]
    codelist_id <- dc$codelist_id[pos_new[i]]

    # current position of the column
    pos <- which(colnames(d) == target)

    d <- translate_one_column(d, pos, codelist_id)
  }

  d
}


translate_one_column <- function(d, pos, codelist_id) {
  if (length(pos) != 1) {
    abort(paste("Invalid pos:", paste(pos, collapse = ", ")))
  }

  code_orig <- code <- d[[pos]]
  target <- colnames(d)[pos]

  tbl <- .codelist[[codelist_id]]

  # if the data is integer, do matching in integer so that e.g. "01" matches 1
  if (is.numeric(code) ||
      # Note: all(NA, na.rm = TRUE) returns TRUE, so we need to eliminate the cases when all codes are NA.
      (any(!is.na(code)) && all(!stringr::str_detect(code, "\\D"), na.rm = TRUE))) {
    # TODO: detect the conversion failures
    tbl$code <- as.character(as.integer(tbl$code))

    # code is also needs to be character, otherwise codelist_translation[code]
    # will subset the data by position, not by name
    code <- as.character(as.integer(code))
  }

  # Some column (e.g. A03_007) contains comma-separated list of codes
  if (any(stringr::str_detect(code, ","), na.rm = TRUE)) {
    label <- lapply(stringr::str_split(code, ","), function(x) {
      x <- x[!is.na(x) & x != ""]

      matched_code <- match(x, tbl$code)
      mismatched_code <- unique(x[is.na(matched_code) & !is.na(x)])
      if (length(mismatched_code) > 0) {
        mismatched_code <- paste(mismatched_code, collapse = ", ")
        msg <- glue::glue("Failed to translate these codes in {target}: {mismatched_code}")
        warn(msg)
      }

      tbl$label[matched_code]
    })
  } else {
    matched_code <- match(code, tbl$code)

    mismatched_code <- unique(code_orig[is.na(matched_code) & !is.na(code_orig)])
    if (length(mismatched_code) > 0) {
      mismatched_code <- paste(mismatched_code, collapse = ", ")
      msg <- glue::glue("Failed to translate these codes in {target}: {mismatched_code}")
      warn(msg)
    }

    label <- tbl$label[matched_code]
  }

  # overwrite the target column with human-readable labels
  d[[pos]] <- label
  # append the original codes right after the original position
  nm <- sym(glue::glue("{target}_code"))
  tibble::add_column(d, "{{ nm }}" := code_orig, .after = pos)
}
