#' Read an EBD file
#'
#' Read an eBird Basic Dataset file using [readr][read_delim]. This function
#' chooses read options and column formats that are suitable for EBD files and
#' cleans up variable names to be in `snake_case`. Note that this function makes
#' assumptions about the names of the columns in the EBD file and will not work
#' correctly if the header row has been modified.
#'
#' @param file character; EBD file to read.
#' @param sep character; single character used to separate fields within a row.
#' @param setclass `tbl`, `data.frame`, or `data.table`; optionally set
#'   additional classes to set on the output data. All return objects are
#'   data frames, but may additionally be `tbl` (for use with `dplyr`
#'   and the tidyverse) or `data.table` (for use with `data.table`). The default
#'   is to return a tibble.
#'
#' @return A `data.frame` with additional class `tbl` unless `setclass` is used,
#'   in which case a standard `data.frame` or `data.table` can be returned.
#' @export
#' @examples
#' ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd()
#' # optionally return a plain data.frame
#' ebd_tbl <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd(setclass = "data.frame")
read_ebd <- function(file, sep = "\t",
                     setclass = c("tbl", "data.frame", "data.table")) {
  # checks
  assert_that(
    assertthat::is.string(file),
    file.exists(file))
  setclass <- match.arg(setclass)

  # read using readr::read_delim
  col_types <- readr::cols(
    .default = readr::col_character(),
    `LAST EDITED DATE` = readr::col_datetime(format = ""),
    `TAXONOMIC ORDER` = readr::col_double(),
    `BCR CODE` = readr::col_integer(),
    LATITUDE = readr::col_double(),
    LONGITUDE = readr::col_double(),
    `OBSERVATION DATE` = readr::col_date(format = ""),
    `DURATION MINUTES` = readr::col_integer(),
    `EFFORT DISTANCE KM` = readr::col_double(),
    `EFFORT AREA HA` = readr::col_double(),
    `NUMBER OBSERVERS` = readr::col_integer(),
    `ALL SPECIES REPORTED` = readr::col_logical(),
    `HAS MEDIA` = readr::col_logical(),
    APPROVED = readr::col_logical(),
    REVIEWED = readr::col_logical()
  )
  x <- readr::read_delim(file, delim = sep, quote = "", na = "",
                         col_types = col_types)
  attr(x, "spec") <- NULL

  # remove possible blank final column
  blank <- grepl("^[xX][0-9]{2}$", names(x)[ncol(x)])
  if (blank) {
    x[ncol(x)] <- NULL
  }

  # names to snake case
  names(x) <- clean_names(names(x))

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
