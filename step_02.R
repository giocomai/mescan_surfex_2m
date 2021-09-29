library("tidyverse")

fs::dir_create(path = "02-grib_monthly")

all_scripts <- fs::dir_ls(path = "01-download_scripts") %>% 
  fs::path_file()

current_gribs <- fs::dir_ls(path = "02-grib_monthly") %>% 
  fs::path_file()

all_gribs <- stringr::str_replace(string = all_scripts,
                                  pattern = "sh",
                                  replacement = "grib")

scripts_to_download <- fs::path("01-download_scripts", 
                                all_scripts[!is.element(all_gribs, current_gribs)])

message(paste(length(current_gribs), "files downloaded.",
              length(scripts_to_download), "files to download.",
              "Progress bar refers to missing files."))

pb <- progress::progress_bar$new(total = length(scripts_to_download))

purrr::walk(.x = scripts_to_download,
            .f = function(x) {
              pb$tick()
              system(command = x)
            }
)
