#' Read Data from the ABARES Trade Dashboard
#'
#' Fetches and imports \acronym{ABARES} trade data. As the data, `x`, is large,
#'  ~1.5GB uncompressed \acronym{CSV}, downloads may be slow.
#'
#' @inheritParams read_aagis_regions
#' @param trade_code_desc Boolean. Include the trade code description, this
#'   results in a larger file with long text descriptions for each trade code.
#' @note
#' Columns are renamed for consistency with other \acronym{ABARES} products
#'  serviced in this package using a snake_case format and ordered
#'  consistently.
#'
#' @examplesIf interactive()
#' trade <- read_abares_trade()
#'
#' trade
#'
#' @returns A \CRANpkg{data.table} object of the \acronym{ABARES} trade data.
#' @family Trade
#' @references <https://www.agriculture.gov.au/abares/research-topics/trade/dashboard>
#' @source <https://daff.ent.sirsidynix.net.au/client/en_AU/search/asset/1033841/0>
#' @autoglobal
#' @export

read_abares_trade <- function(x = NULL, trade_code_desc = FALSE) {
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
  data.table::setkey(abares_trade, "Year_month")

  if (trade_code_desc) {
    abares_trade[, temp_code := str_sub(code, 1, -3)]
    abares_trade[,
      description := fcase(
        Calendar_year < 1996L , concordance::get_desc(temp_code, origin = "HS0") ,
        Calendar_year < 2002L , concordance::get_desc(temp_code, origin = "HS1") ,
        Calendar_year < 2007L , concordance::get_desc(temp_code, origin = "HS2") ,
        default = condordance::get_desc(temp_code, origin = "HS3")
      )
    ]
  }
  abares_trade[,
    Year_month := lubridate::ym(
      gsub(".", "-", Year_month, fixed = TRUE)
    )
  ]

  if (description) {}

  return(abares_trade[])
}
