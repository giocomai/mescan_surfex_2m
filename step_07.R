library("dplyr", warn.conflicts = FALSE)
library("readr")
library("latlon2map")

params <- readr::read_csv(file = "params.csv",
                          col_types = readr::cols(
                            param = readr::col_character(),
                            value = readr::col_double()
                          ))


dataset_by_country_folder <- paste0("07-dataset_by_country",
                                    "-", 
                                    "lau_", params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value),
                                    "-",
                                    "nuts_", params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value),
                                    "-",
                                    "pop_grid_", params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value)
)


fs::dir_create(dataset_by_country_folder)

yearly_average_files <- fs::dir_ls("03-yearly_average")



lau_temp_difference_folder <- stringr::str_c(
  "06-lau_temp_difference",
  "-", 
  "lau_", params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value),
  "-",
  "nuts_", params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value),
  "-",
  "pop_grid_", params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value)
)


lau_diff_files <- fs::dir_ls(lau_temp_difference_folder)

purrr::walk(
  .x = lau_diff_files,
  .f = function(current_lau_diff_file) {
    current_country <- current_lau_diff_file %>% 
      fs::path_file() %>% 
      stringr::str_extract(pattern = "[A-Z]{2}")
    
    current_csv_file <- fs::path(dataset_by_country_folder,
                                 paste0(current_country,
                                        "_by_lau_all_years.csv.gz"))
    
    if (fs::file_exists(current_csv_file)==FALSE) {
      current_country_diff <- readr::read_csv(file = current_lau_diff_file,
                                              col_types = cols(
                                                gisco_id = col_character(),
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
                                                pop_weighted = col_logical(),
                                                id = col_double(),
                                                avg_1961_1970 = col_double(),
                                                avg_2009_2018 = col_double(),
                                                variation_periods = col_double(),
                                                longitude = col_double(),
                                                latitude = col_double()
                                              ))
      
      current_country_cell_id <- current_country_diff %>% 
        dplyr::pull(id)
      
      current_country_all_years <- purrr::map_dfr(
        .x = yearly_average_files,
        .f = function(current_yearly_average_file) {
          current_year <- current_yearly_average_file %>% 
            fs::path_file() %>% 
            stringr::str_extract(pattern = "[0-9]{4}")
          
          readr::read_csv(file = current_yearly_average_file,
                          col_types = cols(id = col_double(),
                                           temperature = col_double()),
                          lazy = TRUE) %>% 
            dplyr::filter(id %in% current_country_cell_id) %>% 
            dplyr::mutate(year = current_year)
          
        })
      
      current_country_diff %>% 
        dplyr::left_join(y = current_country_all_years %>% 
                           dplyr::rename(avg_year = temperature),
                         by = "id") %>% 
        dplyr::group_by(gisco_id) %>% 
        dplyr::mutate(variation_year = avg_year-avg_1961_1970) %>% 
        dplyr::ungroup() %>% 
        dplyr::select(gisco_id,
                      country,
                      nuts_2, 
                      nuts_3, 
                      lau_id, 
                      lau_name, 
                      population,
                      fid,
                      lau_nuts_concordance = concordance,
                      pop_weighted,
                      longitude, 
                      latitude,
                      cell_id = id, 
                      year,
                      avg_year, 
                      variation_year,
                      avg_1961_1970,
                      avg_2009_2018,
                      variation_periods
                      ) %>%
        dplyr::filter(is.na(avg_year)==FALSE) %>%
        dplyr::filter(year>1970) %>% 
        readr::write_csv(file = current_csv_file)
    }
  })


dataset_eu_folder <- paste0("07-dataset_eu",
                            "-", 
                            "lau_", params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value),
                            "-",
                            "nuts_", params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value),
                            "-",
                            "pop_grid_",  params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value)
)



fs::dir_create(dataset_eu_folder)

dataset_eu_file <- fs::path(dataset_eu_folder, 
                            "by_lau_all_years.csv.gz")

if (fs::file_exists(dataset_eu_file)==FALSE) {
  country_files <- fs::dir_ls(dataset_by_country_folder)
  purrr::map_dfr(
    .x = country_files,
    .f = function(current_country_file) {
      readr::read_csv(file = current_country_file,
                      col_types = 
                        cols(
                          gisco_id = col_character(),
                          country = col_character(),
                          nuts_2 = col_character(),
                          nuts_3 = col_character(),
                          lau_id = col_character(),
                          lau_name = col_character(),
                          population = col_double(),
                          fid = col_character(),
                          lau_nuts_concordance = col_character(),
                          pop_weighted = col_logical(),
                          longitude = col_double(),
                          latitude = col_double(),
                          cell_id = col_double(),
                          year = col_double(),
                          avg_year = col_double(),
                          variation_year = col_double(),
                          avg_1961_1970 = col_double(),
                          avg_2009_2018 = col_double(),
                          variation_periods = col_double()
                        )) 
    }) %>% 
    readr::write_csv(file = dataset_eu_file)
}



