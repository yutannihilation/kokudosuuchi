# Utilities

as_param <- function(x) {
  stringi::stri_c(as.character(x), collapse = ",")
}

make_sure_data_is_loaded <- function(x) {
  if (!exists(x)) {
    do.call(data, list(x, package = "kokudosuuchi"))
  }
}

is_duplicated <- function(x) {
  duplicated(x) | duplicated(x, fromLast = TRUE)
}
