library(readxl)

# Download by browser; I don't know why download.file won't work...
xlsfile <- tempfile(fileext = ".xls")
curl::curl_download("http://nlftp.mlit.go.jp/ksj/gml/shape_property_table.xls", destfile = xlsfile)
sheets <- excel_sheets(xlsfile)
KSJShapeProperty <- purrr::map_df(sheets, ~ read_excel(xlsfile, sheet = ., skip = 4))

colnames(KSJShapeProperty) <- c("category", "item", "tag", "code", "name")

# I don't know why conterminated with NA...
KSJShapeProperty <- dplyr::filter(KSJShapeProperty, !is.na(code))

# Work around for merged cells
KSJShapeProperty <- tidyr::fill(KSJShapeProperty, category, item, tag)

# verify
library(dplyr)
KSJShapeProperty %>%
  mutate(category = stringr::str_replace_all(category, "-.*", "")) %>%
  mutate(category = stringr::str_replace_all(category, stringr::regex("\n.*", multiline = TRUE), "")) %>%
  filter(!stringr::str_detect(code, category))

readr::write_csv(KSJShapeProperty, system.file("data-raw/KSJShapeProperty.csv"))
devtools::use_data(KSJShapeProperty, overwrite = TRUE)
