library("tidyverse")
library("stars")

grib_folder <- "02-grib_monthly"

average_folder <- "03-monthly_average"

fs::dir_create(average_folder)

grib_files <- fs::dir_ls(path = grib_folder) %>% 
  fs::path_file()

monthly_average_files <- stringr::str_replace(string = grib_files,
                                              pattern = "grib",
                                              replacement = "rds")

current_monthly_average_files <- fs::dir_ls(path = average_folder) %>% 
  fs::path_file()

gribs_to_process <- fs::path(grib_files[!is.element(monthly_average_files,
                                                    current_monthly_average_files)])


message(paste(length(grib_files), "grib files available.",
              length(gribs_to_process), "not yet processed.",
              "Progress bar refers to files not yet processed."))

pb <- dplyr::progress_estimated(n = length(gribs_to_process))

purrr::walk(.x = gribs_to_process, .f = function(x) {
  destination_file <- fs::path(average_folder, stringr::str_replace(x, "grib", "rds"))
  
    stars::read_stars(.x = fs::path(grib_folder, x)) %>% 
      sf::st_as_sf() %>% 
      sf::st_drop_geometry() %>% 
      dplyr::mutate(id = dplyr::row_number()) %>% 
      tidyr::pivot_longer(cols = dplyr::contains("grib"),
                          names_to = "reference",
                          values_to = "temperature") %>% 
      dplyr::group_by(id) %>% 
      dplyr::summarise(temperature = mean(temperature)) %>% 
      saveRDS(file = destination_file)

  pb$tick()$print()
})


# extract reference geometry

reference_geometry_sf_file <- "reference_geometry_sf.rds"

if (fs::file_exists(reference_geometry_sf_file)) {
  reference_geometry_sf <- readr::read_rds(reference_geometry_sf_file)
} else {
  reference_geometry_sf <- stars::read_stars(.x = fs::path(base_grib_folder, grib_files[1])) %>% 
    sf::st_as_sf() %>% 
    dplyr::select(geometry)
  saveRDS(object = reference_geometry_sf, file = reference_geometry_sf_file)
}