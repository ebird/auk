#' Read an EBD file
#'
#' A thin wrapper for [read.delim] that reads EBD files and cleans on the
#' variable names.
#'
#' @param file character; EBD file to read.
#'
#' @return A `data.frame`.
#' @export
#' @examples
#' ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   auk_read()
auk_read <- function(file) {
  out <- read.delim(file, quote = "", na.strings = "", stringsAsFactors = FALSE)
  setNames(out, names(out) %>% clean_names())
}

auk_read_dt <- function(file) {

}

clean_names <- function(x) {
  x_clean <- tolower(x) %>%
    trimws() %>%
    stringr::str_replace_all("[./ ]", "_")
  x_clean
}
