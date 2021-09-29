library("tidyverse")

comparison_folder <- "04-comparison"

centre_folder <- fs::path("05-population_weighted_centres")

difference_sf <- readr::read_rds(file = fs::path(comparison_folder,
                                                       "difference_sf.rds"))


library("latlon2map")
options(timeout = 6000)
concordance_df <- ll_get_lau_nuts_concordance(lau_year = 2018,
                                              nuts_year = 2016)

# lau_df <- ll_get_lau_eu(year = 2018) %>% 
#   sf::st_drop_geometry()


centre_by_country_files <- fs::dir_ls(path = centre_folder)

current_centre_file <- centre_by_country_files[1]

fs::dir_create("06-lau_temp_difference")

pb <- progress::progress_bar$new(total = length(centre_by_country_files))

purrr::walk(.x = centre_by_country_files,
            .f = function(current_centre_file) {
              pb$tick()
              current_country_code <- current_centre_file %>% 
                fs::path_file() %>% 
                stringr::str_extract(pattern = "[A-Z]{2}")
              
              current_country_file <- fs::path("06-lau_temp_difference", 
                       paste0(current_country_code, "_difference", ".csv"))
              
              if (fs::file_exists(current_country_file)==FALSE) {
                current_centres_df <- readr::read_csv(file = current_centre_file,
                                                      col_types = readr::cols(
                                                        gisco_id = readr::col_character(),
                                                        lau_name = readr::col_character(),
                                                        longitude = readr::col_double(),
                                                        latitude = readr::col_double()
                                                      ))
                
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
                
                
                current_centres_df %>%
                  dplyr::select(gisco_id, longitude, latitude) %>% 
                  dplyr::left_join(y = concordance_df %>% 
                                     dplyr::select(gisco_id, nuts_2, nuts_3),
                                   by = "gisco_id") %>% 
                  dplyr::left_join(y = current_combo_sf %>% sf::st_drop_geometry(),
                                   by = "gisco_id") %>% 
                  dplyr::mutate(country_code = stringr::str_extract(string = gisco_id, 
                                                                    pattern = "[A-Z]{2}")) %>% 
                  dplyr::select(country_code,
                                nuts_2, 
                                nuts_3, 
                                gisco_id, 
                                lau_name, 
                                longitude,
                                latitude,
                                avg_1961_1970,
                                avg_2009_2018,
                                variation_periods,
                                cell_id = id) %>% 
                  readr::write_csv(current_country_file)
              }
            })



