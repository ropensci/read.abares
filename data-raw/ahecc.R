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
    c("chapter", "heading", "hs_code", "ahecc_code", "uq", "description")
  )

  x[,
    depth := data.table::fifelse(
      !is.na(description),
      nchar(sub("^(-*).*", "\\1", description)),
      0L
    )
  ]
  x[,
    label := data.table::fifelse(
      !is.na(description),
      trimws(sub("^-+\\s*", "", sub(":$", "", description))),
      NA_character_
    )
  ]

  for (d in 0L:2L) {
    col <- paste0("parent_d", d)
    x[,
      (col) := .locf(data.table::fifelse(
        depth == d & !is.na(label),
        label,
        NA_character_
      ))
    ]
  }

  x[
    tolower(trimws(label)) == "other",
    label := {
      p <- data.table::fcase(
        depth == 3L , parent_d2 , depth == 2L , parent_d1 , depth == 1L , parent_d0
      )
      data.table::fifelse(
        !is.na(p),
        paste0(tools::toTitleCase(tolower(p)), ", other"),
        label
      )
    }
  ]

  x <- x[!is.na(ahecc_code) & nchar(trimws(ahecc_code)) == 8L]
  if (!nrow(x)) {
    return(NULL)
  }

  x[,
    c(
      "chapter",
      "heading",
      "hs_code",
      "description",
      "depth",
      "parent_d0",
      "parent_d1",
      "parent_d2"
    ) := NULL
  ]
  x[, ahecc_code := as.factor(trimws(ahecc_code))]
  data.table::setnames(x, "label", "description")
  data.table::setcolorder(x, c("ahecc_code", "uq", "description"))
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
