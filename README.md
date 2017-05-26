
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
#> [1] "/var/folders/mg/qh40qmqd7376xn8qxd6hm5lwjyy0h2/T//RtmpHbZeZ0/file8397b46c42e"
# number of lines in input
length(readLines(f))
#> [1] 1001
# number of lines in output
length(readLines(tmp))
#> [1] 996
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
  read_ebd()
#> # A tibble: 1,000 x 46
#>                          global_unique_identifier    last_edited_date
#>                                             <chr>              <dttm>
#>  1 URN:CornellLabOfOrnithology:EBIRD:OBS172901271 2012-12-17 11:04:03
#>  2 URN:CornellLabOfOrnithology:EBIRD:OBS118712387 2011-10-04 15:40:47
#>  3 URN:CornellLabOfOrnithology:EBIRD:OBS155256467 2015-08-08 21:02:47
#>  4 URN:CornellLabOfOrnithology:EBIRD:OBS284448755 2016-08-11 09:14:19
#>  5 URN:CornellLabOfOrnithology:EBIRD:OBS420415441 2016-07-27 17:42:10
#>  6 URN:CornellLabOfOrnithology:EBIRD:OBS150662526 2013-11-23 11:07:30
#>  7 URN:CornellLabOfOrnithology:EBIRD:OBS134228541 2011-12-27 20:12:55
#>  8 URN:CornellLabOfOrnithology:EBIRD:OBS118726549 2017-01-12 21:14:23
#>  9 URN:CornellLabOfOrnithology:EBIRD:OBS420402930 2016-07-30 20:30:22
#> 10 URN:CornellLabOfOrnithology:EBIRD:OBS100358984 2014-02-17 17:35:52
#> # ... with 990 more rows, and 44 more variables: taxonomic_order <dbl>,
#> #   category <chr>, common_name <chr>, scientific_name <chr>,
#> #   subspecies_common_name <chr>, subspecies_scientific_name <chr>,
#> #   observation_count <chr>, breeding_bird_atlas_code <chr>,
#> #   age_sex <chr>, country <chr>, country_code <chr>, state <chr>,
#> #   state_code <chr>, county <chr>, county_code <chr>, iba_code <chr>,
#> #   bcr_code <int>, usfws_code <chr>, atlas_block <chr>, locality <chr>,
#> #   locality_id <chr>, locality_type <chr>, latitude <dbl>,
#> #   longitude <dbl>, observation_date <date>,
#> #   time_observations_started <chr>, observer_id <chr>, first_name <chr>,
#> #   last_name <chr>, sampling_event_identifier <chr>, protocol_type <chr>,
#> #   project_code <chr>, duration_minutes <int>, effort_distance_km <dbl>,
#> #   effort_area_ha <dbl>, number_observers <int>,
#> #   all_species_reported <lgl>, group_identifier <chr>, has_media <lgl>,
#> #   approved <lgl>, reviewed <lgl>, reason <chr>, trip_comments <chr>,
#> #   species_comments <chr>
```

By default, `read_ebd()` returns a tibble for use with [Tidyverse](http://tidyverse.org) packages. Tibbles will behave just like plain data frames in most instances, but users can choose to return a plain `data.frame` or `data.table` by using the `setclass` argument.

``` r
system.file("extdata/ebd-sample.txt", package="auk") %>% 
  read_ebd(setclass = "data.frame") %>% 
  str()
#> 'data.frame':    1000 obs. of  46 variables:
#>  $ global_unique_identifier  : chr  "URN:CornellLabOfOrnithology:EBIRD:OBS172901271" "URN:CornellLabOfOrnithology:EBIRD:OBS118712387" "URN:CornellLabOfOrnithology:EBIRD:OBS155256467" "URN:CornellLabOfOrnithology:EBIRD:OBS284448755" ...
#>  $ last_edited_date          : POSIXct, format: "2012-12-17 11:04:03" "2011-10-04 15:40:47" ...
#>  $ taxonomic_order           : num  18772 18772 18816 18825 18772 ...
#>  $ category                  : chr  "species" "species" "species" "issf" ...
#>  $ common_name               : chr  "Green Jay" "Green Jay" "Steller's Jay" "Steller's Jay" ...
#>  $ scientific_name           : chr  "Cyanocorax yncas" "Cyanocorax yncas" "Cyanocitta stelleri" "Cyanocitta stelleri" ...
#>  $ subspecies_common_name    : chr  NA NA NA "Steller's Jay (Central American)" ...
#>  $ subspecies_scientific_name: chr  NA NA NA "Cyanocitta stelleri [coronata Group]" ...
#>  $ observation_count         : chr  "2" "2" "3" "6" ...
#>  $ breeding_bird_atlas_code  : chr  NA NA NA NA ...
#>  $ age_sex                   : chr  NA NA NA NA ...
#>  $ country                   : chr  "Mexico" "Mexico" "Mexico" "Mexico" ...
#>  $ country_code              : chr  "MX" "MX" "MX" "MX" ...
#>  $ state                     : chr  "Quintana Roo" "Guerrero" "Chiapas" "Oaxaca" ...
#>  $ state_code                : chr  "MX-ROO" "MX-GRO" "MX-CHP" "MX-OAX" ...
#>  $ county                    : chr  NA NA NA NA ...
#>  $ county_code               : chr  NA NA NA NA ...
#>  $ iba_code                  : chr  NA NA NA "MX_220-1" ...
#>  $ bcr_code                  : int  56 53 58 54 55 36 NA 53 55 NA ...
#>  $ usfws_code                : chr  NA NA NA NA ...
#>  $ atlas_block               : chr  NA NA NA NA ...
#>  $ locality                  : chr  "Carbonell home" "Sierra de Atoyac--K35.1 from Paraiso, 17.48259, -100.19756" "Carretera a Ocosingo antes del desvío para el Aeropuerto" "Carretera 175/Oaxaca-Tuxtepec--Km 100-105" ...
#>  $ locality_id               : chr  "L1824974" "L1167323" "L1413679" "L282533" ...
#>  $ locality_type             : chr  "P" "P" "P" "H" ...
#>  $ latitude                  : num  21.1 17.5 16.7 17.6 21.3 ...
#>  $ longitude                 : num  -86.8 -100.2 -92.5 -96.5 -89.1 ...
#>  $ observation_date          : Date, format: "2012-12-17" "2011-03-23" ...
#>  $ time_observations_started : chr  "07:52:00" "11:34:00" "07:50:00" "07:30:00" ...
#>  $ observer_id               : chr  "obsr285176" "obsr50351" "obsr47545" "obsr205067" ...
#>  $ first_name                : chr  "Enric" "Charlie" "Francesca" "Alan" ...
#>  $ last_name                 : chr  "Fernandez" "Wright" "Albini" "Knue" ...
#>  $ sampling_event_identifier : chr  "S12309968" "S8259073" "S10904198" "S17567450" ...
#>  $ protocol_type             : chr  "eBird - Traveling Count" "eBird - Stationary Count" "eBird - Traveling Count" "eBird - Traveling Count" ...
#>  $ project_code              : chr  "EBIRD" "EBIRD" "EBIRD" "EBIRD" ...
#>  $ duration_minutes          : int  105 26 90 80 30 60 15 45 30 70 ...
#>  $ effort_distance_km        : num  0.499 NA 1.5 4.828 NA ...
#>  $ effort_area_ha            : num  NA NA NA NA NA ...
#>  $ number_observers          : int  1 3 2 2 1 2 2 3 1 2 ...
#>  $ all_species_reported      : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
#>  $ group_identifier          : chr  NA "G262032" NA "G1248347" ...
#>  $ has_media                 : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
#>  $ approved                  : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
#>  $ reviewed                  : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
#>  $ reason                    : chr  NA NA NA NA ...
#>  $ trip_comments             : chr  "<br />Submitted from BirdLog CA for iOS, version 1.5.1" "Butterfly clusters found and photographed." "My last visit to this spot was almost three months ago. Pink-headed Warblers successfully bred meanwhile, as independent young "| __truncated__ NA ...
#>  $ species_comments          : chr  NA NA NA NA ...
```

Acknowledgements
----------------

This package is based on the AWK scripts provided in a presentation given by Wesley Hochachka, Daniel Fink, Tom Auer, and Frank La Sorte at the 2016 NAOC eBird Data Workshop on August 15, 2016.

References
----------

    eBird Basic Dataset. Version: ebd_relFeb-2017. Cornell Lab of Ornithology, Ithaca, New York. May 2013.
