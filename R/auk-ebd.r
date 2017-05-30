#' Reference to EBD file
#'
#' Create a reference to an eBird Basic Dataset (EBD) file in preparation for
#' filtering using AWK.
#'
#' @param file character; input file.
#' @param file_sampling character; optional input sampling event data file,
#'   required if you intend to zero-fill the data to produce a presence absence
#'   data set. The sampling file consists of just effort information for every
#'   eBird checklist. Any species not appearing in the EBD for a given checklist
#'   is implicitly considered to have a count of 0. This file should be
#'   downloaded at the same time as the EBD to ensure they are in sync.
#' @param sep character; the input field seperator, the EBD is tab separated so
#'   this should generally not be modified. Must only be a single character and
#'   space delimited is not allowed since spaces appear in many of the fields.
#'
#' @details The EBD can be downloaded as a tab-separated text file from the
#'   [eBird website](http://ebird.org/ebird/data/download) after submitting a
#'   request for access. As of February 2017, this file is nearly 150 GB making
#'   it challenging to work with. If you're only interested in a single species
#'   or a small region it is possible to submit a custom download request. This
#'   approach is suggested to speed up processing time.
#'
#' @return An `ebd` object storing the file reference and the desired filters
#'   once created with other package functions.
#' @export
#' @examples
#' # example data
#' f <- system.file("extdata/ebd-sample.txt", package = "auk")
#' auk_ebd(f)
auk_ebd <- function(file, file_sampling, sep = "\t") {
  # checks
  assert_that(
    file.exists(file),
    assertthat::is.string(sep), nchar(sep) == 1, sep != " "
  )

  # read header rows
  header <- tolower(get_header(file, sep))

  # identify columns required for filtering
  column_index <- data.frame(
    id = c("species",
           "country", "lat", "lng",
           "date", "time", "duration",
           "complete"),
    name = c("scientific name",
             "country code", "latitude", "longitude",
             "observation date", "time observations started", "duration minutes",
             "all species reported"),
    stringsAsFactors = FALSE)
  # all these columns should be in header
  if (!all(column_index$name %in% header)) {
    stop("Problem parsing header in EBD file.")
  }
  column_index$index <- match(column_index$name, header)

  # process sampling data header
  if (!missing(file_sampling)) {
    assert_that(
      file.exists(file_sampling)
    )
    file_sampling <- normalizePath(file_sampling)
    # species not in sampling data
    column_index_sampling <- column_index[column_index$id != "species", ]
    # read header rows
    header_sampling <- tolower(get_header(file_sampling, sep))
    # all these columns should be in header
    if (!all(column_index_sampling$name %in% header_sampling)) {
      stop("Problem parsing header in EBD file.")
    }
    column_index_sampling$index <- match(column_index_sampling$name,
                                         header_sampling)

  } else {
    file_sampling <- NULL
    column_index_sampling <- NULL
  }

  # output
  structure(
    list(
      file = normalizePath(file),
      file_sampling = normalizePath(file_sampling),
      column_index = column_index,
      column_index_sampling = column_index_sampling,
      species_filter = character(),
      country_filer = character(),
      extent_filter = numeric(),
      date_filter = character(),
      time_filter = character(),
      duration_filter = numeric(),
      complete = FALSE
    ),
    class = "ebd"
  )
}

#' @export
print.ebd <- function(x, ...) {
  cat("eBird Basic Dataset (EBD): \n")
  cat(x$file)
  cat("\n")
  if (!is.null(x$file_sampling)) {
    cat("EBD Sampling File: \n")
    cat(x$file_sampling)
    cat("\n")
  }
  cat("\n")

  cat("Filters: \n")
  # species filter
  cat("Species: ")
  if (length(x$species_filter) == 0) {
    cat("all")
  } else if (length(x$species_filter) <= 10) {
    cat(paste(x$species_filter, collapse = ", "))
  } else {
    cat(paste0(length(x$species_filter), " species"))
  }
  cat("\n")
  # country filter
  cat("Countries: ")
  if (length(x$country_filter) == 0) {
    cat("all")
  } else if (length(x$country_filter) <= 10) {
    cat(paste(x$country_filter, collapse = ", "))
  } else {
    cat(paste0(length(x$country_filter), " countries"))
  }
  cat("\n")
  # extent filter
  cat("Spatial extent: ")
  e <- x$extent_filter
  if (length(e) == 0) {
    cat("full extent")
  } else {
    cat(paste0("Lat ", round(e[1]), " - ", round(e[3]), "; "))
    cat(paste0("Lon ", round(e[2]), " - ", round(e[4])))
  }
  cat("\n")
  # date filter
  cat("Date: ")
  if (length(x$date_filter) == 0) {
    cat("all")
  } else {
    cat(paste0(x$date_filter[1], " - ", x$date_filter[2]))
  }
  cat("\n")
  # time filter
  cat("Time: ")
  if (length(x$time_filter) == 0) {
    cat("all")
  } else {
    cat(paste0(x$time_filter[1], "-", x$time_filter[2]))
  }
  cat("\n")
  # duration filter
  cat("Duration: ")
  if (length(x$duration_filter) == 0) {
    cat("all")
  } else {
    cat(paste0(x$duration_filter[1], "-", x$duration_filter[2], " minutes"))
  }
  cat("\n")
  # complete checklists only
  cat("Complete checklists only: ")
  if (x$complete) {
    cat("yes")
  } else {
    cat("no")
  }
  cat("\n")
}
