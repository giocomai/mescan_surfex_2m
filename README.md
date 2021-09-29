Introduction
============

This repository includes code that can be used to replicate the data
exposed by “[Glocal Climate
Change](https://climatechange.europeandatajournalism.eu/)”, an
investigation carried out by OBC Transeuropa for the European Data
Journalism Network (EDJNet) in 2020.

Find more details in the relevant [“About”
page](https://climatechange.europeandatajournalism.eu/en/about).

It also includes pre-processed data that can be downloaded from the
releases associated with this repository on GitHub.

Source
======

The data have been generated using Copernicus Climate Change Service
information (2019): [UERRA regional reanalysis for Europe on single
levels from 1961 to
2019](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-uerra-europe-single-levels?tab=overview)

Context, data quality, and warnings
===================================

<a href="https://www.youtube.com/watch?v=cAzMzIepOC8" class="uri">https://www.youtube.com/watch?v=cAzMzIepOC8</a>

this video outlines some common issues related to data grids, but does
not go into the specifics that are peculiar of the dataset used as an
example.

For more information, check out the methodological note at the bottom of
this article and read the documentation that accompanies the original
dataset.

Some of the issues outlined in the video are mentioned also in the
original documentation: “results in complex terrain, such as mountainous
regions or coastal areas, are generally less reliable than results over
a more homogeneous terrain. The models cannot represent the strong
gradients that sometimes are caused by the variable terrain.”

Data
====

    library("piggyback")
    pb_new_release(repo = "giocomai/mescan_surfex_2m",
                   tag = "monthly_average",
                   prerelease = TRUE)

    monthly_average_files <- fs::dir_ls(path = "03-monthly_average", recurse = FALSE, type = "file")
    pb_upload(
      monthly_average_files,
      repo = "giocomai/mescan_surfex_2m",
      tag = "monthly_average")


    pb_new_release(repo = "giocomai/mescan_surfex_2m",
                   tag = "yearly_average",
                   prerelease = TRUE)

    yearly_average_files <- fs::dir_ls(path = "03-yearly_average", recurse = FALSE, type = "file")
    pb_upload(
      yearly_average_files,
      repo = "giocomai/mescan_surfex_2m",
      tag = "yearly_average")

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

Follow `step_ _01.R` and following files.

-   `step_01.R` - create download scripts to get the data from the
    source
-   `step_02.R` - download data in .grib format
-   `step_03.R` - calculate monthly and yearly averages
-   `step_04.R` - compare first decade with last decade
-   `step_05.R` - find population-weighted centre of municipalities for
    matching
-   `step_06.R` - match municipalities to cells and merge with
    first/last decade temperature difference
-   `step_07.R` - include data and difference from all years to match
    the published dataset used for the dashboard
