library(rvest)
library(dplyr, warn.conflicts = FALSE)
library(purrr)

data("KSJIdentifierDescriptionURL")

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

extract_tables_html <- function(html) {
  read_html(html, encoding = "CP932") %>%
    html_nodes(css = "table table") %>%
    keep(~ stringr::str_detect(as.character(.), "属性情報|地物情報"))
}

extract_tables_html_safely <- purrr::safely(extract_tables_html)

### process HTMLs ###

datalist_destfiles <- list.files("downloaded_html", pattern = "datalist-.*", full.names = TRUE)
list_of_tables_html_wrapped <- purrr::map(datalist_destfiles, extract_tables_html_safely)
# check errors
datalist_destfiles[map_lgl(list_of_tables_html_wrapped, ~ !is.null(.$error))]

list_of_tables_html <- purrr::map(list_of_tables_html_wrapped, "result") %>%
  rlang::set_names(KSJIdentifierDescriptionURL$identifier)


# Re-split tables -----------------------------------------------------

### define functions ###

resplit_tables_html <- function(tables) {
  map(tables, resplit_one_table_html) %>%
    flatten
}

resplit_one_table_html <- function(table) {
  tr_list_raw <- html_children(table)

  # if tr or first td have bgcolor attribute, the rows bellow belongs to new group.
  has_bgcolor_tr              <- map_lgl(tr_list_raw, ~ !is.na(html_attr(., "bgcolor")))
  has_bgcolor_first_td        <- map_lgl(tr_list_raw, ~ !is.na(html_attr(html_node(., "td"), "bgcolor")))
  is_start_of_different_table <- has_bgcolor_tr | has_bgcolor_first_td

  table_id <- cumsum(is_start_of_different_table)
  # if th has bgcolor, it is a header
  has_header <- has_bgcolor_tr[is_start_of_different_table]
  # if a table has multiple rows, first td has a rowspan attribute
  expected_rows <- tr_list_raw[is_start_of_different_table] %>%
    map_chr(~ html_attr(html_node(., "td"), "rowspan"), default = "1") %>%
    as.integer()

  tr_list_split <- split(tr_list_raw, table_id) %>%
    # some rows belong to no tables; remove them
    map2(expected_rows, head) %>%
    # we don't need tables without proper headers
    keep(has_header)
}

resplit_tables_html_safely <- purrr::safely(resplit_tables_html)

### split tables ###

list_of_tables_resplit_html_wrapped <- purrr::map(list_of_tables_html, resplit_tables_html_safely)

# check errors
keep(list_of_tables_resplit_html_wrapped, ~ !is.null(.$error))
list_of_tables_resplit_html <- purrr::map(list_of_tables_resplit_html_wrapped, "result")

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

