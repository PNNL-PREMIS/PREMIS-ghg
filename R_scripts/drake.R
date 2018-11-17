# Main project file
# November 13, 2018 BBL

library(drake)  # 6.1.0
pkgconfig::set_config("drake::strings_in_dots" = "literals")

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_bw())
library(lubridate)
library(kableExtra)

# Load our functions
source("read_licor_data.R")
source("process_licor_data.R")
source("inventory.R")
source("weatherdat.R")

do_filedigest <- function(dir) digest::digest(list.files(dir)) # helper function

plan <- drake_plan(
  
  # `plot_data` holds information based on the plot code: longitude, latitude,
  # area, and salinity/elevation levels
  plot_data = read_csv(file_in("../design/plots.csv"), col_types = "ccccddi"),
  
  # `collar_data` holds information about the collars, based on collar number: 
  # its origin plot, and (if a transplant collar) into what hole it ended up 
  collar_data = read_csv(file_in("../design/cores_collars.csv"), col_types = "cciiicic"),
  
  # `inventory_data` and `species_codes` hold tree information
  inventory_data = read_csv(file_in("../inventory_data/inventory.csv"), col_types = "ccccdccc"),
  species_codes = read_csv(file_in("../inventory_data/species_codes.csv"), col_types = "ccc"),
  tree_data = make_tree_data(),
  
  # Weather data from Hobo loggers and wells
  # We digest the filename list to detect when something changes in the data directories
  # Not perfect--this won't detect a change *within* a file
  wstation_info = read_csv(file_in("../weather_data/wstation_info.csv"), col_types = "cicic"),
  weather_data = target(command = read_all_wxdat("../weather_data/", read_wxdat),
                        trigger = trigger(change = do_filedigest("../weather_data/"))),
  # Conductivity data from wells
  well_data = target(command = read_all_wxdat("../well_data/", read_single_well),
                     trigger = trigger(change = do_filedigest("../well_data/"))),
  
  # Licor data - transplant cores
  # We digest the filename list to detect when something changes in the licor_data directory
  raw_licor_data = target(command = read_licor_dir("../licor_data/"),
                          trigger = trigger(change = do_filedigest("../licor_data/"))),
  # Process, adding in treatment etc. information
  licor_data = process_licor_data(raw_licor_data, collar_data, plot_data),
  licor_daily_data = calculate_licor_daily_data(licor_data),
  
  # --------------------------------------------------------------------------------------------------------
  # Webpage diagnostics report
  diagnostics_report = rmarkdown::render(
    knitr_in("diagnostics.Rmd"),
    output_file = file_out("diagnostics.html"),
    quiet = TRUE),
  
  # --------------------------------------------------------------------------------------------------------
  # Proximity data for SP's proximity analysis manuscript
  treeProxDat = read_csv(file_in("../inventory_data/collar_to_tree_prox.csv"), col_types = "ccidicdcdcccd"),

  # Proximity analysis report
  prox_report = rmarkdown::render(
    knitr_in("proximity_results.Rmd"),
    output_file = file_out("proximity_results.html"),
    quiet = TRUE)
)

# Now type `make(plan)` at command line
