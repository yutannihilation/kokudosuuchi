.onAttach <- function(...) {
  packageStartupMessage(paste(strwrap(KSJcredit), collapse = "\n"))
}
