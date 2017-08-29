library(rvest)
library(dplyr, warn.conflicts = FALSE)

page <- read_html("http://nlftp.mlit.go.jp/ksj/index.html")

a_nodes <- page %>%
  html_nodes(css = "td > a")

d <- tibble::tibble(url  = html_attr(a_nodes, "href"),
                    name = html_text(a_nodes))
d

KSJCodeDescriptionURL <- d %>%
  mutate(code = stringi::stri_extract_first_regex(url, "(?<=KsjTmplt-).*?(?=(-v\\d+_\\d+)?\\.html)"),
         url  = glue::glue('http://nlftp.mlit.go.jp/ksj/{url}')) %>%
  filter(!is.na(code)) %>%
  arrange(code)

glimpse(KSJCodeDescriptionURL)

readr::write_csv(KSJCodeDescriptionURL, "data-raw/KSJCodeDescriptionURL.csv")
devtools::use_data(KSJCodeDescriptionURL, overwrite = TRUE)

# copy this result as code_regex in R/data.R
paste(KSJCodeDescriptionURL$code, collapse = "|")
