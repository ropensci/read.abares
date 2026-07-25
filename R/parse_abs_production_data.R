#' Create a Unified data.table Object of All Sheets in an Excel Workbook
#'
#' @param filename The name of the Excel workbook for import
#'
#' @returns A [data.table::data.table()] object.
#' @autoglobal
#' @dev

parse_abs_production_data <- function(filename) {
  sheet_names <- readxl::excel_sheets(filename)

  withr::local_options(
    list(
      readxl.show_progress = getOption("read.abares.verbosity") == "verbose"
    )
  )

  x <- purrr::map(sheet_names, function(x) {
    data.table::as.data.table(readxl::read_excel(
      filename,
      sheet = x,
      .name_repair = "universal_quiet",
      na = c("", "NA", "N/A", "n/a", "na", "np", ".")
    ))
  })

  x <- x[-1L] # drop first table with no data
  x[length(x)] <- NULL # drop last table w/ no data

  if (any(grepl("Horticulture", x[[1L]], fixed = TRUE))) {
    x <- purrr::map(x, function(y) {
      region_index <- which(y[[2L]] == "Region") - 1L
      if (length(region_index) && region_index >= 1L) {
        y <- y[-(1L:region_index), ]
      }
      data.table::setnames(y, as.character(unlist(y[1L, ])))
      y <- y[-1L, ]
      data.table::setnames(
        y,
        old = c("Region codes", "Region", "Data item"),
        new = c("region_code", "region", "data_item")
      )
      # keep only region codes 0..8
      y <- y[region_code %in% as.character(0L:8L)]
      data.table::setcolorder(y, neworder = c("region", "region_code"))
      y
    })
  } else {
    x <- purrr::map(x, function(y) {
      region_index <- which(y[[1L]] == "Region") - 1L
      if (length(region_index) && region_index >= 1L) {
        y <- y[-(1L:region_index), ]
      }
      data.table::setnames(y, as.character(unlist(y[1L, ])))
      y <- y[-1L, ]
      data.table::setnames(
        y,
        old = c("Region", "Region codes", "Data item"),
        new = c("region", "region_code", "data_item")
      )
      y <- y[region_code %in% as.character(0L:8L)]
      y
    })
  }

  x <- if (length(x) > 1L) data.table::rbindlist(x) else x[[1L]]

  x <- x[,
    c("commodity", "units") := data.table::tstrsplit(
      data_item,
      " - ",
      fixed = TRUE
    )
  ]
  x[, data_item := NULL]
  data.table::setcolorder(
    x,
    neworder = c("region", "region_code", "commodity", "units")
  )

  total_cols <- ncol(x)
  x[, 1L:2L := lapply(.SD, as.factor), .SDcols = 1L:2L]
  if (total_cols >= 5L) {
    x[, 5L:total_cols := lapply(.SD, as.numeric), .SDcols = 5L:total_cols]
  }
  return(x[])
}

#' Find Which Financial Years Data are Available
#'
#' Grabs the ABS website and uses a regexp to find what financial years are
#'  available for download.
#' @param as string providing the data set that is being requested. One of:
#'   * broadacre,
#'   * horticultural, or
#'   * livestock.
#' @returns A string value of financial years that match availability from the
#'  ABS website, *e.g.*, `2023-24`.
#' @dev
.find_years <- function(data_set) {
  base_url <- "https://www.abs.gov.au/statistics/industry/agriculture/"
  page_url <- switch(
    data_set,
    broadacre = sprintf(
      "%saustralian-agriculture-broadacre-crops",
      base_url
    ),
    horticulture = sprintf(
      "%saustralian-agriculture-horticulture",
      base_url
    ),
    livestock = sprintf("%saustralian-agriculture-livestock", base_url)
  )

  page_text <- htm2txt::gettxt(page_url)

  return(unlist(regmatches(
    page_text,
    gregexpr("\\b\\d{4}-\\d{2}\\b", page_text)
  )))
}
