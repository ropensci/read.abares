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


.onUnload <- function(libpath) {
  penv <- parent.env(environment())
  withr::deferred_run(penv)
  invisible()
}


#' Initialize read.abares options (internal)
#'
#' This is extracted from `.onLoad()` to allow testing.
#' @noRd
.init_read_abares_options <- function() {
  penv <- parent.env(environment())

  op <- options()
  saved <- op[
    names(op) %in%
      c(
        "rlib_message_verbosity",
        "rlib_warning_verbosity",
        "warn",
        "datatable.showProgress"
      )
  ]

  read.abares_env <- new.env(parent = emptyenv())
  read.abares_env$old_options <- saved

  # Only assign if not already locked
  if (!exists(".read.abares_env", envir = penv, inherits = FALSE)) {
    assign(".read.abares_env", read.abares_env, envir = penv)
  }

  ua <- tryCatch(
    withr::with_options(list(warn = 0L), read.abares_user_agent()),
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
  (any(toset))
  {
    withr::local_options(op.read.abares[toset], .local_envir = penv)
  }

  verbosity <- getOption("read.abares.verbosity")
  mapped <- .map_verbosity(verbosity)
  withr::local_options(mapped, .local_envir = penv)

  invisible(NULL)
}
# nocov end
