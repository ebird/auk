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
#' @param checklist_id character; the name of the checklist ID column, each
#'   checklist within a group will get a unique value for this field. The record
#'   with the lowest `checklist_id` will be picked as the unique record within
#'   each group.
#'
#' @details This function chooses the checklist within in each that has the
#'   lowest value for the field specified by `checklist_id`. A new column is
#'   also created, `checklist_id`, whose value is the taken from the field
#'   specified in the `checklist_id` parameter for non-group checklists and from
#'   the field specified by the `group_id` parameter for grouped checklists.
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
                       checklist_id = "sampling_event_identifier") {
  # checks
  assert_that(
    is.data.frame(x),
    assertthat::is.string(group_id),
    group_id %in% names(x),
    assertthat::is.string(checklist_id),
    checklist_id %in% names(x))

  # convert group_id to character if not already
  if (!is.character(x[[group_id]])) {
    x[[group_id]] <- as.character(x[[group_id]])
  }

  # identify and separate non-group records
  grouped <- !is.na(x[[group_id]])
  x_grouped <- x[grouped, ]

  # sort by sampling event id
  x_grouped <- x_grouped[order(x_grouped[[checklist_id]]), ]

  # remove duplicated records
  x_grouped <- x_grouped[!duplicated(x_grouped[[group_id]]), ]

  # set id field
  x$checklist_id <- x[[checklist_id]]
  x_grouped$checklist_id <- x_grouped[[group_id]]

  # only keep non-group or non-duplicated records
  rbind(x[!grouped, ], x_grouped)
}
