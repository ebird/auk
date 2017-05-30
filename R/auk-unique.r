#' Remove duplicate group checklists
#'
#' eBird checklists can be shared among a group of multiple observers, in which
#' case observations will be duplicated in the database. This functions removes
#' these duplicates from the eBird Basic Dataset (EBD) creating a set of unique
#' bird observations. This function is called automatically by [read_ebd()].
#'
#' @param x data.frame; the EBD data frame, typically as imported by
#'   [read_ebd()].
#' @param group_id character; the name of the group ID column.
#'
#' @return A data.frame with unique observations.
#' @export
#' @examples
#' # read in an ebd file and don't automatically remove duplicates
#' ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   read_ebd(unique = FALSE)
#' # remove duplicates
#' ebd_unique <- auk_unique(ebd)
#' nrow(ebd)
#' nrow(ebd_unique)
auk_unique <- function(x, group_id = "group_identifier") {
  # checks
  assert_that(
    is.data.frame(x),
    assertthat::is.string(group_id),
    group_id %in% names(x))

  # convert group_id to character if not already
  if (!is.character(x[[group_id]])) {
    x[[group_id]] <- as.character(x[[group_id]])
  }

  # identify non-group records
  not_grouped <- is.na(x[[group_id]])

  # identify duplicated records
  not_duped <- !duplicated(x[[group_id]])

  # only keep non-group or non-duplicated records
  x[not_grouped | not_duped, ]
}
