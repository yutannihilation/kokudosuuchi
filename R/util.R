# Utilities

as_param <- function(x) {
  stringi::stri_c(as.character(x), collapse = ",")
}
