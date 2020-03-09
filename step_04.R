library("tidyverse")

average_folder <- "03-monthly_average"

comparison_folder <- "04-comparison"

fs::dir_create(path = comparison_folder)

all_months <- readr::read_rds(path = "all_months.rds")


past_months_files <- fs::path(average_folder,
                              all_months %>% 
                                dplyr::filter(year<1971) %>% 
                                dplyr::mutate(month = stringr::str_pad(string = month, width = 2, side = "left", pad = 0)) %>% 
                                glue::glue_data("{year}-{month}.rds"))

recent_months_files <- fs::path(average_folder,
                              all_months %>% 
                                dplyr::filter(year>2008) %>% 
                                dplyr::mutate(month = stringr::str_pad(string = month, width = 2, side = "left", pad = 0)) %>% 
                                glue::glue_data("{year}-{month}.rds"))
  

testthat::expect_equal(object = length(past_months_files),
                       expected = length(recent_months_files))

past_average_file <- fs::path(comparison_folder, "past_average.rds")

if (fs::file_exists(past_average_file)) {
  past_average <- readr::read_rds(path = past_average_file)
} else {
  past_average <- purrr::map_dfr(.x = past_months_files, .f = readr::read_rds) %>% 
    dplyr::group_by(id) %>% 
    summarise(temperature = mean(temperature))
  saveRDS(object = past_average, file = past_average_file)
}

recent_average_file <- fs::path(comparison_folder, "recent_average.rds")

if (fs::file_exists(recent_average_file)) {
  recent_average <- readr::read_rds(path = recent_average_file)
} else {
  recent_average <- purrr::map_dfr(.x = recent_months_files, .f = readr::read_rds) %>% 
    dplyr::group_by(id) %>% 
    summarise(temperature = mean(temperature))
  saveRDS(object = recent_average, file = recent_average_file)
}

difference_df <- bind_rows(past = past_average,
                           recent = recent_average,
                           .id = "type") %>% 
  tidyr::pivot_wider(id_cols = id, names_from = type, values_from = temperature) %>% 
  dplyr::mutate(difference = recent-past)

saveRDS(object = difference_df, file = fs::path(comparison_folder, "difference_df.rds"))

reference_geometry_sf <- readr::read_rds("reference_geometry_sf.rds")

difference_sf <- sf::st_sf(data.frame(difference_df, reference_geometry_sf))

saveRDS(object = difference_sf, file = fs::path(comparison_folder, "difference_sf.rds"))
  