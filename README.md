Get the software
================

On Ubuntu

    sudo apt-get install eccodes

On Fedora

    sudo dnf install eccodes

Get R ready
===========

Libraries needed:

    c("tidyverse", # one package to rule them all
      "lubridate", # easier dates
      "fs",        # file management
      "stars",     # spatial objects, from grib to sf
      "sf",        # spatial objects, sf
      "testthat"   # basic quality control checks
      )

    ## [1] "tidyverse" "lubridate" "fs"        "stars"     "sf"        "testthat"

Get Python ready
================

Get the data
============

The data are distributed by Copernicus:
<a href="https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-uerra-europe-single-levels" class="uri">https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-uerra-europe-single-levels</a>

Authenticate
------------

In order to download them, you must first register and authenticate
access to the API. See instructions:
<a href="https://cds.climate.copernicus.eu/api-how-to" class="uri">https://cds.climate.copernicus.eu/api-how-to</a>

Generate the download scripts
-----------------------------

Follow `step 01.R` and following files.
