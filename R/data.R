#' AHECC Classification Codes
#'
#' Australian Harmonized Export Commodity Classification (AHECC) codes and
#' their descriptions, sourced from the Australian Bureau of Statistics (ABS).
#' The classification is based on the January 2022 version of the AHECC at
#' the 8-digit level.
#'
#' @format A \code{data.table} with three columns:
#' \describe{
#'   \item{Trade_code}{8-digit AHECC export statistical item code (factor).}
#'   \item{uq}{Unit of quantity used in export documentation, e.g. \code{KG},
#'     \code{NO}, \code{L}.}
#'   \item{Description}{Plain-text commodity description with parent context
#'     applied to "Other" categories.}
#' }
#' @source <https://www.abs.gov.au/statistics/classifications/australian-harmonized-export-commodity-classification-ahecc/latest-release>
#' @keywords datasets
"ahecc"
