#' Read an EBD file
#'
#' Read an eBird Basic Dataset file using [data.table][fread],
#' [readr][read_delim], or [read.delim] depending on which packages are
#' installed. This function chooses read options that are suitable for EBD files
#' and cleans up variable names to be in `snake_case`.
#'
#' @param file character; EBD file to read.
#' @param sep character; single character used to separate fields within a row.
#' @param setclass `data.frame`, `tbl`, or `data.table`; optionally set
#'   additional classes to set on the output data. All return objects are
#'   data frames, but may additionally be `tbl` (for use with `dplyr`
#'   and the tidyverse) or `data.table` (for use with `data.table`).
#'
#' @return A `data.frame` unless `setclass` is used in which case the data frame
#'   will have additonal classes `tbl` or `data.table`.
#' @export
#' @examples
#' ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd()
#' # optionally return a tibble for use with tidyverse
#' ebd_tbl <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd(setclass = "tbl")
read_ebd <- function(file, sep = "\t",
                     setclass = c("data.frame", "tbl", "data.table")) {
  # checks
  assert_that(
    assertthat::is.string(file),
    file.exists(file))
  setclass <- match.arg(setclass)

  # read using fread, read_delim, or read.delim
  if (requireNamespace("data.table", quietly = TRUE)) {
    x <- data.table::fread(file, sep = sep, quote = "", na.strings = "")
  } else if (requireNamespace("readr", quietly = TRUE)) {
    x <- readr::read_delim(file, delim = sep, quote = "", na = "")
    if ("spec" %in% names(attributes(x))) {
      attr(x, "spec") <- NULL
    }
  } else {
    x <- read.delim(file, sep = sep, quote = "", na.strings = "",
                    stringsAsFactors = FALSE)
  }

  # names to snake case
  x <- setNames(x, names(x) %>% clean_names())

  # set output format
  if (setclass == "tbl") {
    if (inherits(x, "tbl")) {
      return(x)
    }
    return(structure(x, class = c("tbl_df", "tbl", "data.frame")))
  } else if (setclass == "data.table") {
    if (inherits(x, "data.table")) {
      return(x)
    }
    return(structure(x, class = c("data.table", "data.frame")))
  } else {
    return(structure(x, class = "data.frame"))
  }
}

clean_names <- function(x) {
  x_clean <- tolower(x) %>%
    trimws() %>%
    stringr::str_replace_all("[./ ]", "_")
  x_clean
}
