# Utilities

as_param <- function(x) {
  stringr::str_c(as.character(x), collapse = ",")
}

make_sure_data_is_loaded <- function(x) {
  if (!exists(x)) {
    do.call(utils::data, list(x, package = "kokudosuuchi"))
  }
}
