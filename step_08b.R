library("dplyr", warn.conflicts = FALSE)
library("readr")
library("latlon2map")
options(timeout = 6000)


params <- readr::read_csv(file = "params.csv",
                          col_types = readr::cols(
                            param = readr::col_character(),
                            value = readr::col_double()
                          ))

dataset_eu_folder <- paste0("07-dataset_eu",
                            "-", 
                            "lau_",
                            params %>%
                              dplyr::filter(param == "lau_year") %>%
                              dplyr::pull(value),
                            "-",
                            "pop_grid_",
                            params %>%
                              dplyr::filter(param == "pop_grid_year") %>%
                              dplyr::pull(value)
)

dataset_eu_file <- fs::path(dataset_eu_folder, 
                            "by_lau_all_years.csv.gz")

original_df <- readr::read_csv("~/Downloads/datasets/dashboard_data_source/lau_lvl_data_temperatures_eu.csv")


# gisco id with valid id and within the relevant area
gisco_id_within_area_covered_2018_df <- ll_get_lau_eu(year = 2018) %>%
  sf::st_transform(crs = 4326) %>% 
  sf::st_filter(y = readr::read_rds("area_covered_sf.rds") %>%
                  sf::st_transform(crs = 4326),
                .predicate = sf::st_within) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::filter(is.na(LAU_ID)==FALSE) # exclude lau in montenengro and kosovo with no valid data

# all(sf::st_is_valid( ll_get_lau_eu(year = 2019) %>%  sf::st_make_valid()))
# to deal with issues in the geometry, see also: https://gis.stackexchange.com/questions/404385/r-sf-some-edges-are-crossing-in-a-multipolygon-how-to-make-it-valid-when-using/404454
# or just crs to 3857

# sf_use_s2(TRUE)
gisco_id_within_area_covered_2019_df <- ll_get_lau_eu(year = 2019) %>% 
  sf::st_transform(crs = 3857) %>%
  sf::st_make_valid() %>% 
  sf::st_filter(y = readr::read_rds("area_covered_sf.rds") %>% sf::st_transform(crs = 3857),
                .predicate = sf::st_within) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::filter(is.na(LAU_ID)==FALSE) # exclude lau in montenengro and kosovo with no valid data

gisco_id_within_area_covered_2020_df <- ll_get_lau_eu(year = 2020) %>%
  sf::st_transform(crs = 3857) %>% 
  sf::st_filter(y = readr::read_rds("area_covered_sf.rds") %>%
                  sf::st_transform(crs = 3857),
                .predicate = sf::st_within) %>% 
  sf::st_drop_geometry() %>% 
  dplyr::filter(is.na(LAU_ID)==FALSE) # exclude lau in montenengro and kosovo with no valid data



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

### temporarily exclude missing countries####

nrow(check_df %>%distinct(CNTR_CODE))
check_df <-  check_df %>% 
  dplyr::filter(!is.element(CNTR_CODE, c("CY", "IS", "LU", "MK","RS")))

nrow(check_df %>%distinct(CNTR_CODE))


gisco_id_within_area_covered_2018_df <- gisco_id_within_area_covered_2018_df %>% 
  dplyr::filter(!is.element(CNTR_CODE, c("CY", "IS", "LU", "MK","RS")))

gisco_id_within_area_covered_2019_df <- gisco_id_within_area_covered_2019_df %>% 
  dplyr::filter(!is.element(CNTR_CODE, c("CY", "IS", "LU", "MK","RS")))

#### testing #####

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
  
  check_countries[!is.element(check_countries, original_countries)]
  original_countries[!is.element(original_countries, check_countries)]
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
    
    original_df %>% dplyr::distinct(NUTS_2_ID, .keep_all = TRUE) %>%
      dplyr::filter(CNTR_CODE == "AL")
    original_df %>% dplyr::distinct(GISCO_ID, .keep_all = TRUE) %>%
      dplyr::filter(CNTR_CODE == "EE")
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





test_that("Same LAU included in the dataset", {
  library("latlon2map")
  library("sf")
  options(timeout = 6000)
  
  # 
  # lau_2018_v <- ll_get_lau_eu(year = 2018) %>% 
  #   sf::st_drop_geometry() %>%
  #   dplyr::distinct(GISCO_ID) %>%
  #   dplyr::arrange(GISCO_ID) %>%
  #   dplyr::pull(GISCO_ID)
  # 
  # lau_2019_v <- ll_get_lau_eu(year = 2019) %>% 
  #   sf::st_drop_geometry() %>% 
  #   dplyr::distinct(GISCO_ID) %>%
  #   dplyr::arrange(GISCO_ID) %>%
  #   dplyr::pull(GISCO_ID) 
  # 
  
  
check_df %>% 
  dplyr::filter(GISCO_ID == "ME_")

check_df %>% 
  dplyr::filter(NUTS_2_ID == "PT20")
  
gisco_id_within_area_covered_2018_df %>% 
    dplyr::anti_join(y = check_df,
                     by = "GISCO_ID") %>% 
  distinct(CNTR_CODE)
  
  check_df %>% 
    dplyr::anti_join(y = gisco_id_within_area_covered_2018_df,
                     by = "GISCO_ID") %>% View()
  
  
  # dplyr::distinct(GISCO_ID) %>%
  #   dplyr::arrange(GISCO_ID) %>%
  #   dplyr::pull(GISCO_ID) 
  
  expect_true(object = {
    original_gisco_id <- original_df %>%
      dplyr::distinct(GISCO_ID) %>%
      dplyr::arrange(GISCO_ID) %>%
      dplyr::pull(GISCO_ID) 
    
    check_gisco_id <- check_df %>%
      dplyr::distinct(GISCO_ID) %>%
      dplyr::arrange(GISCO_ID) %>%
      dplyr::pull(GISCO_ID)
    
    theoretic_gisco_id <- gisco_id_within_area_covered_2019_df %>%
      dplyr::distinct(GISCO_ID) %>%
      dplyr::arrange(GISCO_ID) %>%
      dplyr::pull(GISCO_ID)
    
    length(check_gisco_id)
    length(original_gisco_id)
    length(theoretic_gisco_id)
    
    
    unmatched_gisco_id_original <- original_gisco_id[is.element(check_gisco_id, original_gisco_id)==FALSE]
    
    unmatched_gisco_id_check <- check_gisco_id[is.element(original_gisco_id, check_gisco_id)==FALSE]

    
    length(unmatched_gisco_id_check)
    
    ll_get_lau_nuts_concordance(lau_year = 2018) %>% 
      dplyr::filter(is.element(gisco_id, unmatched_gisco_id_check)) %>% 
      dplyr::distinct(nuts_2)
        
      })
  
  
  original_df %>% 
    dplyr::filter(CNTR_CODE == "PT") %>% 
    dplyr::distinct(GISCO_ID) %>% 
    nrow()
  
  gisco_id_within_area_covered_2019_df %>% 
    dplyr::filter(CNTR_CODE == "PT") %>% 
    dplyr::distinct(GISCO_ID) %>% 
    nrow()
  
})



test_that("Same data for the same LAU", {

  
  expect_true(object = {
    
    common_gisco_df <- dplyr::semi_join(check_df %>% 
                       dplyr::distinct(GISCO_ID),
                     original_df %>% 
                       dplyr::distinct(GISCO_ID), by = "GISCO_ID")
    
    
    combo_df <- dplyr::bind_rows(original = original_df, 
                                 check = check_df,
                                 .id = "source")
    
    head(combo_df)
    
    combo_df %>% 
      dplyr::distinct(source, GISCO_ID, avg_1961_1970) %>% 
      tidyr::pivot_wider(names_from = source, values_from = avg_1961_1970) %>% 
      dplyr::mutate(difference = original-check) %>% 
      dplyr::arrange(dplyr::desc(difference)) %>% 
      dplyr::filter(difference>0.1) %>% 
    dplyr::arrange(difference) 
    
    
    
    combo_df %>% 
      dplyr::distinct(source, GISCO_ID, variation_periods) %>% 
      tidyr::pivot_wider(names_from = source, values_from = variation_periods) %>% 
      dplyr::mutate(difference = original-check) %>% 
      dplyr::arrange(dplyr::desc(difference)) %>% 
      dplyr::filter(difference>0.1) %>% 
      dplyr::arrange(difference) 
    
    
    double_gisco_id <- ll_get_lau_eu(year = 2018) %>% 
      dplyr::group_by(CNTR_CODE, LAU_NAME) %>% 
      add_count() %>% 
      ungroup() %>% 
      filter(n>2) %>% 
      dplyr::select(GISCO_ID) %>% 
      sf::st_drop_geometry()
    
    
    
    combo_df %>% 
      dplyr::anti_join(y = double_gisco_id, by = "GISCO_ID") %>% 
      dplyr::distinct(source, GISCO_ID, avg_1961_1970) %>% 
      tidyr::pivot_wider(names_from = source, values_from = avg_1961_1970) %>% 
      dplyr::mutate(difference = original-check) %>% 
      dplyr::arrange(dplyr::desc(difference)) %>% 
      dplyr::filter(difference>0.5) %>% 
      dplyr::arrange(difference) 
    
    
    
    combo_df %>% 
      dplyr::anti_join(y = double_gisco_id, by = "GISCO_ID") %>% 
      dplyr::distinct(source, GISCO_ID, variation_periods) %>% 
      tidyr::pivot_wider(names_from = source, values_from = variation_periods) %>% 
      dplyr::mutate(difference = original-check) %>% 
      dplyr::arrange(dplyr::desc(difference)) %>% 
      dplyr::filter(difference>0.5) %>% 
      dplyr::arrange(difference) 
    

    
    reference_geometry_sf <- readRDS("reference_geometry_sf.rds")
    
    
    
    combo_df %>% 
      dplyr::anti_join(y = double_gisco_id, by = "GISCO_ID") %>% 
      dplyr::distinct(source, GISCO_ID, lon) %>% 
      tidyr::pivot_wider(names_from = source, values_from = lon) %>% 
      dplyr::mutate(difference = original-check) %>% 
      dplyr::arrange(dplyr::desc(difference)) %>% 
      dplyr::filter(difference>0.5) %>% 
      dplyr::arrange(difference) 
    
    SK_511188
  })
  
})


ll_get_la


dplyr::all_equal(original_df,
                 check_df)

dplyr::setdiff(original_df,
               check_df)