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

pb_delete(repo = "giocomai/mescan_surfex_2m",
          tag = "reference_geometri")
