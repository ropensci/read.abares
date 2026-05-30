#' Use httr2 to fetch a file with retries
#'
#' Retries to download the requested resource before stopping. Uses
#'  \CRANpkg{httr2} to cache in-session results in the `tempdir()`.
#'
#' @param url `Character` The URL being requested.
#' @param dest `Character` A filepath to be written to local storage.
#' @param .max_tries `Integer` The number of times to retry a failed download
#'   before emitting an error message.
#'
#' @examples
#'
#' f <- fs::path_temp("fdp-beta-national-historical.csv")
#' .retry_download(
#'   url = "https://www.agriculture.gov.au/sites/default/files/documents/fdp-beta-national-historical.csv",
#'   dest = f
#' )
#'
#' @returns An invisible file path character string. Called for its
#'   side-effects, writes an object to the specified directory for reading into
#'   the active \R session later.
#' @dev

.retry_download <- function(url, dest, .max_tries = 3L) {
  # Return early if already downloaded this session
  if (file.exists(dest)) {
    return(invisible(dest))
  }

  req <- httr2::request(base_url = url) |>
    httr2::req_user_agent("read.abares") |>
    httr2::req_headers(
      "Accept-Encoding" = "identity",
      "Connection" = "Keep-Alive"
    ) |>
    httr2::req_retry(max_tries = .max_tries) |>
    .apply_conditional_options(url = url) # apply before req_cache

  # req_cache after all request modifications so the key is stable
  req <- httr2::req_cache(req, path = fs::path_temp())

  req |>
    httr2::req_perform() |>
    httr2::resp_body_raw() |>
    brio::write_file_raw(path = dest)

  invisible(dest)
}

#' Apply conditional options to httr2 request
#' @param req An httr2 request object
#' @param url The URL being requested
#' @returns Modified httr2 request object
#' @dev
.apply_conditional_options <- function(req, url) {
  # Agriculture.gov.au specific options
  if (.is_agriculture_url(url)) {
    req <- req |> httr2::req_options(http_version = 2L, timeout = 2000L)
  }

  # Progress display for verbose mode
  if (.should_show_progress()) {
    req <- req |> httr2::req_progress()
  }

  req
}

#' Check if URL is from agriculture.gov.au documents
#' @param url URL to check
#' @returns Logical
#' @dev
.is_agriculture_url <- function(url) {
  grepl(
    "https://www\\.agriculture\\.gov\\.au/sites/default/files/documents/",
    url,
    fixed = FALSE
  )
}

#' Check if progress should be shown
#' @returns Logical
#' @dev
.should_show_progress <- function() {
  identical(getOption("read.abares.verbosity"), "verbose")
}
