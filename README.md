<!-- README.md is generated from README.Rmd. Please edit that file -->
auk: eBird Data Processing with AWK
===================================

[![Travis-CI Build
Status](https://img.shields.io/travis/mstrimas/auk/master.svg?label=Mac%20OSX%20%26%20Linux)](https://travis-ci.org/mstrimas/auk)

**This package is the early stages of development and should be used
with caution. If you encounter any bugs, please open an issue on
GitHub**

Overview
--------

[eBird](http://www.ebird.org) is an online tool for recording bird
observations. The eBird database contains nearly 500 million sightings
records making it among the largest citizen science projects in history
and an extremely valuable resource for bird research and conservation.
The full eBird database is packaged as a text file and available for
download as the [eBird Basic Dataset
(EBD)](http://ebird.org/ebird/data/download). Due to the large size of
this dataset, it must be filtered to a smaller subset of desired
observations before reading into R. This subsetting is most efficiently
done using AWK, a unix utility and programming language for processing
column formatted text data. This package acts as a front end for AWK,
allowing users to filter eBird data before import into R.

Installation
------------

This package can be installed directly from GitHub with:

    # install.packages("devtools")
    devtools::install_github("mstrimas/auk")

`auk` requires the unix utility AWK and therefore currently only works
on Linux and Mac OS X.

Usage
-----

### Cleaning

Some rows in the eBird Basic Dataset (EBD) may have an incorrect number
of columns and the dataset has an extra blank column at the end. The
function `auk_clean()` drops these erroneous records and removes the
blank column.

    library(auk)
    # sample data
    f <- system.file("extdata/ebd-sample_messy.txt", package="auk")
    tmp <- tempfile()
    # remove problem runs
    auk_clean(f, tmp)
    #> [1] "/var/folders/mg/qh40qmqd7376xn8qxd6hm5lwjyy0h2/T//RtmpNtZ3iQ/filed2557131c8d3"
    # number of lines in input
    length(readLines(f))
    #> [1] 101
    # number of lines in output
    length(readLines(tmp))
    #> [1] 3
    unlink(tmp)

### Filtering

`auk` uses a [pipeline-based workflow](http://r4ds.had.co.nz/pipes.html)
for defining filters, which can be compiled into an AWK script. Users
should start by defining a reference to the EBD file with `auk_ebd()`.
Then the following filters can be applied:

-   `auk_species()`: filter by species using common or scientific names.
-   `auk_country()`: filter by country using the standard Engligh name
    or [ISO 2-letter country
    codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
-   `auk_extent()`: filter by spatial extent, i.e. a range of latitudes
    and longitudes.
-   `auk_date()`: filter to checklists from a range of dates
-   `auk_time()`: filter to checklists started during a range of times.
-   `auk_duration()`: filter to checklists that lasted a given length
    of time.
-   `auk_complete()`: only retain checklists in which the observer has
    specified that they recorded all species seen or heard. These
    records are the most useful for modelling because they provide both
    presence and absenced data.

<!-- -->

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
    #> Input 
    #>   EBD: /Library/Frameworks/R.framework/Versions/3.3/Resources/library/auk/extdata/ebd-sample.txt 
    #> 
    #> Output 
    #>   Filters not executed.
    #> 
    #> Filters 
    #>   Species: Cyanocitta cristata, Perisoreus canadensis
    #>   Countries: CA, MX, US
    #>   Spatial extent: Lat -100 - -80; Lon 37 - 52
    #>   Date: 2012-01-01 - 2012-12-31
    #>   Time: 06:00-09:00
    #>   Laste edited date: all
    #>   Duration: 0-60 minutes
    #>   Complete checklists only: yes

In all cases, checks are performed to ensure filters are valid. For
example, species are checked against the official [eBird
taxonomy](http://help.ebird.org/customer/portal/articles/1006825-the-ebird-taxonomy)
and countries are checked using the
[`countrycode`](https://github.com/vincentarelbundock/countrycode)
package.

Each of these functions only defines the filter. `auk_filter()` should
be used to compile all the filters into an AWK script and execute it to
produce an output file. So, bringing all this together, one could, for
example, extract all Gray Jay and Blue Jay records from Canada with:

    tmp <- tempfile()
    ebd <- system.file("extdata/ebd-sample.txt", package="auk") %>% 
      auk_ebd() %>% 
      auk_species(species = c("Gray Jay", "Cyanocitta cristata")) %>% 
      auk_country(country = "Canada") %>% 
      auk_filter(file = tmp)
    unlink(tmp)

### Reading

EBD files can be read with `read_ebd()`, a wrapper around
`readr::read_delim()`, that uses `stringsAsFactors = FALSE`,
`quote = ""`, sets column data types, and converts variable names to
`snake_case`.

    system.file("extdata/ebd-sample.txt", package="auk") %>% 
      read_ebd() %>% 
      str()
    #> Classes 'tbl_df', 'tbl' and 'data.frame':    0 obs. of  1 variable:
    #> function (x)  
    #>  - attr(*, "class")= chr  "tbl_df" "tbl" "data.frame"

By default, `read_ebd()` returns a tibble for use with
[Tidyverse](http://tidyverse.org) packages. Tibbles will behave just
like plain data frames in most instances, but users can choose to return
a plain `data.frame` or `data.table` by using the `setclass` argument.

    ebd_df <- system.file("extdata/ebd-sample.txt", package="auk") %>% 
      read_ebd(setclass = "data.frame")

Acknowledgements
----------------

This package is based on the AWK scripts provided in a presentation
given by Wesley Hochachka, Daniel Fink, Tom Auer, and Frank La Sorte at
the 2016 NAOC eBird Data Workshop on August 15, 2016.

References
----------

    eBird Basic Dataset. Version: ebd_relFeb-2017. Cornell Lab of Ornithology, Ithaca, New York. May 2013.
