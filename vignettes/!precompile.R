# vignettes that depend on Internet access need to be precompiled and take a
# while to run
library(knitr)
library(here)
library(devtools)

install("./")

knit(
  input = "vignettes/spatial_data_in_read.abares.Rmd.orig",
  output = "vignettes/spatial_data_in_read.abares.Rmd"
)

purl(
  "vignettes/spatial_data_in_read.abares.Rmd.orig",
  output = "vignettes/spatial_data_in_read.abares.R"
)

# remove file path such that vignettes will build with figures
ra_replace <- readLines("vignettes/spatial_data_in_read.abares.Rmd")
ra_replace <- gsub("<img src=\"vignettes/", "<img src=\"", ra_replace)
ra_file_conn <- file("vignettes/spatial_data_in_read.abares.Rmd")
writeLines(ra_replace, ra_file_conn)
close(ra_file_conn)

# build vignettes
build_vignettes()

# move resource files to /docs
resources <-
  list.files("vignettes/", pattern = ".png$", full.names = TRUE)
file.copy(
  from = resources,
  to = here("doc"),
  overwrite = TRUE
)
