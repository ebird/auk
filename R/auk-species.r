#' Filter the EBD by species
#'
#' Define a filter for the eBird Basic Dataset (EBD) based on species. This
#' function only defines the filter and, once all filters have been defined,
#' [auk_filter()] should be used to call AWK and perform the filtering.
#'
#' @param x `ebd` object; reference to EBD file created by [auk_ebd()].
#' @param species character; species to filter by, provided as scientific or
#'   common names, or a mixture of both. These names must match the official
#'   eBird Taxomony ([ebird_taxonomy]).
#' @param replace logical; multiple calls to `auk_species()` are additive, unless
#'   `replace = FALSE`, in which case the previous list of species to filter by
#'   will be removed and replaced by that in the current call.
#'
#' @return An `ebd` object.
#' @export
#' @examples
#' # common and scientific names can be mixed
#' species <- c("Gray Jay", "Pluvialis squatarola")
#' system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   auk_ebd() %>%
#'   auk_species(species)
auk_species <- function(x, species, replace)  {
  UseMethod("auk_species")
}

#' @export
auk_species.ebd <- function(x, species, replace = FALSE) {
  # checks
  assert_that(
    is.character(species),
    assertthat::is.flag(replace)
  )

  # first check for scientific names
  scientific <- species %in% ebird_taxonomy$name_scientific
  # then for common names
  common <- match(species, ebird_taxonomy$name_common)
  common <- ebird_taxonomy$name_scientific[common]
  # convert common names to scientific
  species_clean <- ifelse(scientific, species, common)

  # check all species names are valid
  if (any(is.na(species_clean))) {
    paste0("The following species were not found in the eBird taxonomy: \n\t",
           paste(species[is.na(species_clean)], collapse =", ")) %>%
      stop()
  }

  # add species to filter list
  if (replace) {
    x$species_filter <- species_clean
  } else {
    x$species_filter <- c(x$species_filter, species_clean)
  }
  x$species_filter <- c(x$species_filter, species_clean) %>%
    unique() %>%
    sort()
  return(x)
}
