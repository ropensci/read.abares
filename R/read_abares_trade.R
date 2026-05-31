#' Read Data from the ABARES Trade Dashboard
#'
#' Fetches and imports \acronym{ABARES} trade data. As the data, `x`, is large,
#'  ~1.5GB uncompressed \acronym{CSV}, downloads may be slow. The final object
#'  is sorted by "Fiscal_year" and "Month".
#'
#' @inheritParams read_aagis_regions
#' @param code_description Boolean. Include the trade code description, this
#'   results in a larger object with long text descriptions for each trade code,
#'   and the unit of quantity measure, *e.g.*,  "KG" (kilograms), "NO"
#'   (number/count), "L" (litres).
#' @note
#' Columns are renamed for consistency with other \acronym{ABARES} products
#'  serviced in this package using a snake_case format and ordered
#'  consistently. "State" reflects the state of origin of the exported
#'  goods, not the state in which the port of departure is located; it is
#'  therefore expected that "State" and "Australian_port" will not always
#'  correspond geographically.
#' @examplesIf interactive()
#' trade <- read_abares_trade()
#'
#' trade
#'
#' trade_codes <- read_abares_trade(code_description = TRUE)
#'
#' trade_codes
#'
#' @returns A \CRANpkg{data.table} object of the \acronym{ABARES} trade data
#'  with the "Trade_code" field as the key for fast subsetting.
#' @family Trade
#' @references <https://www.agriculture.gov.au/abares/research-topics/trade/dashboard>
#' @source <https://daff.ent.sirsidynix.net.au/client/en_AU/search/asset/1033841/0>
#' @autoglobal
#' @export

read_abares_trade <- function(x = NULL, code_description = FALSE) {
  if (is.null(x)) {
    x <- fs::path_temp("abares_trade_data.zip")

    .retry_download(
      url = "https://daff.ent.sirsidynix.net.au/client/en_AU/search/asset/1033841/1",
      dest = x
    )
  }
  abares_trade <- data.table::fread(
    x,
    verbose = getOption("read.abares.verbosity") == "verbose",
    colClasses = c(
      Fiscal_year = "character",
      Month = "integer",
      YearMonth = "character",
      Calendar_year = "integer",
      TradeCode = "factor",
      Overseas_location = "character",
      State = "character",
      Australian_port = "character",
      Unit = "character",
      TradeFlow = "character",
      ModeOfTransport = "character",
      Value = "numeric",
      Quantity = "numeric",
      confidentiality_flag = "integer"
    )
  )
  data.table::setnames(
    abares_trade,
    old = c(
      "Fiscal_year",
      "Month",
      "YearMonth",
      "Calendar_year",
      "TradeCode",
      "Overseas_location",
      "State",
      "Australian_port",
      "Unit",
      "TradeFlow",
      "ModeOfTransport",
      "Value",
      "Quantity",
      "confidentiality_flag"
    ),
    new = c(
      "Fiscal_year",
      "Month",
      "Year_month",
      "Calendar_year",
      "Trade_code",
      "Overseas_location",
      "State",
      "Australian_port",
      "Unit",
      "Trade_flow",
      "Mode_of_transport",
      "Value",
      "Quantity",
      "Confidentiality_flag"
    )
  )

  if (isTRUE(code_description)) {
    abares_trade <- ahecc[abares_trade, on = "Trade_code"]
    abares_trade[, Trade_code := as.factor(Trade_code)]
    abares_trade[
      is.na(Description),
      Description := "It's an older code sir, but it checks out. The code not in current (2022) AHECC classification"
    ]
    data.table::setcolorder(
      abares_trade,
      c(
        "Fiscal_year",
        "Month",
        "Year_month",
        "Calendar_year",
        "Trade_code",
        "Description",
        "uq"
      )
    )
  }
  abares_trade[,
    (names(abares_trade)[vapply(
      abares_trade,
      is.character,
      FUN.VALUE = logical(1L)
    )]) := lapply(.SD, as.factor),
    .SDcols = is.character
  ]
  data.table::setorderv(
    abares_trade,
    c(
      "Trade_flow",
      "Fiscal_year",
      "Month",
      "Trade_code",
      "State",
      "Australian_port",
      "Overseas_location"
    ),
    order = 1L
  )
  abares_trade[,
    Year_month := lubridate::ym(
      gsub(".", "-", Year_month, fixed = TRUE)
    )
  ]

  data.table::setkey(abares_trade, "Trade_code")
  return(abares_trade[])
}
