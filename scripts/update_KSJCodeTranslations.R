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
  has_bgcolor_tr  <- map_lgl(tr_list_raw, ~ !is.na(html_attr(., "bgcolor")))

  has_bgcolor_tds <- tr_list_raw %>%
    map(html_nodes, "td") %>%
    map(map_chr, html_attr, "bgcolor") %>%
    map(~ !is.na(.))
  has_bgcolor_first_td <- map_lgl(has_bgcolor_tds, first)
  has_bgcolor_all_td   <- map_lgl(has_bgcolor_tds, all)

  is_start_of_different_table <- has_bgcolor_tr | has_bgcolor_first_td

  table_id <- cumsum(is_start_of_different_table)
  # if all td has bgcolor, it is a header
  has_header <- (has_bgcolor_tr | has_bgcolor_all_td)[is_start_of_different_table]
  # if a table has multiple rows, first td has a rowspan attribute
  expected_rows <- tr_list_raw[is_start_of_different_table] %>%
    map_chr(~ html_attr(html_node(., "td"), "rowspan", default = "1")) %>%
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

extract_data_from_row <- function(row_node) {
  # lazily assume all child nodes are td
  cells <- html_children(row_node)
  col_count <- length(cells)

  col_order <- seq_len(col_count)
  colspan   <- as.integer(map_chr(cells, html_attr, "colspan", default = "1"))
  col_index <- cumsum(c(1L, colspan))[col_order]

  rowspan   <- as.integer(map_chr(cells, html_attr, "rowspan", default = "1"))

  text <- map_chr(cells, html_text)
  link <- map(cells, html_node, css = "a") %>%
    map(html_attr, "href") %>%
    # cell can contain more than 1 links
    map_chr(stringr::str_c, collapse = ", ")

  tibble::tibble(col_index,
                 col_order,
                 colspan,
                 rowspan,
                 text,
                 link)
}

get_colindex_from_colspan <- function(colspans) {
  cumsum(c(1L, colspans))[seq_along(colspans)]
}

construct_tables <- function(tables) {
  map(tables, construct_one_table)
}

construct_one_table <- function(tr_list) {
  header <- tr_list[1]
  content <- tr_list[-1]

  ### extract header ###

  # xml_node has reference semantics, so we don't need to reassign the modified object
  try_trim_first_td(header)

  col_names <- map_chr(html_children(header), html_text) %>%
    stringr::str_replace("(?<=^属性(情報|名|項目))(\\s*[（\\(].*[）\\)])$", "") %>%
    recode("属性項目"   = "属性名",
           "地物名"     = "属性名",
           "関連役割名" = "属性名",
           "形状"       = "属性の型")

  col_widths <- get_spans(header, direction = "col")

  ### extract content ###

  table_data_raw <- map_dfr(content, extract_data_from_row, .id = "row_index")
  table_data <- table_data_raw %>%
    mutate(row_index = as.integer(row_index),
           text = dplyr::na_if(text, "&nbsp"))

  num_col <- sum(col_widths)
  num_row <- length(content)

  # debug:
  # result <- matrix(NA_character_, ncol = num_col,  nrow = num_row)
  # result[cbind(table_data$row_index, table_data$col_index)] <- table_data$text
  # View(result)

  # horizontally-long cells are already refrected in col_index
  vertically_long_cells_index <- which(table_data$rowspan > 1)
  table_data_adjusted <- table_data

  for (idx in vertically_long_cells_index) {
    col_index_top      <- table_data_adjusted$col_index[idx]
    row_index_top      <- table_data_adjusted$row_index[idx] + 1L
    row_index_bottom   <- table_data_adjusted$row_index[idx] + table_data_adjusted$rowspan[idx] - 1L

    table_data_adjusted <- mutate(
      table_data_adjusted,
      col_index = if_else(
        col_index >= col_index_top &
          between(row_index, row_index_top, row_index_bottom),
        col_index + table_data_adjusted$colspan[idx],
        col_index
      )
    )
  }

  result <- matrix(NA_character_, ncol = num_col,  nrow = num_row)
  result[cbind(table_data_adjusted$row_index, table_data_adjusted$col_index)] <- table_data_adjusted$text

  ### fill tables ###

  for (idx in vertically_long_cells_index) {
    col_idx <- table_data_adjusted$col_index[idx]
    row_idx <- table_data_adjusted$row_index[idx]
    colspan <- table_data_adjusted$colspan[idx]
    rowspan <- table_data_adjusted$rowspan[idx]
    cell_text <- table_data_adjusted$text[idx]

    # if the cell is NA use the text in the cell above
    if (is.na(cell_text)) {
      if (row_idx == 1L) stop("something is wrong")
      cell_text <- result[row_idx - 1, col_idx]
    }
    result[row_idx:(row_idx + rowspan - 1L), col_idx:(col_idx + colspan - 1L)] <- cell_text
  }


  ### coalesce cells ###

  result_list <- list()
  col_index_groups <- c(cumsum(c(1L, col_widths))) %>% { map2(lag(.)[-1], .[-1] - 1L, seq) }

  for (idx in seq_along(col_names)) {
    col_name <- col_names[idx]
    col_index_group <- col_index_groups[[idx]]

    if (length(col_index_group) == 1L) {
      result_list[[col_name]] <- result[, col_index_group]
      next
    }

    result_list[[col_name]] <- purrr::reduce(as_tibble(result[, col_index_group]),
                                             function(x, y) {
                                               y[x == y] <- NA_character_
                                               joined <- stringr::str_c(x, y, sep = "_")
                                               dplyr::coalesce(joined, x)
                                             })
  }
  as_tibble(result_list)
}

# first td can be removed as it has no useful infomation
try_trim_first_td <- function(tr) {
  first_td <- html_node(tr, "td")

  # in almost all cases, we can remove first td. One exception is this:
  #    http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-P33.html
  if (stringr::str_detect(html_text(first_td), "属性情報|地物情報") &&
      !is.na(html_attr(first_td, "rowspan"))) {
    xml_remove(first_td)
  }
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

