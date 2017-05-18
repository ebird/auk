#' Filter the EBD by date
#'
#' Define a filter for the eBird Basic Dataset (EBD) based on a range of dates.
#' This function only defines the filter and, once all filters have been
#' defined, [auk_filter()] should be used to call AWK and perform the
#' filtering.
#'
#' @param x `ebd` object; reference to EBD file created by [auk_ebd()].
#' @param date character or date; date range to filter by to filter by, provided
#'   either as a character vector in the format `"2015-12-31"` or a vector
#'   of Date objects.
#'
#' @return An `ebd` object.
#' @export
#' @examples
#' system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   auk_ebd() %>%
#'   auk_date(date = c("2010-01-01", "2010-12-31"))
auk_date <- function(x, date)  {
  UseMethod("auk_date")
}

#' @export
auk_date <- function(x, date) {
  # checks
  assert_that(
    length(date) == 2,
    is.character(date) || assertthat::is.date(date),
    date[1] <= date[2]
  )

  # convert to date object, then format as ISO standard date format
  date <- as.Date(date) %>%
    format("%Y-%m-%d")

  # define filter
  x$date_filter <- date
  return(x)
}
