library("dplyr", warn.conflicts = FALSE)
library("readr")

dataset_eu_file <- fs::path("07-dataset_eu", 
                            "by_lau_all_years.csv.gz")

original_df <- readr::read_csv("~/Downloads/datasets/dashboard_data_source/lau_lvl_data_temperatures_eu.csv")



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
                                         )) %>% 
  dplyr::filter(year>1970)







### same column names?

library("testthat")

test_that("check if same column names", {
  expect_equal(object = colnames(original_df),
               expected = colnames(check_df))
})


test_that("Same countries included in the dataset", {
  expect_equal(object = {
    original_countries <- original_df %>% dplyr::distinct(CNTR_CODE) %>% dplyr::arrange(CNTR_CODE) %>% dplyr::pull(CNTR_CODE)
    original_countries
  },
  expected = {
    check_countries <- check_df %>% dplyr::distinct(CNTR_CODE) %>% dplyr::arrange(CNTR_CODE) %>% dplyr::pull(CNTR_CODE)
    check_countries
  })
})


test_that("Same NUTS2 included", {
  original_nuts2_df <- original_df %>% dplyr::distinct(NUTS_2_ID) %>% dplyr::arrange(NUTS_2_ID) %>% dplyr::select(NUTS_2_ID)
  check_nuts2_df <- check_df %>% dplyr::distinct(NUTS_2_ID) %>% dplyr::arrange(NUTS_2_ID) %>% dplyr::select(NUTS_2_ID)
  
  
  expect_equal(object = {
    nuts2_not_in_check <- original_nuts2_df %>% 
      dplyr::anti_join(check_nuts2_df, by = "NUTS_2_ID")
    
    nuts2_not_in_original <- check_nuts2_df %>% 
      dplyr::anti_join(original_nuts2_df, by = "NUTS_2_ID")

    sum(nrow(nuts2_not_in_check), nrow(nuts2_not_in_original))
  }, expected = 0
  )
  
  
  expect_equal(object = {
    original_nuts2_df
  },
  expected = {
    check_nuts2_df
  })
  
})





test_that("Same number of rows", {
  expect_equal(object = {
    nrow_original <- original_df %>% nrow()
    nrow_original
  },
  expected = {
    nrow_check <- check_df %>% nrow()
    nrow_check
  })
})



library("latlon2map")
options(timeout = 6000)


lau_2018_v <- ll_get_lau_eu(year = 2018) %>% 
  sf::st_drop_geometry() %>% dplyr::distinct(GISCO_ID) %>% dplyr::arrange(GISCO_ID) %>% dplyr::pull(GISCO_ID)

lau_2019_v <- ll_get_lau_eu(year = 2019) %>% 
  sf::st_drop_geometry() %>% dplyr::distinct(GISCO_ID) %>% dplyr::arrange(GISCO_ID) %>% dplyr::pull(GISCO_ID) 


test_that("Same LAU included in the dataset", {
  expect_true(object = {
    original_gisco_id <- original_df %>% dplyr::distinct(GISCO_ID) %>% dplyr::arrange(GISCO_ID) %>% dplyr::pull(GISCO_ID) 
    check_gisco_id <- check_df %>% dplyr::distinct(GISCO_ID) %>% dplyr::arrange(GISCO_ID) %>% dplyr::pull(GISCO_ID)
    
    length(check_gisco_id)
    length(original_gisco_id)
    length(lau_2018_v)
    length(lau_2019_v)
    
    unmatched_gisco_id_original <- original_gisco_id[is.element(check_gisco_id, original_gisco_id)==FALSE]
    
    unmatched_gisco_id_check <- check_gisco_id[is.element(original_gisco_id, check_gisco_id)==FALSE]
    
      })
  
})



test_that("Same data for the same LAU", {
  expect_true(object = {
    
    check_df %>% 
      dplyr::select(GISCO_ID)
    original_df

  })
  
})



dplyr::all_equal(original_df,
                 check_df)

dplyr::setdiff(original_df,
               check_df)