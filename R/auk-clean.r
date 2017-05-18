#' Clean an EBD file
#'
#' Some rows in the eBird Basic Dataset (EBD) may have an incorrect number of
#' columns. This function drops these erroneous records. The most recent EBD
#' has 46 columns per row, so this is used as the default in the function.
#'
#' In addition to cleaning the dataset, the field separator can be changed from
#' tab to another character, for example a CSV file can be generated.
#'
#' Calling this function requires that the command line utility AWK is
#' installed. Linux and Mac machines should have AWK by default, Windows users
#' will likely need to install [Cygwin](https://www.cygwin.com).
#'
#' @param f_in character; input file.
#' @param f_out character; output file.
#' @param ncols integer; number of columns in valid rows.
#' @param sep_in character; the input field seperator, the EBD is tab separated
#'   by default. Must only be a single character and space delimited is not
#'   allowed since spaces appear in many of the fields.
#' @param sep_out character; the output field seperator, defaults to tab
#'   delimited. Must only be a single character and space delimited is not
#'   allowed since spaces appear in many of the fields.
#' @param trailing_tab logical; whether the trailing tab should be removed from
#'   the end of each row. The EBD comes with an extra tab at the end of each
#'   line, which causes a extra blank column. Note that this is applied prior to
#'   filtering based on the number of columns, so if `remove_ws` is set to
#'   `FALSE` one must also set `ncols = 47`.
#' @param overwrite logical; overwrite output file if it already exists
#'
#' @return If AWK ran without errors, the output filename is returned,
#'   however, if an error was encountered the exit code is returned.
#' @export
#' @examples
#' # example data with errors
#' f <- system.file("extdata/ebd-sample_messy.txt", package="auk")
#' tmp <- tempfile()
#'
#' # clean file to remove problem rows
#' auk_clean(f, tmp)
#' # number of lines in input
#' length(readLines(f))
#' # number of lines in output
#' length(readLines(tmp))
#'
#' # note that the extra blank column has also been removed
#' ncol(read.delim(f, nrows = 5, quote = ""))
#' ncol(read.delim(tmp, nrows = 5, quote = ""))
#'
#' # clean file and convert from tab to comma seperated
#' auk_clean(f, tmp, sep_out = ",", overwrite = TRUE)
#' # tab separated
#' readLines(f, 1)
#' # comma separated
#' readLines(tmp, 1)
#' unlink(tmp)
auk_clean <- function(f_in, f_out, ncols = 46L,
                       sep_in = "\t", sep_out = "\t",
                       trailing_tab = TRUE, overwrite = FALSE) {
  # checks
  assert_that(
    file.exists(f_in),
    assertthat::is.count(ncols),
    assertthat::is.string(sep_in), nchar(sep_in) == 1, sep_in != " ",
    assertthat::is.string(sep_out), nchar(sep_out) == 1, sep_out != " ",
    assertthat::is.flag(trailing_tab),
    assertthat::is.flag(overwrite)
  )
  # check output file
  if (!dir.exists(dirname(f_out))) {
    stop("Output directory doesn't exist.")
  }
  if (!overwrite && file.exists(f_out)) {
    stop("Output file already exists, use overwrite = TRUE.")
  }

  # construct awk command
  if (trailing_tab) {
    # remove end of line tab
    ws <- "sub(/\t$/, \"\", $0)"
  } else {
    ws <- ""
  }
  awk <- str_interp(awk_clean,
                    list(ncols = ncols, ws = ws,
                         sep_in = sep_in, sep_out = sep_out))
  awk <- paste0("awk '", awk, "' ")
  com <- paste0(awk, f_in, " > ", f_out)

  # run command
  exit_code <- system(com)
  if (exit_code == 0) {
    f_out
  } else {
    exit_code
  }
}

# awk script template
awk_clean <- "
BEGIN {
  FS = \"${sep_in}\"
  OFS = \"${sep_out}\"
}
{
  # hack to force application of OFS to $0
  $1=$1
  ${ws}
  # only keep rows with correct number of records
  if (NF == ${ncols} || NR == 1) {
    print $0
  }
}
"
