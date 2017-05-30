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
#' @param sort_by character; the name of the field to sort by prior to picking
#'   the first record.
#'
#' @return A data.frame with unique observations.
#' @export
#' @examples
#' # read in an ebd file and don't automatically remove duplicates
#' ebd <- system.file("extdata/ebd-sample.txt", package = "auk") %>%
#'   read_ebd(unique = FALSE)
#' # remove duplicates
#' ebd_unique <- auk_unique(ebd)
#' nrow(ebd)
#' nrow(ebd_unique)
auk_unique <- function(x, group_id = "group_identifier",
                       sort_by = "sampling_event_identifier") {
  # checks
  assert_that(
    is.data.frame(x),
    assertthat::is.string(group_id),
    group_id %in% names(x),
    assertthat::is.string(sort_by),
    sort_by %in% names(x))

  # convert group_id to character if not already
  if (!is.character(x[[group_id]])) {
    x[[group_id]] <- as.character(x[[group_id]])
  }

  # identify and separate non-group records
  grouped <- is.na(x[[group_id]])
  x_grouped <- x[grouped, ]

  # sort by sampling event id
  x_grouped <- x_grouped[order(x_grouped[[sort_by]]), ]

  # remove duplicated records
  x_grouped <- x_grouped[!duplicated(x_grouped[[group_id]]), ]

  # only keep non-group or non-duplicated records
  rbind(x[!grouped, ], x_grouped)
}
