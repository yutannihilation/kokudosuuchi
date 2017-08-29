library(rvest)

# TRUE: download successfully, FALSE: file already exists, NULL: error
download_safely <- purrr::safely(function(url) {
  destfile <- file.path("downloaded_html",
                        paste0("datalist-", basename(url)))

  if (file.exists(destfile)) return(FALSE)

  curl::curl_download(url, destfile)
  Sys.sleep(1)
  return(TRUE)
})

result <- purrr::map(KSJIdentifierDescriptionURL$url,
                     download_safely)

if (any(purrr::map_lgl(result, ~ !is.null(.$error)))) {
  stop("some error happened")
}

htmls <- file.path("downloaded_html", paste0("datalist-", basename(KSJIdentifierDescriptionURL$url)))

x <- read_html(htmls[1])
x %>%
  html_nodes(css = "a") %>%
  html_attr("href") %>%
  stringr::str_subset("codelist")
