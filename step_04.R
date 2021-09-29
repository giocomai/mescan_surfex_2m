library("tidyverse")

monthly_average_folder <- "03-monthly_average"

comparison_folder <- "04-comparison"

fs::dir_create(path = comparison_folder)

all_months <- readr::read_csv(file = "all_months.csv",
                              col_types = cols(year = col_double(),
                                               month = col_double(),
                                               days = col_double()))

past_months_files <- fs::path(monthly_average_folder,
                              all_months %>% 
                                dplyr::filter(year<1971) %>% 
                                dplyr::mutate(month = stringr::str_pad(string = month, width = 2, side = "left", pad = 0)) %>% 
                                glue::glue_data("{year}-{month}.csv.gz"))

recent_months_files <- fs::path(monthly_average_folder,
                                all_months %>% 
                                  dplyr::filter(year>2008) %>% 
                                  dplyr::mutate(month = stringr::str_pad(string = month, width = 2, side = "left", pad = 0)) %>% 
                                  glue::glue_data("{year}-{month}.csv.gz"))


testthat::expect_equal(object = length(past_months_files),
                       expected = length(recent_months_files))

past_average_file <- fs::path(comparison_folder, 
                              "past_average.csv.gz")

if (fs::file_exists(past_average_file)) {
  past_average <- readr::read_csv(file = past_average_file)
} else {
  past_average <- purrr::map_dfr(.x = past_months_files,
                                 .f = readr::read_csv, 
                                 col_types = cols(id = col_double(),
                                                  temperature = col_double())) %>% 
    dplyr::group_by(id) %>% 
    summarise(temperature = mean(temperature))
  
  readr::write_csv(x = past_average,
                   file = past_average_file)
}

recent_average_file <- fs::path(comparison_folder,
                                "recent_average.csv.gz")

if (fs::file_exists(recent_average_file)) {
  recent_average <- readr::read_csv(file = recent_average_file)
} else {
  recent_average <- purrr::map_dfr(.x = recent_months_files,
                                   .f = readr::read_csv,
                                   col_types = cols(id = col_double(),
                                                    temperature = col_double())) %>% 
    dplyr::group_by(id) %>% 
    summarise(temperature = mean(temperature))
  
  readr::write_csv(x = recent_average,
                   file = recent_average_file)
}


difference_file <- fs::path(comparison_folder,
                            "difference_df.csv.gz")

if (fs::file_exists(difference_file)==FALSE) {
  difference_df <- bind_rows(past = past_average,
                             recent = recent_average,
                             .id = "type") %>% 
    tidyr::pivot_wider(id_cols = id, names_from = type, values_from = temperature) %>% 
    dplyr::mutate(difference = recent-past)
  
  readr::write_csv(x = difference_df,
                   file = difference_file)

} else {
  difference_df <- readr::read_csv(difference_file)
}


if (fs::file_exists( fs::path(comparison_folder,
                              "difference_sf.rds"))==FALSE) {
  
  reference_geometry_sf <- readr::read_rds(file = "reference_geometry_sf.rds")
  
  difference_sf <- sf::st_sf(data.frame(difference_df,
                                        reference_geometry_sf))
  
  saveRDS(object = difference_sf,
          file = fs::path(comparison_folder,
                          "difference_sf.rds"))
}


if (fs::file_exists(fs::path(comparison_folder, "difference_point_df.csv.gz"))==FALSE) {
  difference_point_df <- cbind(
    difference_sf %>% sf::st_drop_geometry(),
    difference_sf %>%
      sf::st_centroid() %>% 
      sf::st_transform(crs = 4326) %>%
      sf::st_coordinates() %>% 
      as.data.frame() %>% 
      tibble::as_tibble() %>% 
      dplyr::transmute(longitude = X, latitude = Y)) %>% 
    tibble::as_tibble()
  
  
  readr::write_csv(x = difference_point_df,
                  file = fs::path(comparison_folder,
                                  "difference_point_df.csv.gz"))
} else {
  difference_point_df <- readr::read_csv(file = fs::path(comparison_folder,
                                                         "difference_point_df.csv.gz"))
}


