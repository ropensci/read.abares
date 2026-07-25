test_that(".get_nlum maps all dataset codes correctly", {
  codes <- c(
    "Y201011" = "NLUM_v7_250_ALUMV8_2010_11_alb_package_20241128",
    "Y201516" = "NLUM_v7_250_ALUMV8_2015_16_alb_package_20241128",
    "Y202021" = "NLUM_v7_250_ALUMV8_2020_21_alb_package_20241128",
    "C201121" = "NLUM_v7_250_CHANGE_SIMP_2011_to_2021_alb_package_20241128",
    "T201011" = "NLUM_v7_250_INPUTS_2010_11_geo_package_20241128",
    "T201516" = "NLUM_v7_250_INPUTS_2015_16_geo_package_20241128",
    "T202021" = "NLUM_v7_250_INPUTS_2020_21_geo_package_20241128",
    "P201011" = "NLUM_v7_250_AgProbabilitySurfaces_2010_11_geo_package_20241128",
    "P201516" = "NLUM_v7_250_AgProbabilitySurfaces_2015_16_geo_package_20241128",
    "P202021" = "NLUM_v7_250_AgProbabilitySurfaces_2020_21_geo_package_20241128"
  )

  with_mocked_bindings(
    .file_exists = function(path) TRUE,
    .retry_download = function(url, dest) NULL,
    {
      for (code in names(codes)) {
        path <- .get_nlum(code)
        expect_true(
          grepl(codes[[code]], path),
          info = paste("Failed for code", code)
        )
      }
    }
  )
})

test_that(".get_nlum rejects invalid dataset codes", {
  expect_error(.get_nlum("INVALID"), "must be one of")
})

test_that(".get_nlum maps dataset codes correctly", {
  # stub file_exists to TRUE so download branch is skipped
  with_mocked_bindings(
    .file_exists = function(path) TRUE,
    .retry_download = function(url, dest) NULL,
    {
      path <- .get_nlum("Y202021")
      expect_true(grepl("NLUM_v7_250_ALUMV8_2020_21", path, fixed = TRUE))
    }
  )
})

test_that(".get_nlum calls .retry_download when file missing", {
  called <- FALSE
  fake_retry <- function(url, dest) {
    called <<- TRUE
    # create a dummy zip file so fs::file_exists() will succeed afterwards
    writeBin(raw(0), dest)
  }

  with_mocked_bindings(
    .file_exists = function(path) FALSE,
    .retry_download = fake_retry,
    {
      path <- .get_nlum("Y201516")
      expect_true(called)
      expect_true(grepl("NLUM_v7_250_ALUMV8_2015_16", path, fixed = TRUE))
    }
  )
})

test_that(".get_nlum returns a file path string", {
  with_mocked_bindings(
    .file_exists = function(path) TRUE,
    .retry_download = function(url, dest) NULL,
    {
      path <- .get_nlum("C201121")
      expect_type(path, "character")
      expect_true(grepl("\\.zip$", path))
    }
  )
})
