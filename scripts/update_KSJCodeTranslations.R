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

purrr::map(KSJIdentifierDescriptionURL$url[1:3],
           download_safely)

x <- read_html("http://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-W07.html")
x %>%
  html_nodes(css = "a") %>%
  html_attr("href") %>%
  stringr::str_subset("codelist")
