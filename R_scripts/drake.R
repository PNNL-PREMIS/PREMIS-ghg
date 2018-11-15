# Main project file
# November 13, 2018 BBL

library(drake)  # 6.1.0
pkgconfig::set_config("drake::strings_in_dots" = "literals")

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)

# Load our functions
source("read_licor_data.R")
source("process_licor_data.R")
source("inventory.R")

do_filecount <- function(dir) length(list.files(dir))

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
  tree_data = make_tree_data(inventory_data, species_codes, plot_data),
  
  # We use number of files to detect when a new Licor data file is added
  raw_licor_data = target(command = read_licor_dir("../licor_data/"),
                          trigger = trigger(change = do_filecount("../licor_data/"))),
  
  # Process Licor data, adding in treatment etc. information
  licor_data = process_licor_data(raw_licor_data, collar_data, plot_data),
  
  # Proximity data that feeds SP's proximity analysis manuscript
  treeProxDat = read_csv(file_in("../inventory_data/collar_to_tree_prox.csv")),

  # Proximity analysis report
  prox_report = rmarkdown::render(
    knitr_in("proximity_results.Rmd"),
    output_file = file_out("proximity_results.html"),
    quiet = TRUE)
)

# Now type `make(plan)` at command line
