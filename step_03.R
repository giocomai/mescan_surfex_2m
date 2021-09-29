library("tidyverse")
library("stars")

grib_folder <- "02-grib_monthly"

monthly_average_folder <- "03-monthly_average"
yearly_average_folder <- "03-yearly_average"

all_months <- readr::read_csv(file = "all_months.csv",
                              col_types = cols(year = col_double(),
                                               month = col_double(),
                                               days = col_double())) %>% 
  dplyr::mutate(month = stringr::str_pad(string = month, width = 2, side = "left", pad = 0)) %>% 
  tidyr::unite(col = "year_month", year, month, sep = "-")

#### calculate monthly averages ####

fs::dir_create(monthly_average_folder)

grib_files <- fs::dir_ls(path = grib_folder) %>% 
  fs::path_file()

monthly_average_files <- stringr::str_replace(string = grib_files,
                                              pattern = "grib",
                                              replacement = "csv.gz")

current_monthly_average_files <- fs::dir_ls(path = monthly_average_folder) %>% 
  fs::path_file()

gribs_to_process <- fs::path(grib_files[!is.element(monthly_average_files,
                                                    current_monthly_average_files)])


message(paste(length(grib_files), "grib files available.",
              length(gribs_to_process), "not yet processed.",
              "Progress bar refers to files not yet processed."))

pb <- progress::progress_bar$new(total = length(gribs_to_process))

purrr::walk(
  .x = gribs_to_process,
  .f = function(current_grib) {
    pb$tick()
    
    destination_file <- fs::path(monthly_average_folder,
                                 stringr::str_replace(current_grib,
                                                      "grib",
                                                      "csv.gz"))
    
    stars::read_stars(.x = fs::path(grib_folder, current_grib)) %>% 
      sf::st_as_sf() %>% 
      sf::st_drop_geometry() %>% 
      dplyr::mutate(id = dplyr::row_number()) %>% 
      tidyr::pivot_longer(cols = dplyr::starts_with("2"),
                          names_to = "reference",
                          values_to = "temperature") %>% 
      dplyr::group_by(id) %>% 
      dplyr::summarise(temperature = mean(temperature)) %>% 
      readr::write_csv(file = destination_file)

  })

#### calculate yearly averages ####

fs::dir_create(yearly_average_folder)

yearly_average_files <- fs::path(yearly_average_folder, 
                                 stringr::str_c(1961:2018,
                                                "_average.csv.gz"))
# make sure all monthly files have been calculated before proceding with yearly average

current_yearly_average_files <- fs::dir_ls(path = yearly_average_folder) %>% 
  fs::path_rel()

yearly_average_files_to_process <- yearly_average_files[!is.element(yearly_average_files,
                                                                   current_yearly_average_files)]

message(paste(length(yearly_average_files), "years to process.",
              length(yearly_average_files_to_process), "not yet processed.",
              "Progress bar refers to files not yet processed."))

pb <- progress::progress_bar$new(total = length(yearly_average_files_to_process))

purrr::walk(
  .x = yearly_average_files_to_process,
  .f = function(current_yearly_average_file) {
    
    pb$tick()
    
    current_year <- current_yearly_average_file %>% 
      fs::path_file() %>% 
      stringr::str_extract(pattern = "[[:digit:]]{4}")

    source_files <- fs::dir_ls(path = monthly_average_folder,
                               type = "file",
                               regexp = paste0(current_year))
    
    # there should be 12 files per year, let's check
    testthat::expect_equal(object = length(source_files),
                           expected = 12)
    

    
    current_year_data_df <- purrr::map_dfr(
      .x = source_files,
      .f = function(current_source_file) {
      
        current_year_data <- readr::read_csv(file = current_source_file,
                                             col_types = cols(id = col_double(),
                                                              temperature = col_double())) 
      }, .id = "year_month") %>% 
    # adjust considering months of different length
      dplyr::mutate(year_month = fs::path_file(year_month) %>%
                      stringr::str_extract(pattern = "[[:digit:]]{4}-[[:digit:]]{2}")) %>% 
      dplyr::left_join(y = all_months, by = "year_month") %>% 
    
      dplyr::group_by(id) %>% 
      dplyr::summarise(temperature = weighted.mean(x = temperature,
                                                   w = days)) %>% 
      readr::write_csv(file = current_yearly_average_file)
  

})




#### extract reference geometry ####

reference_geometry_sf_file <- "reference_geometry_sf.rds"

if (fs::file_exists(reference_geometry_sf_file)) {
  reference_geometry_sf <- readr::read_rds(reference_geometry_sf_file)
} else {
  reference_geometry_sf <- stars::read_stars(.x = fs::path(grib_folder,
                                                           grib_files[1])) %>% 
    sf::st_as_sf() %>% 
    dplyr::select(geometry)
  
  saveRDS(object = reference_geometry_sf,
          file = reference_geometry_sf_file)
  
  reference_geometry_df <- reference_geometry_sf %>% 
    sf::st_centroid() %>% 
    sf::st_transform(crs = 4326) %>% 
    sf::st_coordinates() %>% 
    as.data.frame() %>% 
    tibble::as_tibble() %>% 
    dplyr::transmute(longitude = X, latitude = Y)
  
  readr::write_csv(x = reference_geometry_df,
                   file = "reference_geometry_df.csv.gz")
}

