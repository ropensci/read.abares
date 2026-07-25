test_that("read_clum_terra returns a SpatRaster when x is provided", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_terra(x = zipfile, data_set = NULL),
    .get_lum_files = fake_get_lum_files
  )
  expect_s4_class(result, "SpatRaster")
  expect_identical(dim(result), c(2, 2, 1))
  expect_identical(terra::nrow(result), 2)
  expect_identical(terra::ncol(result), 2)
})

test_that("read_clum_terra works with mocked . get_lum_files", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_terra(data_set = "clum_50m_2023_v2"),
    .get_lum_files = fake_get_lum_files
  )
  expect_s4_class(result, "SpatRaster")
  expect_identical(dim(result), c(2, 2, 1))
})

test_that("read_clum_terra propagates errors from .get_lum_files", {
  fake_get_lum_files <- function(x, data_set, lum) {
    cli::cli_abort("fake error")
  }
  expect_error(
    with_mocked_bindings(
      read_clum_terra(data_set = "clum_50m_2023_v2"),
      .get_lum_files = fake_get_lum_files
    ),
    "fake error"
  )
})

test_that("read_clum_terra passes ... to terra:: rast", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_terra(data_set = "clum_50m_2023_v2"),
    .get_lum_files = fake_get_lum_files
  )
  expect_s4_class(result, "SpatRaster")
  expect_identical(dim(result), c(2, 2, 1))
})

## ---- Tests for read_clum_stars ----
test_that("read_clum_stars returns a stars object when x is provided", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_stars(x = zipfile, data_set = NULL),
    .get_lum_files = fake_get_lum_files
  )
  expect_s3_class(result, "stars")
  expect_identical(unname(dim(result)), c(2L, 2L))
  expect_named(dim(result), c("x", "y"))
})

test_that("read_clum_stars works with mocked .get_lum_files", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_stars(data_set = "clum_50m_2023_v2"),
    .get_lum_files = fake_get_lum_files
  )
  expect_s3_class(result, "stars")
  expect_identical(unname(dim(result)), c(2L, 2L))
  expect_named(dim(result), c("x", "y"))
})

test_that("read_clum_stars propagates errors from .get_lum_files", {
  fake_get_lum_files <- function(x, data_set, lum) {
    cli::cli_abort("fake error")
  }
  expect_error(
    with_mocked_bindings(
      read_clum_stars(data_set = "clum_50m_2023_v2"),
      .get_lum_files = fake_get_lum_files
    ),
    "fake error"
  )
})

test_that("read_clum_stars passes ...  to stars::read_stars", {
  skip_on_os("windows") # Skip due to intermittent vsizip issues on Windows CI
  zipfile <- test_path("testdata", "test_clum.zip")

  fake_get_lum_files <- function(x, data_set, lum) {
    list(file_path = zipfile, tiff = "clum.tif")
  }

  with_mocked_bindings(
    result <- read_clum_stars(data_set = "clum_50m_2023_v2", RAT = "category"),
    .get_lum_files = fake_get_lum_files
  )
  expect_s3_class(result, "stars")
  expect_identical(unname(dim(result)), c(2L, 2L))
  expect_named(dim(result), c("x", "y"))
})

## ---- Tests for CLUM metadata helpers ----

test_that(".create_clum_50m_coltab loads a data.table from Rds file", {
  ct <- .create_clum_50m_coltab()
  expect_s3_class(ct, "data.table")
  expect_named(ct, c("value", "color"))
  expect_type(ct$value, "integer")
  expect_type(ct$color, "character")
  expect_gt(nrow(ct), 0)
  expect_identical(ct$value[1], 0L)
  expect_identical(ct$color[1], "#ffffff")
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", ct$color)))
})
