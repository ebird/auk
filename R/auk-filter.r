#' Filter the EBD using AWK
#'
#' Convert the filters defined in an `ebd` object into an AWK script and run
#' this script to produce a filtered eBird Reference Dataset (ERD). The initial
#' creation of the `ebd` object should be done with [auk_ebd()] and filters can
#' be defined using the various other functions in this package, e.g.
#' [auk_species()] or [auk_country()]. Note that this function typically takes
#' at least a couple hours to run.
#'
#' The AWK script can be saved for future reference by providing an output
#' filename to `awk_file`. The default behvaiour of this function is to generate
#' and run the AWK script, however, by setting `execute = FALSE` the AWK script
#' will be generated but not run. In this case, `file` is ignored and `awk_file`
#' must be specified.
#'
#' Calling this function requires that the command line utility AWK is
#' installed. Linux and Mac machines should have AWK by default, Windows users
#' will likely need to install [Cygwin](https://www.cygwin.com).
#'
#' @param x `ebd` object; reference to EBD file created by [auk_ebd()].
#' @param file character; output file.
#' @param awk_file character; output file to optionally save the awk script to.
#' @param sep character; the input field seperator, the EBD is tab separated by
#'   default. Must only be a single character and space delimited is not allowed
#'   since spaces appear in many of the fields.
#' @param execute logical; whether to execute the awk script, or output it to a
#'   file for manual execution. If this flag is `FALSE`, `awk_file` must be
#'   provided.
#' @param overwrite logical; overwrite output file if it already exists
#'
#' @return If AWK ran without errors, the output filename is returned,
#'   however, if an error was encountered the exit code is returned. If `execute
#'   = FALSE`, then the path to the AWK script is returned rather than the path
#'   to the output file.
#' @export
#' @examples
#' # temp output file
#' # define filters
#' filters <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   auk_ebd() %>%
#'   auk_species(species = c("Gray Jay", "Blue Jay")) %>%
#'   auk_country(country = c("US", "Canada")) %>%
#'   auk_extent(extent = c(-125, 37, -120, 52)) %>%
#'   auk_date(date = c("2010-01-01", "2010-12-31")) %>%
#'   auk_time(time = c("06:00", "08:00")) %>%
#'   auk_duration(duration = c(0, 60)) %>%
#'   auk_complete()
#' out_file <- tempfile()
#' auk_filter(filters, file = out_file)
#' # clean
#' unlink(out_file)
auk_filter <- function(x, file, awk_file, sep, execute, overwrite) {
  UseMethod("auk_filter")
}

#' @export
auk_filter.ebd <- function(x, file, awk_file, sep = "\t", execute = TRUE,
                            overwrite = FALSE) {
  # checks
  if (execute && !auk_installed()) {
    stop("auk_filter() requires a valid AWK install, unless execute = FALSE.")
  }
  assert_that(
    assertthat::is.flag(execute),
    !execute || assertthat::is.string(file),
    missing(awk_file) || assertthat::is.string(awk_file),
    assertthat::is.string(sep), nchar(sep) == 1, sep != " ",
    assertthat::is.flag(overwrite)
  )
  if (!execute && missing(awk_file)) {
    stop("awk_file must be set when executre is FALSE.")
  }
  # check output file
  if (!missing(file)) {
    if (!dir.exists(dirname(file))) {
      stop("Output directory doesn't exist.")
    }
    if (!overwrite && file.exists(file)) {
      stop("Output file already exists, use overwrite = TRUE.")
    }
  }
  # check output awk file
  if (!missing(awk_file) && !dir.exists(dirname(awk_file))) {
    stop("Output directory for awk file doesn't exist.")
  }

  # set up filters
  filters <- list(sep = sep)
  # species filter
  if (length(x$species_filter) == 0) {
    filters$species_filter <- ""
  } else {
    idx <- x$column_index$index[x$column_index$id == "species"]
    condition <- paste0("$", idx, " == \"", x$species_filter, "\"",
                        collapse = " || ")
    filters$species_filter <- str_interp(awk_if, list(condition = condition))
  }
  # country filter
  if (length(x$country_filter) == 0) {
    filters$country_filter <- ""
  } else {
    idx <- x$column_index$index[x$column_index$id == "country"]
    condition <- paste0("$", idx, " == \"", x$country_filter, "\"",
                        collapse = " || ")
    filters$country_filter <- str_interp(awk_if, list(condition = condition))
  }
  # extent filter
  if (length(x$extent_filter) == 0) {
    filters$extent_filter <- ""
  } else {
    lat_idx <- x$column_index$index[x$column_index$id == "lat"]
    lng_idx <- x$column_index$index[x$column_index$id == "lng"]
    condition <- paste0("$${lng_idx} > ${xmn} && ",
                        "$${lng_idx} < ${xmx} && ",
                        "$${lat_idx} > ${ymn} && ",
                        "$${lat_idx} < ${ymx}") %>%
      str_interp(list(lat_idx = lat_idx, lng_idx = lng_idx,
                      xmn = x$extent_filter[1], xmx = x$extent_filter[3],
                      ymn = x$extent_filter[2], ymx = x$extent_filter[4]))
    filters$extent_filter <- str_interp(awk_if, list(condition = condition))
  }
  # date filter
  if (length(x$date_filter) == 0) {
    filters$date_filter <- ""
  } else {
    idx <- x$column_index$index[x$column_index$id == "date"]
    condition <- str_interp("$${idx} > \"${mn}\" && $${idx} < \"${mx}\"",
                            list(idx = idx,
                                 mn = x$date_filter[1],
                                 mx = x$date_filter[2]))
    filters$date_filter <- str_interp(awk_if, list(condition = condition))
  }
  # time filter
  if (length(x$time_filter) == 0) {
    filters$time_filter <- ""
  } else {
    idx <- x$column_index$index[x$column_index$id == "time"]
    condition <- str_interp("$${idx} > \"${mn}\" && $${idx} < \"${mx}\"",
                            list(idx = idx,
                                 mn = x$time_filter[1],
                                 mx = x$time_filter[2]))
    filters$time_filter <- str_interp(awk_if, list(condition = condition))
  }
  # duration filter
  if (length(x$duration_filter) == 0) {
    filters$duration_filter <- ""
  } else {
    idx <- x$column_index$index[x$column_index$id == "duration"]
    condition <- str_interp("$${idx} > ${mn} && $${idx} < ${mx}",
                            list(idx = idx,
                                 mn = x$duration_filter[1],
                                 mx = x$duration_filter[2]))
    filters$duration_filter <- str_interp(awk_if, list(condition = condition))
  }
  # complete checklists only
  if (x$complete) {
    idx <- x$column_index$index[x$column_index$id == "complete"]
    condition <- str_interp("$${idx} == 1", list(idx = idx))
    filters$complete <- str_interp(awk_if, list(condition = condition))
  } else {
    filters$complete <- ""
  }

  # generate awk script
  awk_script <- str_interp(awk_filter, filters)

  # output file
  if (!missing(awk_file)) {
    writeLines(awk_script, awk_file)
  }
  # run
  if (execute) {
    awk <- paste0("awk '", awk_script, "' ")
    com <- paste0(awk, x$file, " > ", file)
    exit_code <- system(com)
    if (exit_code == 0) {
      out <- normalizePath(file)
    } else {
      out <- exit_code
    }
  } else {
    out <- normalizePath(awk_file)
  }
  return(out)
}

# awk script template
awk_filter <- "
BEGIN {
  FS = \"${sep}\"
  OFS = \"${sep}\"
}
{
  keep = 1

  # filters
  ${species_filter}
  ${country_filter}
  ${extent_filter}
  ${date_filter}
  ${time_filter}
  ${duration_filter}
  ${complete}

  # keeps header
  if (NR == 1) {
    keep = 1
  }

  if (keep == 1) {
    print $0
  }
}
"

awk_if <- "
  if (keep == 1 && (${condition})) {
    keep = 1
  } else {
    keep = 0
  }
"
