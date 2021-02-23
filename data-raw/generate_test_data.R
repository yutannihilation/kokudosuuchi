zip <- list.files("../kokudosuuchi-metadata/data-raw/zip", pattern = "\\.zip$", full.names = TRUE)

d <- readKSJData(zip[4])

head(d[[10]])
translateKSJData(d)
