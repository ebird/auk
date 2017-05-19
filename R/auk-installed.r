#' Check for a valid AWK install
#'
#' @return A logical indicating whether awk was found or not.
#' @export
#' @examples
#' auk_installed()
auk_installed <- function() {
  awk_version <- tryCatch(
    list(result = system("awk --version", intern = TRUE, ignore.stderr = TRUE)),
    error = function(e) list(result = NULL)
  )
  !is.null(awk_version$result) && grepl("^awk", awk_version$result)
}
