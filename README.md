
<!-- README.md is generated from README.Rmd. Please edit that file -->
auk: an R interface to AWK for manipulating eBird data
======================================================

[eBird](http://www.ebird.org) is an online tool for recording bird observations. The eBird database contains nearly 500 million sightings records making it among the largest citizen science projects in history and an extremely valuable resource for bird research and conservation. eBird provides free access to data through a variety of means. Some data can be accessed through the [eBird API](https://confluence.cornell.edu/display/CLOISAPI/eBird+API+1.1), which has an associated R pacakge [rebird](https://github.com/ropensci/rebird). In addition, the full eBird database is packaged as a text file and available for download as the [eBird Basic Dataset (EBD)](http://ebird.org/ebird/data/download). For most applications in science or conservation, users will require the EBD, however, working with these data can be challenging because of the inherently large file size. This primary function of this R package is to subset the EBD into smaller pieces, which are more easily manipulated in R.

The EBD and AWK
---------------

The EBD is a tab separated text file containing every bird sighting in the eBird database at the time of release. Each row corresponds to a sighting of a single species within a checklist and, in addition to the species and number of individuals observed, information is provided at the checklist level (location, time, date, search effort, etc.). Full metadata on the EBD is provided when the [file is downloaded](http://ebird.org/ebird/data/download). Because eBird contains nearly 500 million sightings, the EBD is an inherently large file (~150 GB uncompressed) and therefore challenging to work with in R.

AWK is a unix utility and programming language for processing column formatted text data. It is highly flexible and extremely fast, making it a valuable tool for pre-processing the EBD. Users of the EBD can use AWK to subset the full text file taxonomically, spatially, or temporally, to produce a smaller file, which can then be loaded in to R for visualization, analysis, and modelling. This package is a wrapper for AWK specifically designed for filtering the EBD. The goal is to ease the use of the EBD by removing the hurdle of learning AWK.

Linux and Mac users should already have AWK installed on their machines, however, Windows uses will need to install [Cygwin](https://www.cygwin.com) to gain access to AWK.

Installation
------------

This package can be installed directly from GitHub with:

``` r
install.packages("devtools")
devtools::install_github("mstrimas/auk")
```

Example usage
-------------

### Cleaning

Some rows in the eBird Basic Dataset (EBD) may have an incorrect number of columns and the dataset has an extra blank column at the end. The function `auk_clean()` drops these erroneous records and removes the blank column.

``` r
library(auk)
# sample data
f <- system.file("extdata/ebd-sample_messy.txt", package="auk")
tmp <- tempfile()
# remove problem runs
auk_clean(f, tmp)
#> [1] "/var/folders/mg/qh40qmqd7376xn8qxd6hm5lwjyy0h2/T//Rtmp6RfbVk/file11b95e4c208f"
# number of lines in input
length(readLines(f))
#> [1] 1001
# number of lines in output
length(readLines(tmp))
#> [1] 997
unlink(tmp)
```

### Filtering

`auk` uses a [pipeline-based workflow](http://r4ds.had.co.nz/pipes.html) for defining filters, which can be compiled into an AWK script. Users should start by defining a reference to the EBD file with `auk_ebd()`. Then the following filters can be applied:

-   `auk_species()`: filter by species using common or scientific names.
-   `auk_country()`: filter by country using the standard Engligh name or [ISO 2-letter country codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
-   `auk_extent()`: filter by spatial extent, i.e. a range of latitudes and longitudes.
-   `auk_date()`: filter to checklists from a range of dates
-   `auk_time()`: filter to checklists started during a range of times.
-   `auk_duration()`: filter to checklists that lasted a given length of time.
-   `auk_complete()`: only retain checklists in which the observer has specified that they recorded all species seen or heard. These records are the most useful for modelling because they provide both presence and absenced data.

``` r
# sample data
f <- system.file("extdata/ebd-sample.txt", package="auk")
# define an EBD reference and a set of filters
ebd <- auk_ebd(f) %>% 
  # species: common and scientific names can be mixed
  auk_species(species = c("Gray Jay", "Cyanocitta cristata")) %>%
  # country: codes and names can be mixed; case insensitive
  auk_country(country = c("US", "Canada", "mexico")) %>%
  # extent: formatted as `c(lng_min, lat_min, lng_max, lat_max)`
  auk_extent(extent = c(-100, 37, -80, 52)) %>%
  # date: use standard ISO date format `"YYYY-MM-DD"`
  auk_date(date = c("2012-01-01", "2012-12-31")) %>%
  # time: 24h format
  auk_time(time = c("06:00", "09:00")) %>%
  # duration: length in minutes of checklists
  auk_duration(duration = c(0, 60)) %>%
  # complete: all species seen or heard are recorded
  auk_complete()
ebd
#> eBird Basic Dataset (EBD): 
#> /Library/Frameworks/R.framework/Versions/3.3/Resources/library/auk/extdata/ebd-sample.txt
#> 
#> Filters: 
#> Species: Cyanocitta cristata, Perisoreus canadensis
#> Countries: CA, MX, US
#> Spatial extent: Lat -100 - -80; Lon 37 - 52
#> Date: 2012-01-01 - 2012-12-31
#> Time: 06:00-09:00
#> Duration: 0-60 minutes
#> Complete checklists only: yes
```

In all cases, checks are performed to ensure filters are valid. For example, species are checked against the official [eBird taxonomy](http://help.ebird.org/customer/portal/articles/1006825-the-ebird-taxonomy) and countries are checked using the [`countrycode`](https://github.com/vincentarelbundock/countrycode) package.

Each of these functions only defines the filter. `auk_filter()` should be used to compile all the filters into an AWK script and execute it to produce an output file. So, bringing all this together, one could, for example, extract all Gray Jay and Blue Jay records from Canada with:

``` r
tmp <- tempfile()
ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>% 
  auk_ebd() %>% 
  auk_species(species = c("Gray Jay", "Cyanocitta cristata")) %>% 
  auk_country(country = "Canada") %>% 
  auk_filter(file = tmp) %>% 
  read.delim(quote = "")
str(ebd)
#> 'data.frame':    50 obs. of  46 variables:
#>  $ GLOBAL.UNIQUE.IDENTIFIER  : Factor w/ 50 levels "URN:CornellLabOfOrnithology:EBIRD:OBS102848882",..: 11 8 42 27 23 28 26 4 5 13 ...
#>  $ LAST.EDITED.DATE          : Factor w/ 48 levels "2011-12-19 11:44:05",..: 41 4 27 35 40 19 43 3 18 2 ...
#>  $ TAXONOMIC.ORDER           : int  18831 18831 18831 18831 18831 18831 18831 18831 18831 18831 ...
#>  $ CATEGORY                  : Factor w/ 1 level "species": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ COMMON.NAME               : Factor w/ 2 levels "Blue Jay","Gray Jay": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ SCIENTIFIC.NAME           : Factor w/ 2 levels "Cyanocitta cristata",..: 1 1 1 1 1 1 1 1 1 1 ...
#>  $ SUBSPECIES.COMMON.NAME    : logi  NA NA NA NA NA NA ...
#>  $ SUBSPECIES.SCIENTIFIC.NAME: logi  NA NA NA NA NA NA ...
#>  $ OBSERVATION.COUNT         : Factor w/ 18 levels "1","10","11",..: 11 1 1 5 18 4 7 1 12 9 ...
#>  $ BREEDING.BIRD.ATLAS.CODE  : logi  NA NA NA NA NA NA ...
#>  $ AGE.SEX                   : Factor w/ 1 level "Unknown Sex, Adult (1)": NA NA NA NA NA NA NA NA NA NA ...
#>  $ COUNTRY                   : Factor w/ 1 level "Canada": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ COUNTRY.CODE              : Factor w/ 1 level "CA": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ STATE                     : Factor w/ 8 levels "Alberta","British Columbia",..: 6 6 6 5 6 6 6 6 6 6 ...
#>  $ STATE.CODE                : Factor w/ 8 levels "CA-AB","CA-BC",..: 6 6 6 5 6 6 6 6 6 6 ...
#>  $ COUNTY                    : Factor w/ 34 levels "Bruce","Calgary",..: 32 21 9 19 8 10 18 34 23 11 ...
#>  $ COUNTY.CODE               : Factor w/ 35 levels "CA-AB-EL","CA-AB-FT",..: 27 19 14 10 13 15 16 29 20 26 ...
#>  $ IBA.CODE                  : Factor w/ 7 levels "CA-BC_035","CA-NB_011",..: 5 3 NA NA 4 NA 6 NA NA NA ...
#>  $ BCR.CODE                  : int  13 13 12 14 NA 13 NA 13 13 12 ...
#>  $ USFWS.CODE                : logi  NA NA NA NA NA NA ...
#>  $ ATLAS.BLOCK               : logi  NA NA NA NA NA NA ...
#>  $ LOCALITY                  : Factor w/ 43 levels "156 McInnis Road",..: 23 29 13 1 30 14 4 38 32 41 ...
#>  $ LOCALITY.ID               : Factor w/ 43 levels "L1025043","L1078677",..: 20 8 25 14 34 13 31 6 42 3 ...
#>  $ LOCALITY.TYPE             : Factor w/ 3 levels "H","P","T": 1 2 2 2 1 1 1 2 2 2 ...
#>  $ LATITUDE                  : num  43.9 44 44.6 44.6 41.8 ...
#>  $ LONGITUDE                 : num  -80.4 -77.7 -76.6 -64.3 -82.7 ...
#>  $ OBSERVATION.DATE          : Factor w/ 49 levels "2010-04-17","2010-06-01",..: 20 16 35 37 31 38 36 9 10 19 ...
#>  $ TIME.OBSERVATIONS.STARTED : Factor w/ 30 levels "06:00:00","06:45:00",..: 30 23 12 7 1 13 11 24 15 8 ...
#>  $ OBSERVER.ID               : Factor w/ 42 levels "obsr108915","obsr113953",..: 14 16 29 35 10 32 5 38 42 19 ...
#>  $ FIRST.NAME                : Factor w/ 39 levels "Abuti","Algonquin Park Bird Records",..: 17 20 22 16 19 10 23 36 32 13 ...
#>  $ LAST.NAME                 : Factor w/ 41 levels "Barden","Berlinguette",..: 40 32 10 29 7 18 14 6 3 26 ...
#>  $ SAMPLING.EVENT.IDENTIFIER : Factor w/ 50 levels "S10060058","S10066679",..: 48 45 29 14 10 15 13 41 42 50 ...
#>  $ PROTOCOL.TYPE             : Factor w/ 3 levels "eBird - Stationary Count",..: 2 2 1 1 2 2 1 1 2 1 ...
#>  $ PROJECT.CODE              : Factor w/ 3 levels "EBIRD","EBIRD_CAN",..: 2 2 1 1 2 1 1 2 1 2 ...
#>  $ DURATION.MINUTES          : int  45 30 25 15 45 60 4 10 60 45 ...
#>  $ EFFORT.DISTANCE.KM        : num  1 0.2 NA NA 25 1.5 NA NA 8 NA ...
#>  $ EFFORT.AREA.HA            : logi  NA NA NA NA NA NA ...
#>  $ NUMBER.OBSERVERS          : int  1 5 1 1 3 1 1 2 1 1 ...
#>  $ ALL.SPECIES.REPORTED      : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ GROUP.IDENTIFIER          : Factor w/ 11 levels "G1066328","G1066396",..: NA 7 2 NA 8 NA NA 6 NA NA ...
#>  $ HAS.MEDIA                 : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ APPROVED                  : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ REVIEWED                  : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ REASON                    : logi  NA NA NA NA NA NA ...
#>  $ TRIP.COMMENTS             : Factor w/ 17 levels "<br />Submitted from BirdLog NA for iOS, version 1.5.1",..: NA 4 NA 17 5 NA 11 7 NA NA ...
#>  $ SPECIES.COMMENTS          : Factor w/ 2 levels "calling","first ones here in months": NA NA NA NA NA NA NA NA NA NA ...
unlink(tmp)
```

### Reading

Not yet implemented...

Acknowledgements
----------------

This package is based on the AWK scripts provided in a presentation given by Daniel Fink, Wesley Hochachka, Tom Auer, and Frank La Sorte at the 2016 NAOC eBird Data Workshop on August 15, 2016.

References
----------

    eBird Basic Dataset. Version: ebd_relFeb-2017. Cornell Lab of Ornithology, Ithaca, New York. May 2013.
