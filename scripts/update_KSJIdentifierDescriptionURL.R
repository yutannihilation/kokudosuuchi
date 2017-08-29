library(rvest)
library(dplyr, warn.conflicts = FALSE)

page <- read_html("http://nlftp.mlit.go.jp/ksj/index.html")

a_nodes <- page %>%
  html_nodes(css = "td > a")

d <- tibble::tibble(url  = html_attr(a_nodes, "href"),
                    name = html_text(a_nodes))
d

KSJIdentifierDescriptionURL <- d %>%
  mutate(identifier = stringi::stri_extract_first_regex(url, "(?<=KsjTmplt-).*?(?=(-v\\d+_\\d+)?\\.html)"),
         url  = glue::glue('http://nlftp.mlit.go.jp/ksj/{url}')) %>%
  filter(!is.na(identifier)) %>%
  arrange(identifier)

glimpse(KSJIdentifierDescriptionURL)

readr::write_csv(KSJIdentifierDescriptionURL, "data-raw/KSJCodeDescriptionURL.csv")
devtools::use_data(KSJIdentifierDescriptionURL, overwrite = TRUE)

# copy this result as identifier_regex in R/data.R
paste(KSJIdentifierDescriptionURL$identifier, collapse = "|")
