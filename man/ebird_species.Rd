% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ebird-species.r
\name{ebird_species}
\alias{ebird_species}
\title{Lookup species in eBird taxonomy}
\usage{
ebird_species(x, scientific = TRUE)
}
\arguments{
\item{x}{character; species to look up, provided as scientific or
English common names, or a mixture of both. Case insensitive.}

\item{scientific}{logical; whether to return scientific (\code{TRUE}) or English
common names (\code{FALSE}).}
}
\value{
Character vector of scientific names or common names if names if
\code{scientific = FALSE}.
}
\description{
Given a list of common or scientific names, check that they appear in the
official eBird taxonomy and convert them all to scientific names, or common
names if \code{scientific = FALSE}. Un-matched species are returned as \code{NA}.
}
\examples{
# mix common and scientific names, case-insensitive
species <- c("Blackburnian Warbler", "Poecile atricapillus",
             "american dipper", "Caribou")
# species not in the ebird taxonomy return NA
ebird_species(species)
}
