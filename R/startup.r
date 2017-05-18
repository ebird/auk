.onLoad <- function(libname, pkgname) {
  # # check to ensure awk is installed
  # startup_message("Looking for a valid awk install:")
  # if (system("which awk") != 0) {
  #   stop("rawk cannot be loaded: awk not found")
  # }
  # invisible()
}
# get around cran checks
startup_message <- packageStartupMessage
