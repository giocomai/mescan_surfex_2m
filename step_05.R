library("dplyr", warn.conflicts = FALSE)
# Get the population-weighted centre

## for an introduction to the concept, 
## check: https://medium.com/european-data-journalism-network/how-to-find-the-population-weighted-centre-of-local-administrative-units-a0d198fc91f7

## For full technical details:
## https://edjnet.github.io/lau_centres/

#### set params ####
### they will be used also in subsequent steps

if (fs::file_exists("params.csv")==FALSE) {
  tibble::tribble(~param, ~value,
                  "lau_year", 2018, 
                  "nuts_year", 2016,
                  "pop_grid_year", 2018) %>% 
    readr::write_csv(file = "params.csv")
}


params <- readr::read_csv(file = "params.csv",
                          col_types = readr::cols(
                            param = readr::col_character(),
                            value = readr::col_double()
                          ))

lau_year <- params %>%
  dplyr::filter(param == "lau_year") %>%
  dplyr::pull(value)
nuts_year <- params %>%
  dplyr::filter(param == "nuts_year") %>%
  dplyr::pull(value)
pop_grid_year <- params %>%
  dplyr::filter(param == "pop_grid_year") %>%
  dplyr::pull(value)

fs::dir_create("05-population_weighted_centres")

lau_centres_file <- fs::path("05-population_weighted_centres",
                             stringr::str_c("lau_", 
                                            lau_year, 
                                            "_nuts_", 
                                            nuts_year, 
                                            "_pop_", 
                                            pop_grid_year,
                                            "_p_2_adjusted_intersection.csv"))

if (fs::file_exists(lau_centres_file)==FALSE) {
  download.file(url = stringr::str_c("https://github.com/EDJNet/lau_centres/releases/download/lau_",
                                     lau_year, 
                                     "_nuts_", 
                                     nuts_year, 
                                     "_pop_grid_", 
                                     pop_grid_year,
                                     "/",
                                     "lau_", 
                                     lau_year, 
                                     "_nuts_", 
                                     nuts_year, 
                                     "_pop_", 
                                     pop_grid_year,
                                     "_p_2_adjusted_intersection.csv"),
                destfile = lau_centres_file)
}
