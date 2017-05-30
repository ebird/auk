#' Read an EBD file
#'
#' Read an eBird Basic Dataset file using [data.table::fread()],
#' [readr::read_delim()], or [read.delim] depending on which packages are
#' installed. **Note that this function typically takes at least a couple hours
#' to run.**
#'
#' @param file character; EBD file to read.
#' @param sep character; single character used to separate fields within a row.
#' @param unique logical; should duplicate grouped checklists be removed. If
#'   `unique = TRUE`, [auk_unique()] is called on the EBD before returning.
#' @param setclass `tbl`, `data.frame`, or `data.table`; optionally set
#'   additional classes to set on the output data. All return objects are
#'   data frames, but may additionally be `tbl` (for use with `dplyr`
#'   and the tidyverse) or `data.table` (for use with `data.table`). The default
#'   is to return a tibble.
#'
#' @details  This functions performs the following processing steps:
#'
#' - Data types for columns are manually set based on column names used in the
#' February 2017 EBD. If variables are added or names are changed in later
#' releases, any new variables will have data types inferred by the import
#' function used.
#' - Variables names are converted to `snake_case`.
#' - Duplicate observations resulting from group checklists are removed using
#' [auk_unique()], unless `unique = FALSE`.
#'
#' @return A `data.frame` with additional class `tbl` unless `setclass` is used,
#'   in which case a standard `data.frame` or `data.table` can be returned.
#' @export
#' @examples
#' ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd()
#' # optionally return a plain data.frame
#' ebd_df <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd(setclass = "data.frame")
read_ebd <- function(file, sep = "\t", unique = TRUE,
                     setclass = c("tbl", "data.frame", "data.table")) {
  # checks
  assert_that(
    assertthat::is.string(file),
    file.exists(file))
  setclass <- match.arg(setclass)

  # get header
  header <- get_header(file, sep = sep)
  if (header[length(header)] == "") {
    header <- header[-length(header)]
  }

  # read using fread, read_delim, or read.delim
  if (requireNamespace("data.table", quietly = TRUE)) {
    col_types <- get_col_types(header, reader = "fread")
    x <- data.table::fread(file, sep = sep, quote = "", na.strings = "",
                           colClasses = col_types)
    # convert columns to logical
    tf_cols <- c("ALL SPECIES REPORTED", "HAS MEDIA", "APPROVED", "REVIEWED")
    for (i in tf_cols) {
      if (i %in% names(x)) {
        x[[i]] <- as.logical(x[[i]])
      }
    }
    # convert date and time columns
    if ("LAST EDITED DATE" %in% names(x)) {
      x[["LAST EDITED DATE"]] <- as.POSIXct(x[["LAST EDITED DATE"]],
                                            format = "%Y-%m-%d %H:%M:%S")
    }
    if ("OBSERVATION DATE" %in% names(x)) {
      x[["OBSERVATION DATE"]] <- as.Date(x[["OBSERVATION DATE"]],
                                         format = "%Y-%m-%d")
    }
  } else if (requireNamespace("readr", quietly = TRUE)) {
    col_types <- get_col_types(header, reader = "read_delim")
    print(col_types)
    x <- readr::read_delim(file, delim = sep, quote = "", na = "",
                           col_types = col_types)
    if ("spec" %in% names(attributes(x))) {
      attr(x, "spec") <- NULL
    }
  } else {
    w <- paste("read.delim is slow for large EBD files, for better performance",
               "insall the readr or data.table packages.")
    warning(w)
    col_types <- get_col_types(header, reader = "read.delim")
    x <- utils::read.delim(file, sep = sep, quote = "", na.strings = "",
                           stringsAsFactors = FALSE, colClasses = col_types)
    # convert columns to logical
    tf_cols <- c("ALL.SPECIES.REPORTED", "HAS.MEDIA", "APPROVED", "REVIEWED")
    for (i in tf_cols) {
      if (i %in% names(x)) {
        x[[i]] <- as.logical(x[[i]])
      }
    }
  }

  # remove possible blank final column
  blank <- grepl("^[xX][0-9]{2}$", names(x)[ncol(x)])
  if (blank) {
    x[ncol(x)] <- NULL
  }

  # names to snake case
  names(x) <- clean_names(names(x))

  # remove duplicate group checklists
  if (unique) {
    x <- auk_unique(x)
  }

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

get_col_types <- function(header,
                          reader = c("fread", "read_delim", "read.delim")) {
  reader <- match.arg(reader)

  # column types based on feb 2017 ebd
  col_types = c(
    "GLOBAL UNIQUE IDENTIFIER" = "character",
    "LAST EDITED DATE" = "POSIXct",
    "TAXONOMIC ORDER" = "integer",
    "CATEGORY" = "character",
    "COMMON NAME" = "character",
    "SCIENTIFIC NAME" = "character",
    "SUBSPECIES COMMON NAME" = "character",
    "SUBSPECIES SCIENTIFIC NAME" = "character",
    "OBSERVATION COUNT" = "character",
    "BREEDING BIRD ATLAS CODE" = "character",
    "AGE/SEX" = "character",
    "COUNTRY" = "character",
    "COUNTRY CODE" = "character",
    "STATE" = "character",
    "STATE CODE" = "character",
    "COUNTY" = "character",
    "COUNTY CODE" = "character",
    "IBA CODE" = "character",
    "BCR CODE" = "integer",
    "USFWS CODE" = "character",
    "ATLAS BLOCK" = "character",
    "LOCALITY" = "character",
    "LOCALITY ID" = "character",
    "LOCALITY TYPE" = "character",
    "LATITUDE" = "numeric",
    "LONGITUDE" = "numeric",
    "OBSERVATION DATE" = "Date",
    "TIME OBSERVATIONS STARTED" = "character",
    "OBSERVER ID" = "character",
    "FIRST NAME" = "character",
    "LAST NAME" = "character",
    "SAMPLING EVENT IDENTIFIER" = "character",
    "PROTOCOL TYPE" = "character",
    "PROJECT CODE" = "character",
    "DURATION MINUTES" = "integer",
    "EFFORT DISTANCE KM" = "numeric",
    "EFFORT AREA HA" = "numeric",
    "NUMBER OBSERVERS" = "integer",
    "ALL SPECIES REPORTED" = "logical",
    "GROUP IDENTIFIER" = "character",
    "HAS MEDIA" = "logical",
    "APPROVED" = "logical",
    "REVIEWED" = "logical",
    "REASON" = "character",
    "TRIP COMMENTS" = "character",
    "SPECIES COMMENTS" = "character")

  # remove any columns not in header
  col_types <- col_types[names(col_types) %in% header]

  # make reader specific changes
  if (reader == "fread") {
    col_types[col_types == "logical"] = "integer"
    col_types[col_types == "POSIXct"] = "character"
    col_types[col_types == "Date"] = "character"
  } else if (reader == "read_delim") {
    col_types[col_types == "POSIXct"] = "Time"
    col_types = substr(col_types, 1, 1)
  } else {
    col_types[col_types == "logical"] = "integer"
    names(col_types) <- stringr::str_replace_all(names(col_types), " ", ".")
  }
  col_types
}
