#' Filter the EBD by country
#'
#' Define a filter for the eBird Basic Dataset (EBD) based on a set of
#' countries. This function only defines the filter and, once all filters have
#' been defined, [auk_filter()] should be used to call AWK and perform the
#' filtering.
#'
#' @param x `ebd` object; reference to EBD file created by [auk_ebd()].
#' @param country character; countries to filter by. Countries can either be
#'   expressed as English names or [ISO 2-letter country
#'   codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). English names are
#'   matched via regular expressions using [countrycode][countrycode()], so
#'   there is some flexibility in names.
#' @param replace logical; multiple calls to `auk_country()` are additive,
#'   unless `replace = FALSE`, in which case the previous list of countries to
#'   filter by will be removed and replaced by that in the current call.
#'
#' @return An `ebd` object.
#' @export
#' @examples
#' # country names and ISO2 codes can be mixed
#' # not case sensitive
#' country <- c("CA", "United States", "mexico")
#' system.file("extdata/ebd-sample.txt", package="auk") %>%
#'   auk_ebd() %>%
#'   auk_country(country)
auk_country <- function(x, country, replace)  {
  UseMethod("auk_country")
}

#' @export
auk_country.ebd <- function(x, country, replace = FALSE) {
  # checks
  assert_that(
    is.character(country),
    assertthat::is.flag(replace)
  )

  # split into names and 2-letter codes
  country_split <- split(country, ifelse(nchar(country) == 2, "code", "name"))

  # convert country names to codes
  name_codes <- countrycode::countrycode(country_split$name,
                                         origin = "country.name",
                                         destination = "iso2c",
                                         warn = FALSE)
  # check all countries are valid
  if (any(is.na(name_codes))) {
    paste0("The following country names are invalid: \n\t",
           paste(country_split$name[is.na(name_codes)], collapse =", ")) %>%
      stop()
  }
  country_codes <- c(name_codes, country_split$code)

  # check codes are valid
  valid_codes <- country_codes %in% countrycode::countrycode_data$iso2c
  if (!all(valid_codes)) {
    paste0("The following country codes are invalid: \n\t",
           paste(country_codes[!valid_codes], collapse =", ")) %>%
      stop()
  }

  # add countries to filter list
  if (replace) {
    x$country_filter <- country_codes
  } else {
    x$country_filter <- c(x$country_filter, country_codes)
  }
  x$country_filter <- c(x$country_filter, country_codes) %>%
    unique() %>%
    sort()
  return(x)
}
