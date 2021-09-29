library("tidyverse")
library("lubridate")

all_months <- seq.Date(from = as.Date("1961-01-01"), to = as.Date("2018-12-31"), by = "day") %>%
  tibble::enframe(name = NULL, value = "date") %>%
  mutate(year = lubridate::year(date), month = lubridate::month(date)) %>%
  group_by(year, month) %>%
  count(name = "days") %>% 
  ungroup()

readr::write_csv(x = all_months,
                 file = "all_months.csv")

fs::dir_create(path = "01-download_scripts")
fs::dir_create(path = "02-grib_monthly")


# create python download scripts

purrr::walk(
  .x = 1:nrow(all_months),
  .f = function(x) {
    text <- paste0(
      "#!/usr/bin/env python
import cdsapi

c = cdsapi.Client()

c.retrieve(
  'reanalysis-uerra-europe-single-levels',
  {
    'origin':'mescan_surfex',
    'variable':'2m_temperature',
    'year':[
      '",
      all_months$year[x],
      "'
       ],
       'month':[
           '",
      all_months$month[x],
      "'
       ],
       'day':[
           '01','02','03',
           '04','05','06',
           '07','08','09',
           '10','11','12',
           '13','14','15',
           '16','17','18',
           '19','20','21',
           '22','23','24',
           '25','26','27',
           '28','29','30',
           '31'
       ],
       'time':[
           '00:00','06:00','12:00',
           '18:00'
       ],
       'format':'grib'
   },
   '",
      fs::path(
        "02-grib_monthly", paste0(all_months$year[x], "-", stringr::str_pad(string = all_months$month[x], width = 2, side = "left", pad = 0), ".grib")
      ),
      "')"
    )
    
    filename <- fs::path("01-download_scripts", paste0(all_months$year[x], "-", stringr::str_pad(string = all_months$month[x], width = 2, side = "left", pad = 0), ".sh"))
    writeLines(text = text, con = filename)
    system(command = paste("chmod +x", filename))
  }
)
