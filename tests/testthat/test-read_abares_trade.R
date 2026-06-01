# Helper: create a small dummy data.table with the expected columns
make_dummy_dt <- function() {
  data.table::data.table(
    Fiscal_year = 2020,
    Month = 1,
    YearMonth = "2020.01",
    Calendar_year = 2020,
    TradeCode = "ABC",
    Overseas_location = "World",
    State = "NSW",
    Australian_port = "Sydney",
    Unit = "t",
    TradeFlow = "Import",
    ModeOfTransport = "Sea",
    Value = 1000,
    Quantity = 50,
    confidentiality_flag = ""
  )
}

# Helper: create a valid zip containing a single CSV and return the zip path
# Uses withr::with_dir + zip::zipr so the archive has a simple relative layout.
make_dummy_zip <- function() {
  tmp_dir <- tempfile("trade_zipdir_")
  fs::dir_create(tmp_dir)
  tmp_csv <- fs::path(tmp_dir, "dummy.csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  zip_path <- tempfile(fileext = ".zip")
  withr::with_dir(tmp_dir, {
    zip::zipr(zipfile = zip_path, files = "dummy.csv")
  })

  # sanity check: ensure unzip can list the CSV inside
  listed <- utils::unzip(zip_path, list = TRUE)
  stopifnot(NROW(listed) == 1L && listed$Name[1] == "dummy.csv")

  zip_path
}

test_that("read_abares_trade reads and renames columns correctly from CSV", {
  # plain CSV branch
  tmp_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  result <- read_abares_trade(tmp_csv)

  # class
  expect_s3_class(result, "data.table")

  # renamed columns present
  expect_true(all(
    c(
      "Fiscal_year",
      "Month",
      "Year_month",
      "Calendar_year",
      "Trade_code",
      "Overseas_location",
      "State",
      "Australian_port",
      "Unit",
      "Trade_flow",
      "Mode_of_transport",
      "Value",
      "Quantity",
      "Confidentiality_flag"
    ) %in%
      names(result)
  ))

  # type conversions
  expect_s3_class(result$Year_month, "Date")
  expect_s3_class(result$Trade_code, "factor")

  # a quick content check
  expect_identical(result$Year_month[1], as.Date("2020-01-01"))
})

test_that("read_abares_trade reads zipped CSV when path points to a zip", {
  # zip branch (no download — we pass x explicitly)
  zip_path <- make_dummy_zip()

  result <- read_abares_trade(zip_path)

  expect_s3_class(result, "data.table")
  expect_true(all(
    c(
      "Fiscal_year",
      "Month",
      "Year_month",
      "Calendar_year",
      "Trade_code",
      "Overseas_location",
      "State",
      "Australian_port",
      "Unit",
      "Trade_flow",
      "Mode_of_transport",
      "Value",
      "Quantity",
      "Confidentiality_flag"
    ) %in%
      names(result)
  ))
  expect_identical(result$Year_month[1], as.Date("2020-01-01"))
})

test_that("read_abares_trade triggers .retry_download when x is NULL", {
  # Stub the internal downloader in the package namespace.
  ns <- asNamespace("read.abares")
  original <- get(".retry_download", envir = ns)
  called <- FALSE

  fake_retry <- function(url, dest) {
    called <<- TRUE
    # write a VALID zip at 'dest' containing the dummy CSV
    tmp_dir <- tempfile("dl_zipdir_")
    fs::dir_create(tmp_dir)
    tmp_csv <- fs::path(tmp_dir, "dummy.csv")
    data.table::fwrite(make_dummy_dt(), tmp_csv)
    withr::with_dir(tmp_dir, {
      zip::zipr(zipfile = dest, files = "dummy.csv")
    })
    # sanity check: the produced zip can be listed
    listed <- utils::unzip(dest, list = TRUE)
    stopifnot(NROW(listed) == 1L && listed$Name[1] == "dummy.csv")
  }

  # Temporarily replace the binding in the package namespace
  unlockBinding(".retry_download", ns)
  assignInNamespace(".retry_download", fake_retry, ns)
  on.exit(
    {
      assignInNamespace(".retry_download", original, ns)
      lockBinding(".retry_download", ns)
    },
    add = TRUE
  )

  # Call with x = NULL to hit the download branch
  result <- read_abares_trade()

  expect_true(called)
  expect_s3_class(result, "data.table")
  expect_identical(result$Year_month[1], as.Date("2020-01-01"))
})

test_that("read_abares_trade errors on invalid path", {
  # fread will error if the file does not exist or is unreadable
  expect_error(read_abares_trade("not_a_real_file.csv"))
})


test_that("code_description = TRUE joins ahecc descriptions onto trade data", {
  tmp_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  result <- read_abares_trade(tmp_csv, code_description = TRUE)

  expect_s3_class(result, "data.table")
  expect_true("Description" %in% names(result))
  expect_true("uq" %in% names(result))
})

test_that("code_description = TRUE places description and uq after Trade_code", {
  tmp_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  result <- read_abares_trade(tmp_csv, code_description = TRUE)

  col_positions <- match(c("Trade_code", "Description", "uq"), names(result))
  expect_identical(
    col_positions,
    c(col_positions[1], col_positions[1] + 1L, col_positions[1] + 2L)
  )
})

test_that("code_description = TRUE keeps Trade_code as factor", {
  tmp_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  result <- read_abares_trade(tmp_csv, code_description = TRUE)

  expect_s3_class(result$Trade_code, "factor")
})

test_that("code_description = FALSE returns no description or uq columns", {
  tmp_csv <- tempfile(fileext = ".csv")
  data.table::fwrite(make_dummy_dt(), tmp_csv)

  result <- read_abares_trade(tmp_csv, code_description = FALSE)

  expect_false("description" %in% names(result))
  expect_false("uq" %in% names(result))
})

test_that("code_description = TRUE row count matches code_description = FALSE", {
  tmp_csv <- tempfile(fileext = ".csv")
  # write multiple rows including a known ahecc code and an unknown one
  dummy <- data.table::rbindlist(list(
    make_dummy_dt(),
    data.table::data.table(
      Fiscal_year = 2020,
      Month = 2,
      YearMonth = "2020.02",
      Calendar_year = 2020,
      TradeCode = "00000000",
      Overseas_location = "World",
      State = "VIC",
      Australian_port = "Melbourne",
      Unit = "t",
      TradeFlow = "Export",
      ModeOfTransport = "Sea",
      Value = 500,
      Quantity = 25,
      confidentiality_flag = ""
    )
  ))
  data.table::fwrite(dummy, tmp_csv)

  result_with <- read_abares_trade(tmp_csv, code_description = TRUE)
  result_without <- read_abares_trade(tmp_csv, code_description = FALSE)

  expect_identical(nrow(result_with), nrow(result_without))
})
