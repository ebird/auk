#' Read and zero-fill an EBD file
#'
#' Read an eBird Basic Dataset file, and associated sampling event data file, to
#' produce a zero-filled, presence-absence dataset. The EBD contains bird
#' sightings and the sampling event data is a set of all checklists, they can be
#' combined to infer absence data by assuming any species not reported on a
#' checklist was had a count of zero.
#'
#' @param x filename or `auk_ebd` object with associtated output
#'   files as created by [auk_filter()]. If a filename is provided, it must
#'   point to the EBD and the `sampling_events` argument must point to the
#'   sampling event data file.
#' @param sampling_events character; filename for the sampling event data.
#' @param sep character; single character used to separate fields within a row.
#' @param setclass `tbl`, `data.frame`, or `data.table`; optionally set
#'   additional classes to set on the output data. All return objects are
#'   data frames, but may additionally be `tbl` (for use with `dplyr`
#'   and the tidyverse) or `data.table` (for use with `data.table`). The default
#'   is to return a tibble.
#' @param ... additional arguments passed to methods.
#'
#' @return A `data.frame` with additional class `tbl` unless `setclass` is used,
#'   in which case a standard `data.frame` or `data.table` can be returned.
#' @export
#' @examples
#' # read and zero-fill the sampling data
#' f_ebd <- system.file("extdata/zerofill-ex_ebd.txt", package = "auk")
#' f_smpl <- system.file("extdata/zerofill-ex_sampling.txt", package = "auk")
#' x <- read_zerofill(x = f_ebd, sampling_events = f_smpl)
read_zerofill <- function(x, ...) {
  UseMethod("read_zerofill")
}

#' @export
#' @describeIn read_zerofill Filename of EBD.
read_zerofill.character <- function(x, sampling_events, sep = "\t",
                                    setclass = c("tbl", "data.frame",
                                                 "data.table"), ...) {
  # checks
  assert_that(
    assertthat::is.string(x), file.exists(x),
    assertthat::is.string(sampling_events), file.exists(sampling_events),
    assertthat::is.string(sep), nchar(sep) == 1, sep != " ")
  setclass <- match.arg(setclass)
  if (setclass == "data.table" &&
      !requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table package must be installed to return a data.table.")
  }

  # read in the two files
  ebd <- read_ebd(x = x, sep = sep, unique = TRUE, setclass = setclass)
  sed <- read_sampling(x = sampling_events, sep = sep, unique = TRUE,
                       setclass = setclass)
  list(ebd, sed)
}

#' @export
#' @describeIn read_zerofill `auk_ebd` object output from [auk_filter()]. Must
#'   have had a sampling event data file set in the original call to
#'   [auk_ebd()].
read_zerofill.auk_ebd <- function(x, sep = "\t",
                                  setclass = c("tbl", "data.frame",
                                               "data.table"), ...) {
  setclass <- match.arg(setclass)
  # zero-filling requires complete checklists
  if (!x$filters$complete) {
    e <- paste("Sampling event data file provided, but filters have not been ",
               "set to only return complete checklists. Complete checklists ",
               "are required for zero-filling. Try calling auk_complete().")
    stop(e)
  }
  # check that output files defined
  if (is.null(x$output)) {
    stop("No output EBD file in this auk_ebd object, try calling auk_filter().")
  }
  if (is.null(x$output_sampling)) {
    stop("No output sampling event data file in this auk_ebd object.")
  }
  read_zerofill(x = x$output, sampling_events = x$output_sampling,
                sep = sep, setclass = setclass)
}
