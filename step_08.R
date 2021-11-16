library("dplyr", warn.conflicts = FALSE)
library("readr")
library("ggplot2")
library("sf")
library("latlon2map")
options(timeout = 6000)

#### set params ####

params <- readr::read_csv(file = "params.csv",
                          col_types = readr::cols(
                            param = readr::col_character(),
                            value = readr::col_double()
                          ))

lau_year <- params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value)


#### load data #####

area_covered_sf <- readr::read_rds("area_covered_sf.rds") 

lau_within_df <- ll_get_lau_eu(year = lau_year) %>%
  sf::st_transform(crs = 4326) %>% 
  sf::st_filter(y = area_covered_sf%>%
                  sf::st_transform(crs = 4326),
                .predicate = sf::st_within) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::rename(gisco_id = GISCO_ID) %>% 
  dplyr::filter(gisco_id != "XK_", gisco_id != "ME_")  # remove incomplete data
  

lau_excluded_df <- ll_get_lau_eu(year = lau_year) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::anti_join(y = lau_within_df,
                   by = "gisco_id") 


dataset_eu_folder <- paste0("07-dataset_eu",
                            "-", 
                            "lau_", params %>% dplyr::filter(param == "lau_year") %>% dplyr::pull(value),
                            "-",
                            "nuts_", params %>% dplyr::filter(param == "nuts_year") %>% dplyr::pull(value),
                            "-",
                            "pop_grid_",  params %>% dplyr::filter(param == "pop_grid_year") %>% dplyr::pull(value)
)

dataset_eu_file <- fs::path(dataset_eu_folder, 
                            "by_lau_all_years.csv.gz")

check_df <- readr::read_csv(file = dataset_eu_file,
                            col_types = cols(
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
                            ),
                            lazy = TRUE)



# ll_get_lau_eu(year = lau_year) %>% 
#   dplyr::filter(gisco_id == "ME_") %>% 
#   ggplot() +
#   geom_sf()
# 
# ll_get_lau_eu(year = lau_year) %>% 
#   dplyr::filter(gisco_id == "XK_") %>% 
#   ggplot() +
#   geom_sf()

####  run tests ####

library("testthat")

test_that("all LAU within the area covered are included", {
  
  expect_true(object = {
    
    present_in_dataset_but_not_expected_df <- 
      dplyr::anti_join(x = check_df %>% 
                         dplyr::distinct(gisco_id) %>% 
                         arrange(gisco_id),
                       y = lau_within_df %>%
                         dplyr::distinct(gisco_id) %>% 
                         arrange(gisco_id),
                       by = "gisco_id")
    
    missing_in_dataset_but_expected_df <- 
      dplyr::anti_join(x = lau_within_df %>%
                         dplyr::distinct(gisco_id) %>% 
                         arrange(gisco_id),
                       y = check_df %>% 
                         dplyr::distinct(gisco_id) %>% 
                         arrange(gisco_id),
                       by = "gisco_id")
    
    sum(nrow(missing_in_dataset_but_expected_df),
        nrow(missing_in_dataset_but_expected_df))==0
    
    
    # present_in_dataset_but_not_expected_sf <-   ll_get_lau_eu(year = lau_year) %>% 
    #   dplyr::right_join(y = present_in_dataset_but_not_expected_df,
    #                     by = "gisco_id")
    # 
    # 
    # ggplot() +
    #   geom_sf(data = readr::read_rds("area_covered_sf.rds")) +
    #   geom_sf(data = ll_get_nuts_eu(level = 0)) +
    #   geom_sf(data =  present_in_dataset_but_not_expected_sf, colour = "purple")
    
    }
  )
})

