.onLoad <- function(libname, pkgname) {
  # # check to ensure awk is installed
  # packageStartupMessage("Looking for a valid awk install:")
  if (system("which awk") != 0) {
    stop("rawk cannot be loaded: awk not found")
  }
  invisible()
}
