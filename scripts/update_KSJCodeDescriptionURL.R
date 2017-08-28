library(rvest)
library(dplyr, warn.conflicts = FALSE)

x <- read_html("http://nlftp.mlit.go.jp/ksj/index.html")

d <- x %>%
  html_nodes(css = "td > a") %>%
  {
    tibble::tibble(url  = html_attr(., "href"),
                   name = html_text(.))
  }
d


KSJCodeDescriptionURL <- d %>%
  filter(startsWith(url, "gml/datalist")) %>%
  mutate(code = stringi::stri_extract_first_regex(url, "[A-Z][0-9]+"),
         url  = glue::glue('http://nlftp.mlit.go.jp/ksj/{url}')) %>%
  arrange(code)

KSJCodeDescriptionURL

readr::write_csv(KSJCodeDescriptionURL, "data-raw/KSJCodeDescriptionURL.csv")
devtools::use_data(KSJCodeDescriptionURL, overwrite = TRUE)
