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
#' @param species character; species to include in zero-filled dataset, provided
#'   as scientific or English common names, or a mixture of both. These names
#'   must match the official eBird Taxomony ([ebird_taxonomy]). To include all
#'   species, don't pass anything to this argument.
#' @param sep character; single character used to separate fields within a row.
#' @param collapse logical; whether to call `zerofill_collapse()` to return a
#'   data frame rather than an `auk_zerofill` object.
#' @param setclass `tbl`, `data.frame`, or `data.table`; optionally set
#'   additional classes to set on the output data. All return objects are
#'   data frames, but may additionally be `tbl` (for use with `dplyr`
#'   and the tidyverse) or `data.table` (for use with `data.table`). The default
#'   is to return a tibble.
#' @param ... additional arguments passed to methods.
#'
#' @details
#' `auk_zerofill()` generates an `auk_zerofill` object consisting of a list with
#' elements `observations` and `sampling_events`. `observations` is a data frame
#' giving counts and binary presence/absence data for each species.
#' `sampling_events` is a data frame with checklist level information. The two
#' data frames can be connected via the `checklist_id` field. This format is
#' efficient for storage since the checklist columns are not duplicated for each
#' species, however, working with the data often requires joining the two data
#' frames together.
#'
#' To return a data frame, set `collapse = TRUE`. Alternatively,
#' `zerofill_collapse()` generates a data frame from an `auk_zerofill` object,
#' by joining the two data frames together to produce a single data frame in
#' which each row provides both checklist and species information for a
#' sighting.
#'
#' @return By default, an `auk_zerofill` object, or a data frame if `collapse =
#'   TRUE`.
#' @export
#' @examples
#' # read and zero-fill the sampling data
#' f_ebd <- system.file("extdata/zerofill-ex_ebd.txt", package = "auk")
#' f_smpl <- system.file("extdata/zerofill-ex_sampling.txt", package = "auk")
#' ebd <- auk_zerofill(x = f_ebd, sampling_events = f_smpl)
#' # use the species argument to only include a subset of species
#' ebd_sp <- auk_zerofill(x = f_ebd, sampling_events = f_smpl,
#'                         species = "Collared Kingfisher")
auk_zerofill <- function(x, ...) {
  UseMethod("auk_zerofill")
}

#' @export
#' @describeIn auk_zerofill Filename of EBD.
auk_zerofill.character <- function(x, sampling_events, species, sep = "\t",
                                   collapse = FALSE,
                                   setclass = c("tbl", "data.frame",
                                                "data.table"), ...) {
  # checks
  assert_that(
    assertthat::is.string(x), file.exists(x),
    assertthat::is.string(sampling_events), file.exists(sampling_events),
    missing(species) || is.character(species),
    assertthat::is.string(sep), nchar(sep) == 1, sep != " ")
  setclass <- match.arg(setclass)
  if (setclass == "data.table" &&
      !requireNamespace("data.table", quietly = TRUE)) {
    stop("data.table package must be installed to return a data.table.")
  }

  # process species names
  # first check for scientific names
  if (!missing(species)) {
    scientific <- species %in% ebird_taxonomy$name_scientific
    # then for common names
    common <- match(species, ebird_taxonomy$name_common)
    common <- ebird_taxonomy$name_scientific[common]
    # convert common names to scientific
    species_clean <- ifelse(scientific, species, common)
    # check all species names are valid
    if (any(is.na(species_clean))) {
      stop(
        paste0("The following species were not found in the eBird taxonomy:",
               "\n\t",
               paste(species[is.na(species_clean)], collapse =", "))
      )
    }
  }

  # read in the two files
  ebd <- read_ebd(x = x, sep = sep, unique = TRUE, setclass = setclass)
  sed <- read_sampling(x = sampling_events, sep = sep, unique = TRUE,
                       setclass = setclass)

  # check that auk_unique has been run
  if (!"checklist_id" %in% names(ebd)) {
    stop("The EBD file doesn't appear to have been run through auk_unique().")
  }
  if (!"checklist_id" %in% names(sed)) {
    stop(paste("The sampling events file doesn't appear to have been run",
               "through auk_unique()."))
  }

  # subset ebd to remove checklist level fields
  species_cols <- c("checklist_id", "scientific_name", "observation_count")
  if (any(!species_cols %in% names(ebd))) {
    stop(
      paste0("The following fields must appear in the EBD: \n\t",
             paste(species_cols, collapse =", "))
    )
  }
  ebd <- ebd[, species_cols]

  # ensure all checklist in ebd are in sampling file
  if (!"checklist_id" %in% names(sed)) {
    stop("The sampling event data file must have a checklist_id field.")
  }
  if (!all(ebd$checklist_id %in% sed$checklist_id)) {
    stop("Some checklists in EBD are missing from sampling event data file.")
  }

  # subset ebd by species
  if (!"scientific_name" %in% names(ebd)) {
    stop("No scientific_name field found in EBD.")
  }
  if (!missing(species)) {
    in_ebd <- (species_clean %in% ebd$scientific_name)
    if (all(!in_ebd)) {
      stop("None of the provided species appear in the EBD.")
    } else if (any(!in_ebd)) {
      warning(
        paste0("The following species were not found in the EBD: \n\t",
               paste(species[!in_ebd], collapse =", "))
      )
    }
    species_clean <- species_clean[in_ebd]
    ebd <- ebd[ebd$scientific_name %in% species_clean, ]
  }

  # add presence absence column
  ebd$species_observed <- ebd$observation_count
  ebd$species_observed[ebd$species_observed == "X"] <- "1"
  ebd$species_observed <- (as.numeric(ebd$species_observed) >= 1)

  # remove absences that may have sneaked through
  # there shouldn't be any of these, but just in case...
  ebd <- ebd[ebd$species_observed == 1, ]

  # fill in implicit missing values
  ebd <- tidyr::complete_(ebd,
                          cols = list(checklist_id = ~ sed$checklist_id,
                                      "scientific_name"),
                          fill = list(observation_count = "0",
                                      species_observed = 0))

  out <- structure(
    list(observations = ebd, sampling_events = sed),
    class = "auk_zerofill"
  )
  # return a data frame?
  if (collapse) {
    return(collapse_zerofill(out))
  } else {
    return(out)
  }
}

#' @export
#' @describeIn auk_zerofill `auk_ebd` object output from [auk_filter()]. Must
#'   have had a sampling event data file set in the original call to
#'   [auk_ebd()].
auk_zerofill.auk_ebd <- function(x, species, sep = "\t",
                                 collapse = FALSE,
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
  auk_zerofill(x = x$output, sampling_events = x$output_sampling,
               sep = sep, setclass = setclass)
}

#' @export
print.auk_zerofill <- function(x, ...) {
  checklists <- nrow(x$sampling_events)
  species <- length(unique(x$observations$scientific_name))
  cat(
    paste0(
      "Zero-filled EBD: ",
      format(checklists, big.mark = ","), " unique checklists, ",
      "for ", format(species, big.mark = ","), " species.\n"
    )
  )
}

#' @rdname auk_zerofill
#' @export
collapse_zerofill <- function(x, setclass = c("tbl", "data.frame",
                                              "data.table")) {
  UseMethod("collapse_zerofill")
}

#' @export
collapse_zerofill.auk_zerofill <- function(x, setclass = c("tbl", "data.frame",
                                                           "data.table")) {
  setclass = match.arg(setclass)
  out <- merge(x$sampling_events, x$observations, by = "checklist_id")
  set_class(out, setclass = setclass)
}
