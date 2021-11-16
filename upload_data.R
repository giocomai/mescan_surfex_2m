library("piggyback")
pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "monthly_average",
               prerelease = TRUE)

monthly_average_files <- fs::dir_ls(path = "03-monthly_average", recurse = FALSE, type = "file")
pb_upload(
  monthly_average_files,
  repo = "giocomai/mescan_surfex_2m",
  tag = "monthly_average")


pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "yearly_average",
               prerelease = TRUE)

yearly_average_files <- fs::dir_ls(path = "03-yearly_average", recurse = FALSE, type = "file")
pb_upload(
  yearly_average_files,
  repo = "giocomai/mescan_surfex_2m",
  tag = "yearly_average")



pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "reference_geometry",
               prerelease = FALSE)


pb_upload(file = c("reference_geometry_df.csv.gz",
                   "reference_geometry_sf.rds",
                   "area_covered_sf.rds"),
  repo = "giocomai/mescan_surfex_2m",
  tag = "reference_geometry")


pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "04-comparison",
               prerelease = FALSE)


pb_upload(file = fs::dir_ls("04-comparison"),
          repo = "giocomai/mescan_surfex_2m",
          tag = "04-comparison")


pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "05-population_weighted_centres",
               prerelease = FALSE)


pb_upload(file = fs::dir_ls("05-population_weighted_centres"),
          repo = "giocomai/mescan_surfex_2m",
          tag = "05-population_weighted_centres")



pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "06-lau_temp_difference-lau_2018-nuts_2016-pop_grid_2018",
               prerelease = FALSE)


pb_upload(file = fs::dir_ls("06-lau_temp_difference-lau_2018-nuts_2016-pop_grid_2018"),
          repo = "giocomai/mescan_surfex_2m",
          tag = "06-lau_temp_difference-lau_2018-nuts_2016-pop_grid_2018")


pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "07-dataset_by_country-lau_2018-nuts_2016-pop_grid_2018",
               prerelease = FALSE)


pb_upload(file = fs::dir_ls("07-dataset_by_country-lau_2018-nuts_2016-pop_grid_2018"),
          repo = "giocomai/mescan_surfex_2m",
          tag = "07-dataset_by_country-lau_2018-nuts_2016-pop_grid_2018")


pb_new_release(repo = "giocomai/mescan_surfex_2m",
               tag = "07-dataset_eu-lau_2018-nuts_2016-pop_grid_2018",
               prerelease = FALSE)


pb_upload(file = fs::dir_ls("07-dataset_eu-lau_2018-nuts_2016-pop_grid_2018"),
          repo = "giocomai/mescan_surfex_2m",
          tag = "07-dataset_eu-lau_2018-nuts_2016-pop_grid_2018")