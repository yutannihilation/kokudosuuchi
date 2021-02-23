# If the data needs special treatment, write individual logics in this file.


translate_SectionTypeCd <- function(code, variant) {
  tbl <- .codelist[[glue::glue("SectionTypeCd_{variant}")]]
  tbl$label[match(code, tbl$code)]
}

match_A03 <- function(d, id, variant, translate_colnames = TRUE, translate_codelist = TRUE) {
  idx_SectionTypeCd <- which(colnames(d) == "A03_006")
  idx_SectionCd <- which(colnames(d) == "A03_007")

  d <- match_by_name(d, id, translate_colnames = translate_colnames, translate_codelist = translate_codelist)

  if (!isTRUE(translate_codelist)) {
    return(d)
  }

  d[[idx_SectionTypeCd]] <- translate_SectionTypeCd(d[[idx_SectionTypeCd]], variant)

  d
}

replace_year <- function(d, prefix, format) {
  idx <- stringr::str_detect(colnames(d), paste0(prefix, "[12][0-9]{3}"))
  year <- stringr::str_sub(colnames(d)[idx], -4L)
  colnames(d)[idx] <- glue::glue(format)
  d
}

# A22-m has two types of colnames; by exact match and by pattern
`match_A22-m` <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  old_names <- colnames(d)

  d <- match_by_name(d, id,
                     translate_colnames = translate_colnames,
                     translate_codelist = translate_codelist,
                     skip_check = TRUE)

  if (!isTRUE(translate_colnames)) {
    return(d)
  }

  d <- replace_year(d, "A22_01", "\u6700\u6df1\u7a4d\u96ea_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_02", "\u7d2f\u8a08\u964d\u96ea\u91cf_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_03", "\u6700\u4f4e\u6c17\u6e29_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_04", "\u5e73\u5747\u98a8\u901f_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_10", "\u6b7b\u8005\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_11", "\u884c\u65b9\u4e0d\u660e\u8005\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_12", "\u91cd\u50b7\u8005\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_13", "\u8efd\u50b7\u8005\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_14", "\u4f4f\u5bb6\u5168\u58ca\u68df\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_15", "\u4f4f\u5bb6\u534a\u58ca\u68df\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_16", "\u4f4f\u5bb6\u4e00\u90e8\u7834\u640d\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_17", "\u9664\u96ea\u30dc\u30e9\u30f3\u30c6\u30a3\u30a2\u56e3\u4f53\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_18", "\u9664\u96ea\u30dc\u30e9\u30f3\u30c6\u30a3\u30a2\u767b\u9332\u4eba\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_19", "\u9664\u96ea\u30dc\u30e9\u30f3\u30c6\u30a3\u30a2\u6d3b\u52d5\u56de\u6570_{year}\u5e74\u5ea6")
  d <- replace_year(d, "A22_20", "\u9664\u96ea\u30dc\u30e9\u30f3\u30c6\u30a3\u30a2\u306e\u5ef6\u3079\u53c2\u52a0\u4eba\u6570_{year}\u5e74\u5ea6")

  assert_all_translated(colnames(d), old_names, id)

  d
}

`match_A37` <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  old_names <- colnames(d)

  d <- match_by_name(d, id,
                     translate_colnames = translate_colnames,
                     translate_codelist = translate_codelist,
                     skip_check = TRUE)

  if (!isTRUE(translate_colnames)) {
    return(d)
  }

  d <- replace_year(d, "A37_34", "\u6551\u6025\u8eca\u51fa\u52d5\u4ef6\u6570_{year}\u5e74")
  d <- replace_year(d, "A37_35", "\u6d88\u9632\u9632\u707d\u30d8\u30ea\u51fa\u52d5\u4ef6\u6570_{year}\u5e74")
  d <- replace_year(d, "A37_36", "\u5e73\u5747\u73fe\u5834\u5230\u7740\u6240\u8981\u6642\u9593_{year}\u5e74")
  d <- replace_year(d, "A37_37", "\u5e73\u5747\u75c5\u9662\u53ce\u5bb9\u6642\u9593_{year}\u5e74")

  assert_all_translated(colnames(d), old_names, id)

  d
}


match_C02 <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  # Some columns are mistakenly named as "C12_..." whereas they should be "C02_..."
  colnames(d) <- stringr::str_replace(colnames(d), "^C12_", "C02_")
  match_by_name(d, id,
                translate_colnames = translate_colnames,
                translate_codelist = translate_codelist)
}

# This function cannot handle old data
match_L01 <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  dc <- .col_info$other[.col_info$other$id == id, ]

  old_names <- colnames(d)

  d <- match_by_position(d, id, dc = dc,
                         translate_colnames = translate_colnames,
                         translate_codelist = translate_codelist,
                         skip_check = TRUE)

  if (!isTRUE(translate_colnames)) {
    return(d)
  }

  # confirm the last positionally matched column is Sentei Nenji bits
  nenji_bits <- stringr::str_detect(d[["\u9078\u5b9a\u5e74\u6b21\u30d3\u30c3\u30c8"]], "^[01]+$")
  if (!all(nenji_bits)) {
    abort("Failed to match colnames")
  }

  nendo <- as.integer(unique(d[["\u5e74\u5ea6"]]))
  if (length(nendo) != 1) {
    warn("Data seems to over multiple years, using the latest one to calculate colnames...")
    nendo <- max(nendo, na.rm = TRUE)
  }

  col_price <- paste0("\u8abf\u67fb\u4fa1\u683c_", seq(1983, nendo))
  col_move  <- paste0("\u5c5e\u6027\u79fb\u52d5_", seq(1984, nendo))

  # If translate_codelist is TRUE, compensation is needed for inserted rows
  if (!isTRUE(translate_codelist)) {
    inserted_rows <- 0
  } else {
    inserted_rows <- sum(!is.na(dc$codelist_id))
  }
  idx_col_price <- length(dc$name) + inserted_rows + seq_along(col_price)
  idx_col_move  <- max(idx_col_price) + seq_along(col_move)

  if (max(idx_col_move) != ncol(d) - 1L) {
    warn("The number of columns doesn't match with the expectation")
  }

  is_probably_move <- function(i) {
    all(nchar(d[[i]]) == 14L & stringr::str_detect(d[[i]], "^[0124]+$"))
  }

  if (any(vapply(idx_col_price, is_probably_move, logical(1L))) ||
      !all(vapply(idx_col_move, is_probably_move, logical(1L)))) {
    abort("The values of columns don't match with the expectation")
  }

  colnames(d)[idx_col_price] <- col_price
  colnames(d)[idx_col_move] <- col_move

  assert_all_translated(colnames(d), old_names, id)

  d
}

match_L02 <- match_L01

`match_L03-a` <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) d
`match_L03-b` <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) d
`match_L03-b-u` <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) d

match_N04 <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  # geometry column is not counted
  ncol <- ncol(d) - 1L

  dc_N04 <- .col_info$N04

  dc <- dc_N04[dc_N04$columns == ncol, ]

  if (nrow(dc) == 0) {
    abort("Unexpected number of columns")
  }

  match_by_name(d, id, dc = dc,
                translate_colnames = translate_colnames,
                translate_codelist = translate_codelist)
}

`match_S05-a` <- match_N04
`match_S05-b` <- match_N04
`match_P02`   <- match_N04
match_A42     <- match_N04

# P17 has ranged columns
match_P17 <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  old_names <- colnames(d)
  d <- match_by_name(d, id,
                     translate_colnames = translate_colnames,
                     translate_codelist = translate_codelist,
                     skip_check = TRUE)

  if (!isTRUE(translate_colnames)) {
    return(d)
  }

  idx <- which(stringr::str_detect(colnames(d), paste0("^", id)))

  if (length(idx) > 0) {
    offset <- nchar(id) + 2L
    num <- as.integer(stringr::str_sub(colnames(d)[idx], offset))

    if (any(diff(num) != 1)) {
      colnames_joined <- paste(colnames(d), collapse = ", ")
      msg <- glue::glue("Columns are not sequencial: {colnames_joined}")
      abort(msg)
    }

    colnames(d)[idx] <- paste0("\u7ba1\u8f44\u7bc4\u56f2", seq_along(num))
  }

  assert_all_translated(colnames(d), old_names, id)

  d
}

match_P18 <- match_P17

match_P21 <- function(d, id, variant = NULL, translate_colnames = TRUE, translate_codelist = TRUE) {
  colnames <- colnames(d)
  # wrong colname?
  idx <- stringr::str_detect(colnames, "^P21[A-Z]_00$")
  if (any(idx)) {
    # Uncomment this when moving to kokudosuuchi

    msg <- glue::glue("Found invalid colname(s): {colnames[idx]}")
    warn(msg)

    colnames(d)[idx] <- stringr::str_replace(colnames[idx], "\\d+$", sprintf("%03d", which(idx)))
  }

  match_by_name(d, id,
                translate_colnames = translate_colnames,
                translate_codelist = translate_codelist)
}
