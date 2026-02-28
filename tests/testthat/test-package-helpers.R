test_that(".map_verbosity maps inputs correctly", {
  # These are safe to test because they don't depend on side effects
  expect_identical(.map_verbosity("quiet")$warn, -1L)
  expect_identical(.map_verbosity("minimal")$warn, 0L)
  expect_true(.map_verbosity("verbose")$datatable.showProgress)

  # Test defaults
  expect_identical(.map_verbosity(NULL)$rlib_message_verbosity, "verbose")
})

test_that("read.abares_user_agent constructs correct strings", {
  # Test the CI path
  withr::local_envvar(list("READABARES_CI" = "true"))

  ua <- read.abares_user_agent()

  expect_match(ua, "read\\.abares R package")
  expect_match(ua, "CI")
  expect_match(ua, "https://github.com")
})

test_that("read.abares_user_agent handles standard users", {
  # Ensure CI is off
  withr::local_envvar(list("READABARES_CI" = ""))

  # We can't easily mock 'whoami' without extra packages,
  # so we test that it produces A valid string, regardless of DEV/Standard status
  ua <- read.abares_user_agent()

  expect_match(ua, "read\\.abares R package")
  expect_true(grepl("DEV", ua) || grepl("\\d+\\.\\d+\\.\\d+", ua))
})

test_that("Package options are initialized correctly", {
  # Instead of calling .init_read_abares_options(), we just check the reality.
  # If the package is loaded, these should exist.

  # If running via devtools::test(), the package is loaded.
  # If running R CMD check, the package is loaded.

  defaults <- list(
    timeout = getOption("read.abares.timeout"),
    tries = getOption("read.abares.max_tries"),
    verb = getOption("read.abares.verbosity")
  )

  # These checks confirm .init_read_abares_options() did its job
  expect_false(is.null(defaults$timeout))
  expect_identical(defaults$timeout, 5000L)
  expect_identical(defaults$tries, 3L)
  expect_identical(defaults$verb, "verbose")
})
