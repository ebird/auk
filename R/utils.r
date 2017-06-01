get_header <- function(x, sep) {
  readLines(x, n = 1) %>%
    stringr::str_split(sep) %>%
    `[[`(1) %>%
    trimws()
}


clean_names <- function(x) {
  x_clean <- tolower(x) %>%
    trimws() %>%
    stringr::str_replace_all("[./ ]", "_")
  x_clean
}

get_col_types <- function(header,
                          reader = c("fread", "read_delim", "read.delim")) {
  reader <- match.arg(reader)

  # column types based on feb 2017 ebd
  col_types = c(
    "GLOBAL UNIQUE IDENTIFIER" = "character",
    "LAST EDITED DATE" = "POSIXct",
    "TAXONOMIC ORDER" = "integer",
    "CATEGORY" = "character",
    "COMMON NAME" = "character",
    "SCIENTIFIC NAME" = "character",
    "SUBSPECIES COMMON NAME" = "character",
    "SUBSPECIES SCIENTIFIC NAME" = "character",
    "OBSERVATION COUNT" = "character",
    "BREEDING BIRD ATLAS CODE" = "character",
    "AGE/SEX" = "character",
    "COUNTRY" = "character",
    "COUNTRY CODE" = "character",
    "STATE" = "character",
    "STATE CODE" = "character",
    "COUNTY" = "character",
    "COUNTY CODE" = "character",
    "IBA CODE" = "character",
    "BCR CODE" = "integer",
    "USFWS CODE" = "character",
    "ATLAS BLOCK" = "character",
    "LOCALITY" = "character",
    "LOCALITY ID" = "character",
    "LOCALITY TYPE" = "character",
    "LATITUDE" = "numeric",
    "LONGITUDE" = "numeric",
    "OBSERVATION DATE" = "Date",
    "TIME OBSERVATIONS STARTED" = "character",
    "OBSERVER ID" = "character",
    "FIRST NAME" = "character",
    "LAST NAME" = "character",
    "SAMPLING EVENT IDENTIFIER" = "character",
    "PROTOCOL TYPE" = "character",
    "PROJECT CODE" = "character",
    "DURATION MINUTES" = "integer",
    "EFFORT DISTANCE KM" = "numeric",
    "EFFORT AREA HA" = "numeric",
    "NUMBER OBSERVERS" = "integer",
    "ALL SPECIES REPORTED" = "logical",
    "GROUP IDENTIFIER" = "character",
    "HAS MEDIA" = "logical",
    "APPROVED" = "logical",
    "REVIEWED" = "logical",
    "REASON" = "character",
    "TRIP COMMENTS" = "character",
    "SPECIES COMMENTS" = "character")

  # remove any columns not in header
  col_types <- col_types[names(col_types) %in% header]

  # make reader specific changes
  if (reader == "fread") {
    col_types[col_types == "logical"] = "integer"
    col_types[col_types == "POSIXct"] = "character"
    col_types[col_types == "Date"] = "character"
  } else if (reader == "read_delim") {
    col_types[col_types == "POSIXct"] = "Time"
    col_types = substr(col_types, 1, 1)
  } else {
    col_types[col_types == "logical"] = "integer"
    names(col_types) <- stringr::str_replace_all(names(col_types), " ", ".")
  }
  col_types
}
