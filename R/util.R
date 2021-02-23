# Utilities

make_sure_data_is_loaded <- function(x) {
  if (!exists(x)) {
    do.call(utils::data, list(x, package = "kokudosuuchi"))
  }
}

is_installed <- function(pkg) {
  system.file(package = pkg) != ""
}

is_file <- function(x) file.exists(x) && !dir.exists(x)
is_dir  <- function(x) dir.exists(x)
