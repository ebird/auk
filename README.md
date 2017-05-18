
<!-- README.md is generated from README.Rmd. Please edit that file -->
rawk: an R interface to awk for manipulating eBird data
=======================================================

[eBird](http://www.ebird.org) is an online tool for recording bird observations. The eBird database contains nearly 500 million sightings records making it among the largest citizen science projects in history and an extremely valuable resource for bird research and conservation. eBird provides free access to data through a variety of means. Some data can be accessed through the [eBird API](https://confluence.cornell.edu/display/CLOISAPI/eBird+API+1.1), which has an associated R pacakge [rebird](https://github.com/ropensci/rebird). In addition, the full eBird database is packaged as a text file and available for download as the [eBird Basic Dataset (EBD)](http://ebird.org/ebird/data/download). For most applications in science or conservation, users will require the EBD, however, working with these data can be challenging because of the inherently large file size. This primary function of this R package is to subset the EBD into smaller pieces, which are more easily manipulated in R.

The EBD and AWK
---------------

The EBD is a tab separated text file containing every bird sighting in the eBird database. Each row corresponds to a sighting of a single species within a checklist and, in addition to the species and number of individuals observed, information is provided at the checklist level (location, time, date, search effort, etc.). Full metadata on the EBD is provided when the [file is downloaded](http://ebird.org/ebird/data/download). Because eBird contains nearly 500 million sightings, the EBD is an inherently large file (~150 GB uncompressed) and therefore challenging to work with in R.

AWK is a unix utility and programming language for processing column formatted text data. It is highly flexible and extremely fast, making it a valuable tool for pre-processing the EBD. Users of the EBD can use AWK to subset the full text file taxonomically, spatially, or temporally, to produce a smaller file, which can then be loaded in to R for visualization, analysis, and modelling. This package is a wrapper for AWK specifically designed for filtering the EBD. The goal is to ease the use of the EBD by removing the hurdle of learning AWK.

Linux and Mac users should already have AWK installed on their machines, however, Windows uses will need to install [Cygwin](https://www.cygwin.com) to gain access to AWK.

Installation
------------

This package can be installed directly from GitHub with:

``` r
install.packages("devtools")
devtools::install_github("ropensci/rebird")
```

Example usage
-------------

### Cleaning

Some rows in the eBird Basic Dataset (EBD) may have an incorrect number of columns. The function `rawk_clean()` drops these erroneous records.

``` r
library(rawk)
#> Looking for a valid awk install:
# sample data
f <- system.file("extdata/ebd-sample_messy.txt", package="rawk")
tmp <- tempfile()
# remove problem runs
rawk_clean(f, tmp)
#> [1] "/var/folders/mg/qh40qmqd7376xn8qxd6hm5lwjyy0h2/T//RtmpVF2F4S/file14ac31b6115e7"
# number of lines in input
length(readLines(f))
#> [1] 1001
# number of lines in output
length(readLines(tmp))
#> [1] 996
unlink(tmp)
```

### Filtering

`rawk` uses a [pipeline-based workflow](http://r4ds.had.co.nz/pipes.html) for defining filters, which can be compiled into an AWK script. Users should start by defining a reference to the EBD file with `rawk_ebd()`. Then the following filters can be applied:

-   `rawk_species()`: filter by species using common or scientific names.
-   `rawk_country()`: filter by country using the standard Engligh name or [ISO 2-letter country codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
-   `rawk_extent()`: filter by spatial extent, i.e. a range of latitudes and longitudes.
-   `rawk_date()`: filter to checklists from a range of dates
-   `rawk_time()`: filter to checklists started during a range of times.
-   `rawk_duration()`: filter to checklists that lasted a given length of time.
-   `rawk_complete()`: only retain checklists in which the observer has specified that they recorded all species seen or heard. These records are the most useful for modelling because they provide both presence and absenced data.

``` r
# sample data
f <- system.file("extdata/ebd-sample.txt", package="rawk")
# define an EBD reference and a set of filters
ebd <- rawk_ebd(f) %>% 
  # species: common and scientific names can be mixed
  rawk_species(species = c("Gray Jay", "Cyanocitta cristata")) %>%
  # country: codes and names can be mixed; case insensitive
  rawk_country(country = c("US", "Canada", "mexico")) %>%
  # extent: formatted as `c(lng_min, lat_min, lng_max, lat_max)`
  rawk_extent(extent = c(-125, 37, -120, 52)) %>%
  # date: use standard ISO date format `"YYYY-MM-DD"`
  rawk_date(date = c("2010-01-01", "2010-12-31")) %>%
  # time: 24h format
  rawk_time(time = c("06:00", "08:00")) %>%
  # duration: length in minutes of checklists
  rawk_duration(duration = c(0, 60)) %>%
  # complete: all species seen or heard are recorded
  rawk_complete()
ebd
#> eBird Basic Dataset (EBD): 
#> /Library/Frameworks/R.framework/Versions/3.3/Resources/library/rawk/extdata/ebd-sample.txt
#> 
#> Filters: 
#> Species: Cyanocitta cristata, Perisoreus canadensis
#> Countries: CA, MX, US
#> Spatial extent: Lat -125 – -120; Lon 37 – 52
#> Date: 2010-01-01–2010-12-31
#> Time: 06:00–08:00
#> Duration: 0–60 minutes
#> Complete checklists only: yes
```

In all cases, checks are performed to ensure filters are valid. For example, species are checked against the official [eBird taxonomy](http://help.ebird.org/customer/portal/articles/1006825-the-ebird-taxonomy) and countries are checked using the [`countrycode`](https://github.com/vincentarelbundock/countrycode) package.

Each of these functions only defines the filter. `rawk_filter()` should be used to compile all the filters into an AWK script and execute it to produce an output file. So, bringing all this together, one could, for example, extract all Gray Jay and Blue Jay records from Canada with:

``` r
tmp <- tempfile()
ebd <- system.file("extdata/ebd-sample.txt", package="rawk") %>% 
  rawk_ebd() %>% 
  rawk_species(species = c("Gray Jay", "Cyanocitta cristata")) %>% 
  rawk_country(country = "Canada") %>% 
  rawk_filter(file = tmp) %>% 
  read.delim(quote = "")
str(ebd)
#> 'data.frame':    152 obs. of  47 variables:
#>  $ GLOBAL.UNIQUE.IDENTIFIER  : Factor w/ 152 levels "URN:CornellLabOfOrnithology:EBIRD:OBS117135389",..: 79 74 81 75 77 80 76 78 83 72 ...
#>  $ LAST.EDITED.DATE          : Factor w/ 22 levels "2008-04-29 20:57:25",..: 7 7 7 7 7 7 7 7 7 7 ...
#>  $ TAXONOMIC.ORDER           : num  4078 277 18722 561 3805 ...
#>  $ CATEGORY                  : Factor w/ 2 levels "domestic","species": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ COMMON.NAME               : Factor w/ 96 levels "American Bittern",..: 70 21 43 74 12 48 19 85 49 33 ...
#>  $ SCIENTIFIC.NAME           : Factor w/ 96 levels "Actitis macularius",..: 15 10 64 55 69 48 12 1 35 65 ...
#>  $ SUBSPECIES.COMMON.NAME    : Factor w/ 2 levels "","Rock Pigeon (Feral Pigeon)": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ SUBSPECIES.SCIENTIFIC.NAME: Factor w/ 2 levels "","Columba livia (Feral Pigeon)": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ OBSERVATION.COUNT         : Factor w/ 22 levels "1","10","100",..: 10 10 7 16 1 2 1 1 7 3 ...
#>  $ BREEDING.BIRD.ATLAS.CODE  : logi  NA NA NA NA NA NA ...
#>  $ AGE.SEX                   : logi  NA NA NA NA NA NA ...
#>  $ COUNTRY                   : Factor w/ 2 levels "Canada","United States": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ COUNTRY.CODE              : Factor w/ 2 levels "CA","US": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ STATE                     : Factor w/ 14 levels "British Columbia",..: 13 13 13 13 13 13 13 13 13 13 ...
#>  $ STATE.CODE                : Factor w/ 14 levels "CA-BC","CA-MB",..: 6 6 6 6 6 6 6 6 6 6 ...
#>  $ COUNTY                    : Factor w/ 20 levels "Capital","Digby",..: 11 11 11 11 11 11 11 11 11 11 ...
#>  $ COUNTY.CODE               : Factor w/ 20 levels "CA-BC-CP","CA-BC-FV",..: 11 11 11 11 11 11 11 11 11 11 ...
#>  $ IBA.CODE                  : Factor w/ 3 levels "","US-IN_2539",..: 1 1 1 1 1 1 1 1 1 1 ...
#>  $ BCR.CODE                  : int  NA NA NA NA NA NA NA NA NA NA ...
#>  $ USFWS.CODE                : Factor w/ 2 levels "","USFWS_452": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ ATLAS.BLOCK               : logi  NA NA NA NA NA NA ...
#>  $ LOCALITY                  : Factor w/ 21 levels "A. J. Henry Park",..: 17 17 17 17 17 17 17 17 17 17 ...
#>  $ LOCALITY.ID               : Factor w/ 21 levels "L142947","L1452852",..: 13 13 13 13 13 13 13 13 13 13 ...
#>  $ LOCALITY.TYPE             : Factor w/ 3 levels "H","P","T": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ LATITUDE                  : num  49.1 49.1 49.1 49.1 49.1 ...
#>  $ LONGITUDE                 : num  -68.2 -68.2 -68.2 -68.2 -68.2 ...
#>  $ OBSERVATION.DATE          : Factor w/ 24 levels "1961-06-20","1966-07-19",..: 6 6 6 6 6 6 6 6 6 6 ...
#>  $ TIME.OBSERVATIONS.STARTED : Factor w/ 13 levels "","00:00:00",..: 9 9 9 9 9 9 9 9 9 9 ...
#>  $ OBSERVER.ID               : Factor w/ 20 levels "obsr11103","obsr131848",..: 14 14 14 14 14 14 14 14 14 14 ...
#>  $ FIRST.NAME                : Factor w/ 20 levels "Burke","Christian",..: 6 6 6 6 6 6 6 6 6 6 ...
#>  $ LAST.NAME                 : Factor w/ 20 levels "Baxter","Biss",..: 6 6 6 6 6 6 6 6 6 6 ...
#>  $ SAMPLING.EVENT.IDENTIFIER : Factor w/ 24 levels "S1018166","S10305211",..: 13 13 13 13 13 13 13 13 13 13 ...
#>  $ PROTOCOL.TYPE             : Factor w/ 4 levels "eBird - Casual Observation",..: 2 2 2 2 2 2 2 2 2 2 ...
#>  $ PROJECT.CODE              : Factor w/ 3 levels "EBIRD","EBIRD_CAN",..: 2 2 2 2 2 2 2 2 2 2 ...
#>  $ DURATION.MINUTES          : int  60 60 60 60 60 60 60 60 60 60 ...
#>  $ EFFORT.DISTANCE.KM        : num  NA NA NA NA NA NA NA NA NA NA ...
#>  $ EFFORT.AREA.HA            : num  NA NA NA NA NA NA NA NA NA NA ...
#>  $ NUMBER.OBSERVERS          : int  2 2 2 2 2 2 2 2 2 2 ...
#>  $ ALL.SPECIES.REPORTED      : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ GROUP.IDENTIFIER          : logi  NA NA NA NA NA NA ...
#>  $ HAS.MEDIA                 : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ APPROVED                  : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ REVIEWED                  : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ REASON                    : logi  NA NA NA NA NA NA ...
#>  $ TRIP.COMMENTS             : Factor w/ 8 levels "","Observations faites avec Serge Martin.",..: 2 2 2 2 2 2 2 2 2 2 ...
#>  $ SPECIES.COMMENTS          : Factor w/ 6 levels "","Billings Bridge",..: 1 1 1 1 1 1 1 1 1 1 ...
#>  $ X                         : logi  NA NA NA NA NA NA ...
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
