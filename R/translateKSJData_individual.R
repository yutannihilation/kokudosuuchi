# If the data needs special treatment, write individual logics in this file.

match_A03 <- function(d, id, variant, translate_codelist = TRUE) {
  idx_SectionTypeCd <- which(colnames(d) == "A03_006")
  idx_SectionCd <- which(colnames(d) == "A03_007")

  d <- match_by_name(d, id, translate_codelist = translate_codelist)

  if (!isTRUE(translate_codelist)) {
    return(d)
  }

  d[[idx_SectionTypeCd]] <- translate_SectionTypeCd(d[[idx_SectionTypeCd]], variant)

  d
}

translate_SectionTypeCd <- function(code, variant) {
  tbl <- .codelist[[glue::glue("SectionTypeCd_{variant}")]]
  codelist_translation <- setNames(tbl$label, tbl$code)
  codelist_translation[code]
}

# A22-m has two types of colnames; by exact match and by pattern
`match_A22-m` <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  old_names <- colnames(d)

  d <- match_by_name(d, id, skip_check = TRUE)

  replace_year <- function(d, prefix, format) {
    idx <- stringr::str_detect(colnames(d), paste0(prefix, "[12][0-9]{3}"))
    year <- stringr::str_sub(colnames(d)[idx], -4L)
    colnames(d)[idx] <- glue::glue(format)
    d
  }

  d <- replace_year(d, "A22_01", "最深積雪_{year}年度")
  d <- replace_year(d, "A22_02", "累計降雪量_{year}年度")
  d <- replace_year(d, "A22_03", "最低気温_{year}年度")
  d <- replace_year(d, "A22_04", "平均風速_{year}年度")
  d <- replace_year(d, "A22_10", "死者数_{year}年度")
  d <- replace_year(d, "A22_11", "行方不明者数_{year}年度")
  d <- replace_year(d, "A22_12", "重傷者数_{year}年度")
  d <- replace_year(d, "A22_13", "軽傷者数_{year}年度")
  d <- replace_year(d, "A22_14", "住家全壊棟数_{year}年度")
  d <- replace_year(d, "A22_15", "住家半壊棟数_{year}年度")
  d <- replace_year(d, "A22_16", "住家一部破損数_{year}年度")
  d <- replace_year(d, "A22_17", "除雪ボランティア団体数_{year}年度")
  d <- replace_year(d, "A22_18", "除雪ボランティア登録人数_{year}年度")
  d <- replace_year(d, "A22_19", "除雪ボランティア活動回数_{year}年度")
  d <- replace_year(d, "A22_20", "除雪ボランティアの延べ参加人数_{year}年度")

  assert_all_translated(colnames(d), old_names, id)

  d
}

`match_A37` <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  old_names <- colnames(d)

  d <- match_by_name(d, id, skip_check = TRUE)

  replace_year <- function(d, prefix, format) {
    idx <- stringr::str_detect(colnames(d), paste0(prefix, "[12][0-9]{3}"))
    year <- stringr::str_sub(colnames(d)[idx], -4L)
    colnames(d)[idx] <- glue::glue(format)
    d
  }

  d <- replace_year(d, "A37_34", "救急車出動件数_{year}年")
  d <- replace_year(d, "A37_35", "消防防災ヘリ出動件数_{year}年")
  d <- replace_year(d, "A37_36", "平均現場到着所要時間_{year}年")
  d <- replace_year(d, "A37_37", "平均病院収容時間_{year}年")

  assert_all_translated(colnames(d), old_names, id)

  d
}


match_C02 <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  # C02_となるべきところがC12_となっているコードが紛れている？
  colnames(d) <- stringr::str_replace(colnames(d), "^C12_", "C02_")
  match_by_name(d, id)
}

# L01は年度によってカラムが異なる。基本的には最新版に前年までのデータも含まれるはずなので最新版だけ対応でよさそう...？
match_L01 <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  dc <- d_col_info[d_col_info$id == id, ]

  old_names <- colnames(d)

  d <- match_by_position(d, id, dc = dc, translate_codelist = translate_codelist, skip_check = TRUE)

  # confirm the last positionally matched column is 選定年次ビット
  nenji_bits <- stringr::str_detect(d[["選定年次ビット"]], "^[01]+$")
  if (!all(nenji_bits)) {
    rlang::abort("Failed to match colnames")
  }

  nendo <- as.integer(unique(d[["年度"]]))
  if (length(nendo) != 1) {
    rlang::warn("Data seems to over multiple years, using the latest one to calculate colnames...")
    nendo <- max(nendo, na.rm = TRUE)
  }

  col_price <- paste0("調査価格_", seq(1983, nendo))
  col_move  <- paste0("属性移動_", seq(1984, nendo))

  # compensation for inserted rows
  inserted_rows <- sum(!is.na(dc$codelist_id))
  idx_col_price <- length(dc$name) + inserted_rows + seq_along(col_price)
  idx_col_move  <- max(idx_col_price) + seq_along(col_move)

  if (max(idx_col_move) != ncol(d) - 1L) {
    rlang::abort("The number of columns doesn't match with the expectation")
  }

  is_probably_move <- function(i) {
    all(nchar(d[[i]]) == 14L & stringr::str_detect(d[[i]], "^[0124]+$"))
  }

  if (any(vapply(idx_col_price, is_probably_move, logical(1L))) ||
      !all(vapply(idx_col_move, is_probably_move, logical(1L)))) {
    rlang::abort("The values of columns don't match with the expectation")
  }

  colnames(d)[idx_col_price] <- col_price
  colnames(d)[idx_col_move] <- col_move

  assert_all_translated(colnames(d), old_names, id)

  d
}

match_L02 <- match_L01

`match_L03-a` <- function(d, id, variant = NULL, translate_codelist = TRUE) d
`match_L03-b` <- function(d, id, variant = NULL, translate_codelist = TRUE) d
`match_L03-b-u` <- function(d, id, variant = NULL, translate_codelist = TRUE) d

match_N04 <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  # geometry は抜く
  ncol <- ncol(d) - 1L

  dc_N04 <- .col_info$N04

  dc <- dc_N04[dc_N04$columns == ncol, ]

  if (nrow(dc) == 0) {
    rlang::abort("Unexpected number of columns")
  }

  match_by_name(d, id, dc = dc)
}

`match_S05-a` <- match_N04
`match_S05-b` <- match_N04
`match_P02`   <- match_N04
match_A42     <- match_N04

# exact matchに加えて、ある範囲以上のカラムには「管轄範囲1」、「管轄範囲2」...というルールで名前がついていく
match_P17 <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  old_names <- colnames(d)
  d <- match_by_name(d, id, skip_check = TRUE)

  idx <- which(stringr::str_detect(colnames(d), paste0("^", id)))

  if (length(idx) > 0) {
    offset <- nchar(id) + 2L
    num <- as.integer(stringr::str_sub(colnames(d)[idx], offset))

    if (any(diff(num) != 1)) {
      colnames_joined <- paste(colnames(d), collapse = ", ")
      msg <- glue::glue("Columns are not sequencial: {colnames_joined}")
      rlang::abort(msg)
    }

    colnames(d)[idx] <- paste0("管轄範囲", seq_along(num))
  }

  assert_all_translated(colnames(d), old_names, id)

  d
}

match_P18 <- match_P17

match_P21 <- function(d, id, variant = NULL, translate_codelist = TRUE) {
  colnames <- colnames(d)
  # wrong colname?
  idx <- stringr::str_detect(colnames, "^P21[A-Z]_00$")
  if (any(idx)) {
    # Uncomment this when moving to kokudosuuchi

    # msg <- glue::glue("Found invalid colname(s): {colnames[idx]}")
    # rlang::warn(msg)

    colnames(d)[idx] <- stringr::str_replace(colnames[idx], "\\d+$", sprintf("%03d", which(idx)))
  }

  match_by_name(d, id)
}
