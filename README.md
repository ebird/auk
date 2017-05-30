
<!-- README.md is generated from README.Rmd. Please edit that file -->
auk: an R interface to AWK for manipulating eBird data
======================================================

[![Travis-CI Build Status](https://travis-ci.org/mstrimas/auk.svg?branch=master)](https://travis-ci.org/mstrimas/auk)

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
#> [1] "/var/folders/mg/qh40qmqd7376xn8qxd6hm5lwjyy0h2/T//RtmpVTVgpY/filebe34b946d6c"
# number of lines in input
length(readLines(f))
#> [1] 1001
# number of lines in output
length(readLines(tmp))
#> [1] 4
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
  auk_filter(file = tmp)
unlink(tmp)
```

### Reading

EBD files can be read with `read_ebd()`, a wrapper around `readr::read_delim()`, that uses `stringsAsFactors = FALSE`, `quote = ""`, sets column classes, and converts variable names to `snake_case`.

``` r
system.file("extdata/ebd-sample.txt", package="auk") %>% 
  read_ebd() %>% 
  str()
#> Classes 'tbl_df', 'tbl' and 'data.frame':    974 obs. of  46 variables:
#>  $ global_unique_identifier  : chr  "URN:CornellLabOfOrnithology:EBIRD:OBS169024777" "URN:CornellLabOfOrnithology:EBIRD:OBS173096361" "URN:CornellLabOfOrnithology:EBIRD:OBS201605886" "URN:CornellLabOfOrnithology:EBIRD:OBS169955140" ...
#>  $ last_edited_date          : POSIXct, format: "2013-04-01 14:01:21" "2016-02-11 09:57:31" ...
#>  $ taxonomic_order           : int  18772 18772 18772 18772 18772 18772 18772 18772 18772 18772 ...
#>  $ category                  : chr  "species" "species" "species" "species" ...
#>  $ common_name               : chr  "Green Jay" "Green Jay" "Green Jay" "Green Jay" ...
#>  $ scientific_name           : chr  "Cyanocorax yncas" "Cyanocorax yncas" "Cyanocorax yncas" "Cyanocorax yncas" ...
#>  $ subspecies_common_name    : chr  NA NA NA NA ...
#>  $ subspecies_scientific_name: chr  NA NA NA NA ...
#>  $ observation_count         : chr  "9" "2" "2" "8" ...
#>  $ breeding_bird_atlas_code  : chr  NA NA NA NA ...
#>  $ age_sex                   : chr  NA NA NA NA ...
#>  $ country                   : chr  "Mexico" "Belize" "Mexico" "Mexico" ...
#>  $ country_code              : chr  "MX" "BZ" "MX" "MX" ...
#>  $ state                     : chr  "Tamaulipas" "Cayo" "Chiapas" "Tamaulipas" ...
#>  $ state_code                : chr  "MX-TAM" "BZ-CY" "MX-CHP" "MX-TAM" ...
#>  $ county                    : chr  NA NA NA NA ...
#>  $ county_code               : chr  NA NA NA NA ...
#>  $ iba_code                  : chr  NA NA NA NA ...
#>  $ bcr_code                  : int  36 NA 60 36 NA 60 60 56 60 65 ...
#>  $ usfws_code                : chr  NA NA NA NA ...
#>  $ atlas_block               : chr  NA NA NA NA ...
#>  $ locality                  : chr  "Mexico--across from Salineno" "Mountain Pine Ridge, Bradley Rd east" "Berlin2_Punto_06" "La Gloria--a Través de Salineño" ...
#>  $ locality_id               : chr  "L1800752" "L1109683" "L2224225" "L448149" ...
#>  $ locality_type             : chr  "P" "P" "P" "H" ...
#>  $ latitude                  : num  26.5 17 15.8 26.5 17 ...
#>  $ longitude                 : num  -99.1 -88.8 -93 -99.1 -88.8 ...
#>  $ observation_date          : Date, format: "2012-11-09" "2011-03-06" ...
#>  $ time_observations_started : chr  "07:20:00" "11:55:00" "08:00:00" "07:30:00" ...
#>  $ observer_id               : chr  "obsr131249" "obsr247125" "obsr313215" "obsr290731" ...
#>  $ first_name                : chr  "Joe" "Roni" "MONITORES COMUNITARIOS" "Barbara" ...
#>  $ last_name                 : chr  "Removed" "Removed" "Removed" "Removed" ...
#>  $ sampling_event_identifier : chr  "S11996405" "S12322996" "S14432467" "S12063163" ...
#>  $ protocol_type             : chr  "eBird - Stationary Count" "eBird - Stationary Count" "eBird - Traveling Count" "eBird - Stationary Count" ...
#>  $ project_code              : chr  "EBIRD" "EBIRD" "EBIRD_MEX" "EBIRD" ...
#>  $ duration_minutes          : int  110 20 10 80 20 10 10 95 18 90 ...
#>  $ effort_distance_km        : num  NA NA 0.257 NA NA ...
#>  $ effort_area_ha            : num  NA NA NA NA NA NA NA NA NA NA ...
#>  $ number_observers          : int  40 4 1 42 4 1 1 15 1 2 ...
#>  $ all_species_reported      : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
#>  $ group_identifier          : chr  NA NA NA "G487002" ...
#>  $ has_media                 : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
#>  $ approved                  : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
#>  $ reviewed                  : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
#>  $ reason                    : chr  NA NA NA NA ...
#>  $ trip_comments             : chr  NA "With Lee Jones and Wayne Hall" "Alonso Gomez Hdz Monitoreo Comunitario, Transectos en Bosque de Pino Encino, La Concordia,1098 msnm" "Rio Grande Valley Birding Festival - Upper Rio Trip. Leaders: Rich Hoyer, Richard Gibbons, Michael Marsden, and Cole Wolf. Chec"| __truncated__ ...
#>  $ species_comments          : chr  NA NA NA NA ...
#>  - attr(*, ".internal.selfref")=<externalptr>
```

By default, `read_ebd()` returns a tibble for use with [Tidyverse](http://tidyverse.org) packages. Tibbles will behave just like plain data frames in most instances, but users can choose to return a plain `data.frame` or `data.table` by using the `setclass` argument.

``` r
ebd_df <- system.file("extdata/ebd-sample.txt", package="auk") %>% 
  read_ebd(setclass = "data.frame")
```

Acknowledgements
----------------

This package is based on the AWK scripts provided in a presentation given by Wesley Hochachka, Daniel Fink, Tom Auer, and Frank La Sorte at the 2016 NAOC eBird Data Workshop on August 15, 2016.

References
----------

    eBird Basic Dataset. Version: ebd_relFeb-2017. Cornell Lab of Ornithology, Ithaca, New York. May 2013.
