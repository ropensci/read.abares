# Internal: map read.abares.verbosity to derived options
#' @noRd
.map_verbosity <- function(verbosity) {
  v <- as.character(verbosity %||% "default")
  if (!v %in% c("quiet", "default", "verbose")) {
    v <- "default"
  }
  list(
    rlib_message_verbosity = switch(
      v,
      quiet = "quiet",
      default = "default",
      verbose = "verbose"
    ),
    rlib_warning_verbosity = switch(
      v,
      quiet = "quiet",
      default = "verbose",
      verbose = "verbose"
    ),
    warn = switch(v, quiet = -1L, default = 0L, verbose = 0L),
    datatable.showProgress = switch(
      v,
      quiet = FALSE,
      default = FALSE,
      verbose = TRUE
    )
  )
}
# nocov start
.onLoad <- function(libname, pkgname) {
  .init_read_abares_options()
}


#' Initialize read.abares options (internal)
#'
#' This is extracted from `.onLoad()` to allow testing.
#' @noRd
.init_read_abares_options <- function() {
  op <- options()

  ua <- tryCatch(
    withr::with_options(
      list(warn = 0L),
      read.abares_user_agent()
    ),
    error = function(e) {
      ver <- tryCatch(
        as.character(utils::packageVersion("read.abares")),
        error = function(...) "unknown"
      )

      sprintf("read.abares/%s (unknown UA)", ver)
    }
  )

  op.read.abares <- list(
    read.abares.user_agent = ua,
    read.abares.timeout = 5000L,
    read.abares.timeout_connect = 20L,
    read.abares.max_tries = 3L,
    read.abares.verbosity = "default"
  )

  toset <- !(names(op.read.abares) %in% names(op))

  if (any(toset)) {
    options(op.read.abares[toset])
  }

  options(
    .map_verbosity(
      getOption("read.abares.verbosity", "default")
    )
  )

  invisible(NULL)
}
#nocov end
