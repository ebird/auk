#' Filter the EBD by duration
#'
#' Define a filter for the eBird Basic Dataset (EBD) based on the duration of
#' the checklist. This function only defines the filter and, once all filters
#' have been defined, [auk_filter()] should be used to call AWK and perform the
#' filtering.
#'
#' @param x `ebd` object; reference to EBD file created by [auk_ebd()].
#' @param duration integer; 2 element vector specifying the range of durations
#'   in minutes to filter by.
#'
#' @return An `ebd` object.
#' @export
#' @examples
#' # only keep checklists that are less than an hour long
#' system.file("extdata/ebd-sample.txt", package = "auk") %>%
#'   auk_ebd() %>%
#'   auk_duration(duration = c(0, 60))
auk_duration <- function(x, duration)  {
  UseMethod("auk_duration")
}

#' @export
auk_duration <- function(x, duration) {
  # checks
  assert_that(
    length(duration) == 2,
    is.numeric(duration),
    duration[1] <= duration[2]
  )

  # define filter
  x$duration_filter <- as.integer(round(duration))
  return(x)
}
