library("tidyverse")
library("latlon2map")
options(timeout = 6000)

## read params set in step_05
params <- readr::read_csv(file = "params.csv",
                          col_types = readr::cols(
                            param = readr::col_character(),
                            value = readr::col_double()
                          ))


comparison_folder <- "04-comparison"

lau_centres_df <- read_csv(
  file = fs::path("05-population_weighted_centres",
                  stringr::str_c("lau_", 
                                 params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value), 
                                 "_nuts_", 
                                 params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value), 
                                 "_pop_", 
                                 params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value),
                                 "_p_2_adjusted_intersection.csv")),
  col_types = cols(
    gisco_id = col_character(),
    longitude = col_double(),
    latitude = col_double(),
    country = col_character(),
    nuts_2 = col_character(),
    nuts_3 = col_character(),
    lau_id = col_character(),
    lau_name = col_character(),
    population = col_double(),
    area_km2 = col_double(),
    year = col_double(),
    fid = col_character(),
    concordance = col_character(),
    pop_weighted = col_logical()
  )
) %>% 
  dplyr::rename(population_year = year)



difference_sf <- readr::read_rds(file = fs::path(comparison_folder,
                                                 "difference_sf.rds"))


lau_temp_difference_folder <- stringr::str_c(
  "06-lau_temp_difference",
  "-", 
  "lau_", params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value),
  "-",
  "nuts_", params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value),
  "-",
  "pop_grid_", params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value)
)

fs::dir_create(lau_temp_difference_folder)


available_countries_v <- lau_centres_df %>% 
  dplyr::filter(is.na(longitude)==FALSE, is.na(lau_id)==FALSE) %>% 
  dplyr::distinct(country) %>% 
  dplyr::pull(country)



pb <- progress::progress_bar$new(total = length(available_countries_v))

purrr::walk(
  .x = available_countries_v,
  .f = function(current_country_code) {
    pb$tick()
    
    current_country_file <- fs::path(lau_temp_difference_folder, 
                                     paste0(current_country_code, "_difference", ".csv"))
    
    if (fs::file_exists(current_country_file)==FALSE) {
      current_centres_df <- lau_centres_df %>% 
        dplyr::filter(country==current_country_code)
      
      current_centres_sf <- sf::st_as_sf(
        x = current_centres_df,
        coords = c("longitude","latitude"),
        crs = 4326)
      
      
      current_combo_sf <- sf::st_join(
        x = current_centres_sf %>% sf::st_transform(crs = 4326),
        y = difference_sf %>% sf::st_transform(crs = 4326),
        join = sf::st_within) %>% 
        dplyr::rename(avg_1961_1970 = past, 
                      avg_2009_2018 = recent,
                      variation_periods = difference) 
      
      
      current_country_df <- current_combo_sf %>% sf::st_drop_geometry()%>% 
        dplyr::left_join(y = current_centres_df %>% select(gisco_id, longitude, latitude),
                         by = "gisco_id") 
      
        readr::write_csv(x = current_country_df,
                         file = current_country_file)
    }
  })



