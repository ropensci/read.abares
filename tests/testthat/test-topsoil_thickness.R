test_that("read_topsoil_thickness_stars returns a stars object with correct dimensions", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path(
    "testdata",
    "test_topsoil.zip"
  )
  result <- read_topsoil_thickness_stars(x = zipfile)
  expect_s3_class(result, "stars")
  expect_identical(unname(dim(result)), c(2L, 2L))
})

test_that("read_topsoil_thickness_stars works with NULL x and mocked download", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path(
    "testdata",
    "test_topsoil.zip"
  )

  fake_retry_download <- function(url, dest) {
    file.copy(zipfile, dest, overwrite = TRUE)
  }

  with_mocked_bindings(
    result <- read_topsoil_thickness_stars(x = NULL),
    .retry_download = fake_retry_download
  )
  expect_s3_class(result, "stars")
  expect_identical(unname(dim(result)), c(2L, 2L))
})

test_that("read_topsoil_thickness_terra returns a SpatRaster with correct dimensions", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path(
    "testdata",
    "test_topsoil.zip"
  )
  result <- read_topsoil_thickness_terra(x = zipfile)
  expect_s4_class(result, "SpatRaster")
  expect_identical(dim(result), c(2, 2, 1))
})

test_that("read_topsoil_thickness_terra works with NULL x and mocked download", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- system.file(
    "testdata",
    "test_topsoil.zip",
    package = "read.abares"
  )

  fake_retry_download <- function(url, dest) {
    file.copy(zipfile, dest, overwrite = TRUE)
  }

  with_mocked_bindings(
    result <- read_topsoil_thickness_terra(x = NULL),
    .retry_download = fake_retry_download
  )
  expect_s4_class(result, "SpatRaster")
  expect_identical(dim(result), c(2, 2, 1))
})

# Keep the metadata tests as they were...
test_that("print_topsoil_thickness_metadata prints headings and metadata when x is NULL", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  ns <- asNamespace("read.abares")

  fake_obj <- list(metadata = "Custodian:  ABARES\nOther metadata")
  fake_get <- function(.x = NULL) fake_obj

  with_mocked_bindings(
    {
      output <- testthat::capture_messages({
        result <- print_topsoil_thickness_metadata()
        expect_null(result)
      })
      output <- paste(output, collapse = "\n")

      expect_match(
        output,
        "Topsoil Thickness for Australian areas of intensive agriculture"
      )
      expect_match(output, "Dataset ANZLIC ID ANZCW1202000149")
      expect_match(output, "Custodian: ABARES")
    },
    .get_topsoil_thickness = fake_get,
    .env = ns
  )
})

test_that("print_topsoil_thickness_metadata works with provided x", {
  ns <- asNamespace("read.abares")

  fake_obj <- list(metadata = "Custodian:  ABARES\nExtra notes")
  fake_get <- function(.x = "local. zip") fake_obj

  with_mocked_bindings(
    {
      output <- testthat::capture_messages({
        result <- print_topsoil_thickness_metadata(x = "local. zip")
        expect_null(result)
      })
      output <- paste(output, collapse = "\n")

      expect_match(output, "Custodian: ABARES")
      expect_match(output, "Topsoil Thickness")
    },
    .get_topsoil_thickness = fake_get,
    .env = ns
  )
})

test_that("print_topsoil_thickness_metadata handles metadata without Custodian gracefully", {
  ns <- asNamespace("read.abares")

  fake_obj <- list(metadata = "No custodian info here")
  fake_get <- function(.x = NULL) fake_obj

  with_mocked_bindings(
    {
      output <- testthat::capture_messages({
        result <- print_topsoil_thickness_metadata()
        expect_null(result)
      })
      output <- paste(output, collapse = "\n")

      expect_match(output, "Topsoil Thickness")
      expect_match(output, "Dataset ANZLIC ID ANZCW1202000149")
    },
    .get_topsoil_thickness = fake_get,
    .env = ns
  )
})
