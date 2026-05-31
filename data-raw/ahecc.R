## Run this script once to download and process the AHECC classification data
## and save it as an internal data object for the package.
##
## The "uq" column is the Unit of Quantity used in export documentation,
## e.g., KG (kilograms), NO (number/count), L (litres).
##
## Requires: data.table, openxlsx, purrr, usethis

.locf <- function(x) {
  idx <- which(!is.na(x))
  if (!length(idx)) {
    return(x)
  }
  out <- x
  filled <- findInterval(seq_along(x), idx)
  has_prior <- filled > 0L
  out[has_prior] <- x[idx[filled[has_prior]]]
  out
}

.clean_label <- function(x) trimws(sub("^-+\\s*", "", sub(":$", "", x)))

.parse_ahecc_sheet <- function(path, sheet) {
  x <- data.table::as.data.table(
    openxlsx::read.xlsx(
      path,
      sheet = sheet,
      startRow = 6L,
      colNames = TRUE,
      na.strings = c("", "NA", "N/A", "n/a", "na", "np", ".")
    )
  )

  x <- x[,
    !vapply(x, function(col) all(is.na(col)), FUN.VALUE = logical(1L)),
    with = FALSE
  ]
  data.table::setnames(
    x,
    names(x)[1L:6L],
    c("chapter", "heading", "hs_code", "Trade_code", "uq", "description")
  )

  # strip footnote markers from Trade_code e.g. "(a)(b)"
  x[, Trade_code := trimws(sub("\\(.*", "", Trade_code))]

  # forward-fill heading and hs_code down through their None rows so every
  # leaf row carries the last-seen value in each structural column
  x[, heading_ff := .locf(heading)]
  x[, hs_code_ff := .locf(hs_code)]

  # build heading lookup: 4-digit key -> heading description
  heading_lookup <- unique(x[
    !is.na(heading),
    .(key = trimws(heading), heading_desc = .clean_label(description))
  ])

  # build hs lookup: variable-length key -> hs description (may be 5 or 6 digits)
  hs_lookup <- unique(x[
    !is.na(hs_code) & is.na(Trade_code),
    .(key = trimws(hs_code), hs_desc = .clean_label(description))
  ])

  # keep only valid 8-digit leaf rows
  x <- x[!is.na(Trade_code) & nchar(Trade_code) == 8L]
  if (!nrow(x)) {
    return(NULL)
  }

  # join heading via forward-filled heading column (always 4 digits)
  x <- heading_lookup[x, on = .(key = heading_ff)]
  data.table::setnames(x, "key", "heading_ff")

  # join hs via forward-filled hs_code column (5 or 6 digits — actual key length)
  x <- hs_lookup[x, on = .(key = hs_code_ff)]
  data.table::setnames(x, "key", "hs_code_ff")

  x[, leaf_desc := .clean_label(description)]

  # assemble full description from heading -> hs -> leaf, skipping redundant levels
  x[,
    Description := {
      h <- heading_desc
      s <- hs_desc
      l <- leaf_desc
      mid <- data.table::fifelse(
        !is.na(s) & tolower(trimws(s)) != tolower(trimws(h)),
        s,
        NA_character_
      )
      leaf_needed <- data.table::fifelse(
        !is.na(mid),
        tolower(trimws(l)) != tolower(trimws(mid)),
        tolower(trimws(l)) != tolower(trimws(h))
      )
      result <- data.table::fifelse(!is.na(mid), paste(h, mid, sep = " - "), h)
      data.table::fifelse(leaf_needed, paste(result, l, sep = " - "), result)
    }
  ]

  x[, Trade_code := as.factor(Trade_code)]
  x[,
    c(
      "chapter",
      "heading",
      "hs_code",
      "description",
      "heading_ff",
      "hs_code_ff",
      "heading_desc",
      "hs_desc",
      "leaf_desc"
    ) := NULL
  ]
  data.table::setcolorder(x, c("Trade_code", "uq", "Description"))
  x[]
}

tmp_zip <- tempfile(fileext = ".zip")
download.file(
  paste0(
    "https://www.abs.gov.au/statistics/classifications/",
    "australian-harmonized-export-commodity-classification-ahecc/",
    "2022/CompleteAHECC.zip"
  ),
  tmp_zip,
  mode = "wb"
)

xlsx_files <- head(
  Filter(function(f) endsWith(f, ".xlsx"), unzip(tmp_zip, list = TRUE)$Name),
  -2L
)

ahecc <- data.table::rbindlist(Filter(
  Negate(is.null),
  purrr::list_flatten(
    purrr::map(xlsx_files, function(f) {
      path <- unzip(tmp_zip, files = f, exdir = tempdir())
      sheets <- openxlsx::getSheetNames(path)
      sheets <- sheets[
        !is.na(sheets) &
          !endsWith(tolower(sheets), "notes") &
          sheets != "Contents"
      ]
      purrr::map(sheets, ~ .parse_ahecc_sheet(path, .x))
    })
  )
))

usethis::use_data(ahecc, overwrite = TRUE)
