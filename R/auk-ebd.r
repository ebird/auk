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
#' @return An `auk_ebd` object storing the file reference and the desired
#'   filters once created with other package functions.
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
  col_idx <- data.frame(
    id = c("species",
           "country", "lat", "lng",
           "date", "time",
           "duration", "complete"),
    name = c("scientific name",
             "country code", "latitude", "longitude",
             "observation date", "time observations started",
             "duration minutes", "all species reported"),
    stringsAsFactors = FALSE)
  # all these columns should be in header
  if (!all(col_idx$name %in% header)) {
    stop("Problem parsing header in EBD file.")
  }
  col_idx$index <- match(col_idx$name, header)

  # process sampling data header
  if (!missing(file_sampling)) {
    assert_that(
      file.exists(file_sampling)
    )
    file_sampling <- normalizePath(file_sampling)
    # species not in sampling data
    col_idx_sampling <- col_idx[col_idx$id != "species", ]
    # read header rows
    header_sampling <- tolower(get_header(file_sampling, sep))
    # all these columns should be in header
    if (!all(col_idx_sampling$name %in% header_sampling)) {
      stop("Problem parsing header in EBD file.")
    }
    col_idx_sampling$index <- match(col_idx_sampling$name, header_sampling)

  } else {
    file_sampling <- NULL
    col_idx_sampling <- NULL
  }

  # output
  structure(
    list(
      file = normalizePath(file),
      file_sampling = file_sampling,
      output = NULL,
      output_sampling = NULL,
      col_idx = col_idx,
      col_idx_sampling = col_idx_sampling,
      filters = list(
        species = character(),
        country = character(),
        extent = numeric(),
        date = character(),
        time = character(),
        duration = numeric(),
        complete = FALSE
      )
    ),
    class = "auk_ebd"
  )
}

#' @export
print.auk_ebd <- function(x, ...) {
  cat("Input \n")
  cat(paste("  EBD:", x$file, "\n"))
  if (!is.null(x$file_sampling)) {
    cat(paste("  EBD:", x$file_sampling, "\n"))
  }
  cat("\n")

  cat("Output \n")
  if (is.null(x$output)) {
    cat("  Filters not executed.\n")
  } else {
    cat(paste("  EBD:", x$output, "\n"))
    if (!is.null(x$output_sampling)) {
      cat(paste("  EBD:", x$output_sampling, "\n"))
    }
  }
  cat("\n")

  cat("Filters \n")
  # species filter
  cat("  Species: ")
  if (length(x$filters$species) == 0) {
    cat("all")
  } else if (length(x$filters$species) <= 10) {
    cat(paste(x$filters$species, collapse = ", "))
  } else {
    cat(paste0(length(x$filters$species), " species"))
  }
  cat("\n")
  # country filter
  cat("  Countries: ")
  if (length(x$filters$country) == 0) {
    cat("all")
  } else if (length(x$filters$country) <= 10) {
    cat(paste(x$filters$country, collapse = ", "))
  } else {
    cat(paste0(length(x$filters$country), " countries"))
  }
  cat("\n")
  # extent filter
  cat("  Spatial extent: ")
  e <- x$filters$extent
  if (length(e) == 0) {
    cat("full extent")
  } else {
    cat(paste0("Lat ", round(e[1]), " - ", round(e[3]), "; "))
    cat(paste0("Lon ", round(e[2]), " - ", round(e[4])))
  }
  cat("\n")
  # date filter
  cat("  Date: ")
  if (length(x$filters$date) == 0) {
    cat("all")
  } else {
    cat(paste0(x$filters$date[1], " - ", x$filters$date[2]))
  }
  cat("\n")
  # time filter
  cat("  Time: ")
  if (length(x$filters$time) == 0) {
    cat("all")
  } else {
    cat(paste0(x$filters$time[1], "-", x$filters$time[2]))
  }
  cat("\n")
  # duration filter
  cat("  Duration: ")
  if (length(x$filters$duration) == 0) {
    cat("all")
  } else {
    cat(paste0(x$filters$duration[1], "-", x$filters$duration[2], " minutes"))
  }
  cat("\n")
  # complete checklists only
  cat("  Complete checklists only: ")
  if (x$filters$complete) {
    cat("yes")
  } else {
    cat("no")
  }
  cat("\n")
}
