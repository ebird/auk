#' Read an EBD file
#'
#' Read an eBird Basic Dataset file using [data.table::fread()],
#' [readr::read_delim()], or [read.delim] depending on which packages are
#' installed. `read_ebd()` reads the EBD itself, while read_sampling()` reads a
#' sampling event data file.
#'
#' @param x filename or `auk_ebd` object with associtated output
#'   files as created by [auk_filter()].
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
#' ebd <- system.file("extdata/ebd-sample.txt", package = "auk") %>%
#'   read_ebd()
#' # optionally return a plain data.frame
#' ebd_df <- system.file("extdata/ebd-sample.txt", package = "auk") %>%
#'   read_ebd(setclass = "data.frame")
read_ebd <- function(x, sep, unique, setclass) {
  UseMethod("read_ebd")
}

#' @export
#' @describeIn read_ebd Filename of EBD.
read_ebd.character <- function(x, sep = "\t", unique = TRUE,
                               setclass = c("tbl", "data.frame",
                                            "data.table")) {
  # checks
  assert_that(
    assertthat::is.string(x),
    file.exists(x))
  setclass <- match.arg(setclass)
  if (setclass == "data.table" &&
      !requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table package must be installed to return a data.table.")
  }

  # get header
  header <- get_header(x, sep = sep)
  if (header[length(header)] == "") {
    header <- header[-length(header)]
  }

  # read using fread, read_delim, or read.delim
  if (requireNamespace("data.table", quietly = TRUE)) {
    col_types <- get_col_types(header, reader = "fread")
    out <- data.table::fread(x, sep = sep, quote = "", na.strings = "",
                             colClasses = col_types)
    # convert columns to logical
    tf_cols <- c("ALL SPECIES REPORTED", "HAS MEDIA", "APPROVED", "REVIEWED")
    for (i in tf_cols) {
      if (i %in% names(out)) {
        out[[i]] <- as.logical(out[[i]])
      }
    }
    # convert date and time columns
    if ("LAST EDITED DATE" %in% names(out)) {
      out[["LAST EDITED DATE"]] <- as.POSIXct(out[["LAST EDITED DATE"]],
                                              format = "%Y-%m-%d %H:%M:%S")
    }
    if ("OBSERVATION DATE" %in% names(out)) {
      out[["OBSERVATION DATE"]] <- as.Date(out[["OBSERVATION DATE"]],
                                           format = "%Y-%m-%d")
    }
  } else if (requireNamespace("readr", quietly = TRUE)) {
    col_types <- get_col_types(header, reader = "read_delim")
    print(col_types)
    out <- readr::read_delim(x, delim = sep, quote = "", na = "",
                             col_types = col_types)
    if ("spec" %in% names(attributes(out))) {
      attr(out, "spec") <- NULL
    }
  } else {
    w <- paste("read.delim is slow for large EBD files, for better performance",
               "insall the readr or data.table packages.")
    warning(w)
    col_types <- get_col_types(header, reader = "read.delim")
    out <- utils::read.delim(x, sep = sep, quote = "", na.strings = "",
                             stringsAsFactors = FALSE, colClasses = col_types)
    # convert columns to logical
    tf_cols <- c("ALL.SPECIES.REPORTED", "HAS.MEDIA", "APPROVED", "REVIEWED")
    for (i in tf_cols) {
      if (i %in% names(out)) {
        out[[i]] <- as.logical(out[[i]])
      }
    }
  }

  # remove possible blank final column
  blank <- grepl("^[xX][0-9]{2}$", names(out)[ncol(out)])
  if (blank) {
    out[ncol(out)] <- NULL
  }

  # names to snake case
  names(out) <- clean_names(names(out))

  # remove duplicate group checklists
  if (unique) {
    out <- auk_unique(out)
  }

  # set output format
  if (setclass == "tbl") {
    if (inherits(out, "tbl")) {
      return(out)
    }
    return(structure(out, class = c("tbl_df", "tbl", "data.frame")))
  } else if (setclass == "data.table") {
    if (inherits(out, "data.table")) {
      return(out)
    }
    return(data.table::as.data.table(out))
  } else {
    return(structure(out, class = "data.frame"))
  }
}

#' @export
#' @describeIn read_ebd `auk_ebd` object output from [auk_filter()]
read_ebd.auk_ebd <- function(x, sep = "\t", unique = TRUE,
                         setclass = c("tbl", "data.frame", "data.table")) {
  setclass <- match.arg(setclass)
  if (is.null(x$output)) {
    stop("No output EBD file in this auk_ebd object, try calling auk_filter().")
  }
  read_ebd(x$output, sep = sep, unique = unique, setclass = setclass)
}

#' @rdname read_ebd
#' @export
#' @examples
#' # read a sampling event data file
#' x <- system.file("extdata/zerofill-ex_sampling.txt", package = "auk") %>%
#'   read_sampling()
read_sampling <- function(x, sep, unique, setclass) {
  UseMethod("read_sampling")
}

#' @export
#' @describeIn read_ebd Filename of sampling event data file
read_sampling.character <- function(x, sep = "\t", unique = TRUE,
                                    setclass = c("tbl", "data.frame",
                                                 "data.table")) {
  setclass <- match.arg(setclass)
  read_ebd(x = x, sep = sep, unique = unique, setclass = setclass)
}

#' @export
#' @describeIn read_ebd `auk_ebd` object output from [auk_filter()]. Must have
#'   had a sampling event data file set in the original call to [auk_ebd()].
read_sampling.auk_ebd <- function(x, sep = "\t", unique = TRUE,
                                  setclass = c("tbl", "data.frame",
                                               "data.table")) {
  setclass <- match.arg(setclass)
  if (is.null(x$output_sampling)) {
    stop("No output sampling event data file in this auk_ebd object.")
  }
  read_ebd(x$output_sampling, sep = sep, unique = unique, setclass = setclass)
}
