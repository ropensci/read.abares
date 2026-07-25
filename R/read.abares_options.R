#' Get or Set read.abares Options
#'
#' A convenience function to get or set options used by \CRANpkg{read.abares}.
#' These are package-level persistent options.
#'
#' @param ... Named options to set, or no arguments to retrieve current values.
#' @returns A list of current option values.
#'
#' @examples
#' # See currently set options for {read.abares}
#' read.abares_options()
#'
#' # Set verbosity to quiet and suppress messages
#' read.abares_options(read.abares.verbosity = "quiet")
#' read.abares_options()
#'
#' @export
#' @family read.abares-options

read.abares_options <- function(...) {
  dots <- list(...)

  if (length(dots) == 0L) {
    return(options()[grep("^read.abares\\.", names(options()))])
  }

  invisible(options(...))
}
