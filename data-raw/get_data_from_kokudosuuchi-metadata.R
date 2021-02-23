data_dir <- "../kokudosuuchi-metadata/data"

col_types <- readr::cols(
  columns = readr::col_integer(),
  .default = readr::col_character()
)


# matching_types ----------------------------------------------------------

d_matching_types <- readr::read_csv(
  file.path(data_dir, "matching_types.csv"),
  col_types = col_types
)

.matching_types <- d_matching_types$matching_type
names(.matching_types) <- d_matching_types$id


# col_info ----------------------------------------------------------

col_info_csvs <- list.files(data_dir, pattern = "^[A-Z].*\\.csv$", full.names = TRUE)
names(col_info_csvs) <- tools::file_path_sans_ext(basename(col_info_csvs))

.col_info <- purrr::map(
  col_info_csvs,
  readr::read_csv,
  col_types = col_types
)

.col_info[["other"]] <- readr::read_csv(file.path(data_dir, "joined.csv"),
                                        col_types = col_types)


# codelist ----------------------------------------------------------------

codelist_csvs <- list.files(file.path(data_dir, "codelist"), pattern = "\\.csv$", full.names = TRUE)
names(codelist_csvs) <- tools::file_path_sans_ext(basename(codelist_csvs))

.codelist <- purrr::map(
  codelist_csvs,
  readr::read_csv,
  col_types = col_types
)

usethis::use_data(
  .matching_types,
  .col_info,
  .codelist,
  internal = TRUE,
  overwrite = TRUE
)
