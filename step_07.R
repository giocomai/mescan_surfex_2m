library("latlon2map")

fs::dir_create("07-dataset_by_country")

yearly_average_files <- fs::dir_ls("03-yearly_average")

lau_diff_files <- fs::dir_ls("06-lau_temp_difference")

purrr::walk(
  .x = lau_diff_files,
  .f = function(current_lau_diff_file) {
    current_country <- current_lau_diff_file %>% 
      fs::path_file() %>% 
      stringr::str_extract(pattern = "[A-Z]{2}")
    
    current_csv_file <- fs::path("07-dataset_by_country",
                                 paste0(current_country,
                                        "_by_lau_all_years.csv.gz"))
    
    if (fs::file_exists(current_csv_file)==FALSE) {
      current_country_diff <- readr::read_csv(file = current_lau_diff_file,
                                              col_types = cols(
                                                country_code = col_character(),
                                                nuts_2 = col_character(),
                                                nuts_3 = col_character(),
                                                gisco_id = col_character(),
                                                lau_name = col_character(),
                                                longitude = col_double(),
                                                latitude = col_double(),
                                                avg_1961_1970 = col_double(),
                                                avg_2009_2018 = col_double(),
                                                variation_periods = col_double(),
                                                cell_id = col_double()
                                              ))
      
      current_country_cell_id <- current_country_diff %>% 
        dplyr::pull(cell_id)
      
      current_country_all_years <- purrr::map_dfr(
        .x = yearly_average_files,
        .f = function(current_yearly_average_file) {
          current_year <- current_yearly_average_file %>% 
            fs::path_file() %>% 
            stringr::str_extract(pattern = "[0-9]{4}")
          
          readr::read_csv(file = current_yearly_average_file,
                          col_types = cols(id = col_double(),
                                           temperature = col_double())) %>% 
            dplyr::filter(id %in% current_country_cell_id) %>% 
            dplyr::mutate(year = current_year)
          
        })
      
      current_country_diff %>% 
        dplyr::left_join(y = current_country_all_years %>% 
                           dplyr::rename(cell_id = id, 
                                         avg_year = temperature),
                         by = "cell_id") %>% 
        dplyr::group_by(gisco_id) %>% 
        dplyr::mutate(variation_year = avg_year-dplyr::lag(avg_year)) %>% 
        dplyr::ungroup() %>% 
        dplyr::transmute(CNTR_CODE = country_code,
                         NUTS_2_ID = nuts_2, 
                         NUTS_3_ID = nuts_3,
                         GISCO_ID = gisco_id, 
                         LAU_LABEL = lau_name,
                         avg_1961_1970,
                         year,
                         avg_year,
                         variation_year,
                         avg_2009_2018,
                         variation_periods,
                         lon = longitude,
                         lat = latitude) %>% 
        readr::write_csv(file = current_csv_file)
    }
  })


fs::dir_create("07-dataset_eu")

dataset_eu_file <- fs::path("07-dataset_eu", 
                            "by_lau_all_years.csv.gz")

if (fs::file_exists(dataset_eu_file)==FALSE) {
  country_files <- fs::dir_ls("07-dataset_by_country")
  purrr::map_dfr(.x = country_files,
                 .f = function(current_country_file) {
    readr::read_csv(file = current_country_file,
                    col_types = 
    cols(
      CNTR_CODE = col_character(),
      NUTS_2_ID = col_character(),
      NUTS_3_ID = col_character(),
      GISCO_ID = col_character(),
      LAU_LABEL = col_character(),
      avg_1961_1970 = col_double(),
      year = col_double(),
      avg_year = col_double(),
      variation_year = col_double(),
      avg_2009_2018 = col_double(),
      variation_periods = col_double(),
      lon = col_double(),
      lat = col_double()
    )) 
  }) %>% 
    readr::write_csv(file = dataset_eu_file)
}



