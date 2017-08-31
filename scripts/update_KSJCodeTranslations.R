library(rvest)
library(dplyr, warn.conflicts = FALSE)
library(purrr)

# Functions -----------------------------------------------

# TRUE: download successfully, FALSE: file already exists, NULL: error
download_safely <- purrr::safely(function(url, destfile) {
  if (file.exists(destfile)) return(FALSE)

  curl::curl_download(url, destfile)
  Sys.sleep(1)
  return(TRUE)
})

list_codelist_urls <- function(x) {
  read_html(x, encoding = "CP932") %>%
    html_nodes(css = "a") %>%
    html_attr("href") %>%
    stringr::str_subset("codelist")
}

# Download all files ---------------------------------------

### datalist ###

datalist_urls <- KSJIdentifierDescriptionURL$url
datalist_destfiles <- file.path("downloaded_html", paste0("datalist-", basename(datalist_urls)))

result <- purrr::map2(datalist_urls,
                      datalist_destfiles,
                      download_safely)

if (any(purrr::map_lgl(result, ~ !is.null(.$error)))) {
  stop("some error happened")
}

### codelist ###

codelist_urls <- purrr::map(datalist_destfiles, list_codelist_urls) %>%
  purrr::flatten_chr() %>%
  unique %>%
  sort

codelist_destfiles <- file.path("downloaded_html", paste0("codelist-", basename(codelist_urls)))

result <- purrr::map2(codelist_urls,
                      codelist_destfiles,
                      download_safely)

if (any(purrr::map_lgl(result, ~ !is.null(.$error)))) {
  stop("some error happened")
}


# data wrangling --------------------------------------------------

extract_table <- purrr::safely(function(x) {
  html <- read_html(x, encoding = "CP932")
  tables <- html %>%
    html_nodes(css = "table table") %>%
    html_table(fill = TRUE) %>%
    purrr::keep(~ any(stringr::str_detect(.$X1, "属性情報|地物情報")))

  bind_rows(tables) %>%
    dplyr::filter(stringr::str_detect(.data$X1, "属性情報|地物情報"))
})

split_table <- function(table) {
  table_refilled <- table %>%
    # remove if all cells are NA
    dplyr::select_if(~ !all(is.na(.))) %>%
    refill_table

  # split them by rle-manner IDs (c.f. https://github.com/tidyverse/dplyr/issues/1534#issuecomment-326039714)
  rleid <- cumsum(dplyr::coalesce(table_refilled$X1 != dplyr::lag(table_refilled$X1), FALSE))
  table_chunks <- split(table_refilled, rleid) %>%
    keep(~ stringr::str_detect(unique(.$X1), "属性情報"))

  # if there are no 属性情報, use 地物情報
  if (length(table_chunks) == 0) {
    table_chunks <- split(table_refilled, table$X1) %>%
      keep(stringr::str_detect(names(.), "属性情報|地物情報"))
  }

  purrr::map(table_chunks, coalesce_duplicated_columns)
}

# fix cells wrongly filled by rvest::html_table(fill = TRUE)
refill_table <- function(table) {
  table %>%
    mutate_all(funs(stringr::str_replace(., "(?<=^属性(情報|名|項目))(\\s*[（\\(].*[）\\)])$", ""))) %>%
    # 属性情報 is valid only for the first column
    mutate_at(-1, funs(dplyr::na_if(., "属性情報"))) %>%
    tidyr::fill(-1)
}

coalesce_duplicated_columns <- function(table) {
  col_names <- table[1, ]
  colnames(table) <- col_names

  message(glue::glue("col_names: {paste(col_names, collapse = ', ')}"))

  col_rle <- rle(col_names)
  col_names_duplicated <- col_rle$values[col_rle$lengths > 1]

  message(glue::glue("col_names_duplicated: {col_names_duplicated}"))

  for (cn in col_names_duplicated) {
    # the length of colnames may be changed as the table shrinks
    col_names <- table[1, ]
    print(col_names)

    coalesced <- purrr::reduce(table[, col_names == cn, drop = FALSE],
                               function(x, y) {
                                 y[x == y] <- NA_character_
                                 joined <- stringr::str_c(x, y, sep = "_")
                                 dplyr::coalesce(joined, x)
                               })
    table[, col_names == cn] <- NULL
    table[, cn] <- coalesced
  }

  table[-1, ]
}

result_wrapped <- purrr::map(datalist_destfiles, extract_table)
# check errors
datalist_destfiles[map_lgl(result_wrapped, ~ !is.null(.$error))]

result <- purrr::map(result_wrapped, "result") %>%
  rlang::set_names(KSJIdentifierDescriptionURL$identifier)

result %>%
  purrr::map(split_table) %>%
  purrr::map(purrr::keep, ~ length(.) > 4) %>%
  purrr::keep(~ length(.) > 0) %>%
  names

d <- map_dfr(result, "result", .id = "identifier")

d %>%
  filter(!is.na(.data$X5)) %>%
  filter_at(vars(X5:X7), any_vars(stringr::str_detect(., "コードリスト")))
View(.Last.value)


result %>%
  map("result") %>%
  rlang::set_names(KSJIdentifierDescriptionURL$identifier) %>%
  map(split_table) %>%
  # discard the identifier which has at least one 属性情報
  discard(~ any(stringr::str_detect(names(.), "属性情報"))) %>%
  map(map, colnames)
