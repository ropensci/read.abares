# -----------------------------
# Helper: create a temporary zip with a tif
make_zip_with_tif <- function(name = "dummy.tif") {
  tmpdir <- fs::path_temp()
  tif_file <- fs::path(tmpdir, name)
  writeLines("fake raster content", tif_file)
  zipfile <- tempfile(fileext = ".zip")
  # Use zip::zipr instead of utils::zip to reliably return a file
  zip::zipr(zipfile, files = tif_file)
  zipfile
}

# -----------------------------
# Tests for .check_zip_has_tiff
test_that(".check_zip_has_tiff returns tif names when valid", {
  zipfile <- make_zip_with_tif("valid.tif")
  result <- .check_zip_has_tiff(zipfile)
  expect_length(result, 1)
  expect_match(result, "\\.tif$")
})

test_that(".check_zip_has_tiff errors if zip does not exist", {
  badfile <- tempfile(fileext = ".zip")
  expect_error(.check_zip_has_tiff(badfile), "does not exist")
})

test_that(".check_zip_has_tiff errors if no tif inside", {
  tmpdir <- fs::path_temp()
  txt_file <- fs::path(tmpdir, "dummy.txt")
  writeLines("not a tif", txt_file)
  zipfile <- tempfile(fileext = ".zip")
  utils::zip(zipfile, files = txt_file, flags = "-j")
  expect_error(
    .check_zip_has_tiff(zipfile),
    "does not appear to contain any .tif files"
  )
})

# -----------------------------
# Tests for .get_lum_files
test_that(".get_lum_files errors if both x and data_set provided", {
  zipfile <- make_zip_with_tif()
  expect_error(
    .get_lum_files(x = zipfile, data_set = "set", lum = "nlum"),
    "You must provide only either"
  )
})

test_that(".get_lum_files errors if neither x nor data_set provided", {
  expect_error(
    .get_lum_files(x = NULL, data_set = NULL, lum = "nlum"),
    "You must provide only either"
  )
})

test_that(".get_lum_files works when x is provided directly", {
  zipfile <- make_zip_with_tif("direct.tif")
  result <- .get_lum_files(x = zipfile, data_set = NULL, lum = "nlum")
  expect_true(fs::file_exists(result$file_path))
  expect_match(result$tiff, "direct.tif")
})

test_that(".get_lum_files errors if x does not exist", {
  badfile <- tempfile(fileext = ".zip")
  expect_error(
    .get_lum_files(x = badfile, data_set = NULL, lum = "nlum"),
    "does not exist"
  )
})

test_that(".get_lum_files works with mocked .get_nlum", {
  fake_nlum <- function(.data_set) make_zip_with_tif("nlum_dummy.tif")
  with_mocked_bindings(
    result <- .get_lum_files(x = NULL, data_set = "testset", lum = "nlum"),
    .get_nlum = fake_nlum
  )
  expect_true(fs::file_exists(result$file_path))
  expect_match(result$tiff, "nlum_dummy.tif")
})

test_that(".get_lum_files works with mocked .get_clum", {
  fake_clum <- function(.data_set) make_zip_with_tif("clum_dummy.tif")
  with_mocked_bindings(
    result <- .get_lum_files(x = NULL, data_set = "testset", lum = "clum"),
    .get_clum = fake_clum
  )
  expect_true(fs::file_exists(result$file_path))
  expect_match(result$tiff, "clum_dummy.tif")
})
