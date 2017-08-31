library(rvest)
library(dplyr, warn.conflicts = FALSE)
library(purrr)

# Download  -----------------------------------------------

### define functions ###

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


### datalist ###

data("KSJIdentifierDescriptionURL")
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


# extract tables --------------------------------------------------

### define functions ###

extract_tables_safely <- purrr::safely(function(x) {
  read_html(x, encoding = "CP932") %>%
    html_nodes(css = "table table") %>%
    html_table(fill = TRUE) %>%
    purrr::keep(~ any(stringr::str_detect(.$X1, "属性情報|地物情報")))
})

### process HTMLs ###

list_of_tables_wrapped <- purrr::map(datalist_destfiles, extract_tables_safely)
# check errors
datalist_destfiles[map_lgl(list_of_tables_wrapped, ~ !is.null(.$error))]

list_of_tables <- purrr::map(list_of_tables_wrapped, "result") %>%
  rlang::set_names(KSJIdentifierDescriptionURL$identifier)


# Re-split tables -----------------------------------------------------

### define functions ###

split_table_by_rleid <- function(table) {
  # split them by rle-manner IDs (c.f. https://github.com/tidyverse/dplyr/issues/1534#issuecomment-326039714)
  rleid <- cumsum(dplyr::coalesce(table$X1 != dplyr::lag(table$X1), FALSE))
  split(table, rleid)
}

resplit_tables <- function(tables) {
  tables_resplit <- tables %>%
    purrr::map(split_table_by_rleid) %>%
    purrr::flatten()

  tables_filtered <- tables_resplit %>%
    purrr::keep(~ stringr::str_detect(unique(.$X1), "属性情報"))

  # if there are no 属性情報, use 地物情報
  if (length(tables_filtered) == 0) {
    tables_filtered <- tables_resplit %>%
      purrr::keep(~ stringr::str_detect(unique(.$X1), "属性情報|地物情報"))
  }

  tables_filtered
}

### split tables ###

list_of_tables_resplit <- purrr::map(list_of_tables, resplit_tables)

# something is wron if some table is zero rows
list_of_tables_resplit %>%
  purrr::map(purrr::keep, ~ nrow(.) == 0) %>%
  purrr::keep(~ length(.) > 0) %>%
  names


# Make tables tidy ---------------------------------------------------------------------

### define functions ###

squash_tables_safely <- purrr::safely(function(tables) {
  tables %>%
    purrr::map(refill_table) %>%
    purrr::map(shrink_table)
})

# fix cells wrongly filled by rvest::html_table(fill = TRUE)
refill_table <- function(table) {
  table %>%
    dplyr::select_if(~ !all(is.na(.))) %>%
    mutate_all(funs(stringr::str_replace(., "(?<=^属性(情報|名|項目))(\\s*[（\\(].*[）\\)])$", ""))) %>%
    # 属性情報 is valid only for the first column
    mutate_at(-1, funs(dplyr::na_if(., "属性情報"))) %>%
    tidyr::fill(-1)
}

shrink_table <- function(table, debug = FALSE) {
  col_names <- table[1, ]
  colnames(table) <- col_names

  if (debug) message(glue::glue("col_names: {paste(col_names, collapse = ', ')}"))

  col_rle <- rle(col_names)
  col_names_duplicated <- col_rle$values[col_rle$lengths > 1]

  if (debug) message(glue::glue("col_names_duplicated: {col_names_duplicated}"))

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

### squash ###

result_wrapped <- purrr::map(list_of_tables_resplit, squash_tables_safely)

result <- purrr::map(result_wrapped, "result")

map(result, map, colnames)

result %>%
  map(map, colnames) %>%
  map(map, sort, na.last = TRUE) %>%
  map(discard, identical, sort(c("属性情報", "属性名", "説明", "属性の型"))) %>%
  keep(~ length(.) > 0)

