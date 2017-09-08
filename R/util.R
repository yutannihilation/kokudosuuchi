# Utilities

as_param <- function(x) {
  stringr::str_c(as.character(x), collapse = ",")
}
