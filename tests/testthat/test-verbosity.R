test_that(".map_verbosity maps inputs correctly", {
  # Test "quiet"
  quiet <- .map_verbosity("quiet")
  expect_identical(quiet$rlib_message_verbosity, "quiet")
  expect_identical(quiet$warn, -1L)
  expect_false(quiet$datatable.showProgress)

  # Test "minimal"
  minimal <- .map_verbosity("default")
  expect_identical(minimal$rlib_message_verbosity, "default")
  expect_identical(minimal$warn, 0L)
  expect_false(minimal$datatable.showProgress)

  # Test "verbose"
  verbose <- .map_verbosity("verbose")
  expect_identical(verbose$rlib_message_verbosity, "verbose")
  expect_identical(verbose$warn, 0L)
  expect_true(verbose$datatable.showProgress)
})

test_that(".map_verbosity handles garbage inputs gracefully", {
  # Should default to verbose behavior for safety

  # NULL
  res <- .map_verbosity(NULL)
  expect_identical(res$rlib_message_verbosity, "default")
  expect_false(res$datatable.showProgress)

  # Invalid string
  res <- .map_verbosity("super_loud_mode")
  expect_identical(res$rlib_message_verbosity, "default")

  # NA
  res <- .map_verbosity(NA)
  expect_identical(res$rlib_message_verbosity, "default")
})
