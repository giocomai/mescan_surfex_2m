# Get the population-weighted centre

## To do

## for reference, check: https://medium.com/european-data-journalism-network/how-to-find-the-population-weighted-centre-of-local-administrative-units-a0d198fc91f7

fs::dir_create("05-population_weighted_centres")
library("piggyback")

piggyback::pb_download(repo = "giocomai/population_weighted_centres",
                       tag = "pop_2011_lau_2018_p_2",
                       dest = "05-population_weighted_centres")