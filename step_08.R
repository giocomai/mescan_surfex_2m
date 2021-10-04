library("dplyr", warn.conflicts = FALSE)
library("readr")

lau_year <- 2018

lau_within_df <- ll_get_lau_eu(year = 2018) %>%
  sf::st_transform(crs = 4326) %>% 
  sf::st_filter(y = readr::read_rds("area_covered_sf.rds") %>%
                  sf::st_transform(crs = 4326),
                .predicate = st_within) %>% 
  sf::st_drop_geometry()

lau_excluded_df <- ll_get_lau_eu(year = 2018) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::anti_join(y = lau_within_df, by = "GISCO_ID") 


dataset_eu_file <- fs::path("07-dataset_eu", 
                            "by_lau_all_years.csv.gz")


check_df <- readr::read_csv(file = dataset_eu_file,
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


test_that("all LAU within the area covered are included", {
  expect_equal(object = dataset_eu_file,
               expected = colnames(check_df))
})