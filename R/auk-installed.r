#' Check for a valid AWK install
#'
#' @return A logical indicating whether awk was found or not.
#' @export
#' @examples
#' auk_installed()
auk_installed <- function() {
  message("Checking for valid AWK install...")
  (system("which awk") == 0)
}
