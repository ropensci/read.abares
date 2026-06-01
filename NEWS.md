
# read.abares 3.0.0

## Breaking Changes

- `read_abares_trade()` returns all character strings as factors that are sorted by "Trade_flow", "Fiscal_year", "Month", "Trade_code", "State", "Australian_port", "Overseas_location".
- Verbosity option changed from "minimal" to "default", aligns with {rlang} values.
- Verbosity is now set to "default" by default, not "verbose".

## Minor Changes

- Users can now request trade code descriptions to be included in `read_abares_trade()`.

## Bug fixes

- Download caching now works as intended, files are not re-downloaded during the current session.
- `read_abares_trade()` no longer drops the leading "0" in the "Trade_codes" column.
- Fixed a misconfigured footnote in the "Setting Global Options for "Working with Spatial Data in read.abares" vignette.

# read.abares 2.0.1 (Unreleased)

## Minor Changes

- Update title in DESCRIPTION to be <65 characters for CRAN compliance.

# read.abares 2.0.0

- Accepted into [rOpenSci](https://ropensci.org/) as of 2026-01-13!

- On [CRAN](https://cran.r-project.org/package=read.abares) as of 2026-01-22!

## Breaking Changes

- `soil_thickness` functions are now `topsoil_thickness` functions, _e.g._, `read_soil_thickness_stars()` is now `read_topsoil_thickness_stars()`.
  This is to clarify that the data is for topsoil only and not all soil layers, thanks, @obr-soil!

- `get_` functions are now integrated into `read_`, there is no need to call any `get_` functions separately or use piping.

- Caching is no longer possible between sessions to simplify the package's maintenance and CRAN-proof it.
  I would encourage users to look into using [{targets}](https://books.ropensci.org/targets/) or other methods of managing their data in the workflow.

## New features

- When fetching AGFD, users can filter data by climate year or climate/price year depending on the data and only work with that year or years.
  This functionality still requires **ALL** of the AGFD to be fetched, so this isn't faster, but any of the `read_agfd` functions are faster since they are only reading a smaller portion of data into the active R session, thanks @potterzot!.

- All `read_` functions now support importing local files and parsing them.
  Users may now download the data using methods other than an R session and import local data.

- Additional datasets are now serviced:
  - National and Catchment Scale Land Use data and
  - ABS production data on broadacre crops, horticulture, and livestock.

- Users can set options for {read.abares} including:
  - User-agent string for downloads,
  - Timeout for downloads,
  - Connect-timeout for downloads,
  - Number of download retries and
  - Verbosity of the package's messages.
    Thanks, @mpaulacaldas.

- Improved documentation including:
  - All data sets now have an `@source` field that points to the file being provided
  - All data sets now have an `@references` field that points to references for the data.

- Improved testing:
  - Better coverage, >95% covered,
  - Tests are faster due to using mocking to avoid downloading files during testing,
  - Adds a check of URLs to ensure that they are still valid since no downloads occur during testing.

## Minor improvements and fixes

- Files are more reliably downloaded rather than timing out for some users, thanks to @obrsoil for the help troubleshooting this issue, painful as it was.

- `skimr::skim()` is used in the vignette to display the AGFD {data.table} formatted data rather than just using `head()`.

- [{bit64}](https://cran.r-project.org/package=bit64) has been added to the Suggested packages to help users avoid warning messages when working with data in the console via {data.table}, thanks, @potterzot.

- Alternative installation instructions using {remotes} are provided in the README for users that may prefer or may not use [{pak}](https://cran.r-project.org/package=pak), thanks, @econpotter.

- The topsoil thickness map now correctly displays proper continuous values rather than classes, thanks, @obr-soil.

- The geospatial vignette examples run more quickly, except for the AAGIS examples, which are still slow due to large downloads, but all local operations in R now run much more quickly, thanks to @econpotter.

# read.abares 1.0.0

## Breaking Changes

- Rename functions that both download and read files into active R session from `get_` to `read_` to avoid confusion with functions that only fetch data and have separate `read_` functions

- Adds new function, `print_agfd_nc_file_format()` to provide details on the AGFD NetCDF files' contents

- Uses Geopackages for {sf} objects rather than .Rds, faster and smaller file sizes when caching

- Checks and corrects the geometries of the AAGIS Regions shapefile upon import and applies to the cached object if applicable

## New features

- Improved documentation
  - All data sets now have an `@source` field that points to the file being provided
  - All data sets now have an `@references` field that points to references for the data

- Code linting thanks to [{flint}](https://flint.etiennebacher.com)

- Use {httr2} to handle downloads
  - Increase timeout values to deal with stubborn long-running file downloads
  - Uses {httr2}'s caching functionality to simplify in-session caching

- Use {brio} to write downloads to disk

- Use {httptest2} to help test downloads

- Gracefully handle errors when AGFD zip files are corrupted on download, provide the user with an informative message and remove corrupted download

- Tests are run in parallel for quicker testing

- {sf} operations are now quiet when reading data where possible

## Minor improvements and fixes

- No longer checks the length of a Boolean vector when checking the number of files in the cache before proceeding with removing them

- Fixes bugs in `get_agfd()` when creating the directories for saving the downloaded file

- Fixes bug in `get_aagis_regions()` when creating the cached object file

- Fixes "URL" field in DESCRIPTION file (@mpadge <https://github.com/ropensci/read.abares/issues/1>)

# read.abares 0.1.0

- Submission to rOpenSci for [peer code review](https://github.com/ropensci/software-review/issues)
