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

plan <- drake_plan(
  
  # `plot_data` holds information based on the plot code: longitude, latitude,
  # area, and salinity/elevation levels
  plot_data = read_csv(file_in("../design/plots.csv"), col_types = "ccccddi"),
  
  # `collar_data` holds information about the collars, based on collar number: 
  # its origin plot, and (if a transplant collar) into what hole it ended up 
  collar_data = read_csv(file_in("../design/cores_collars.csv"), col_types = "cciiicic"),
  
  # Licor data
  # This is my attempt to have drake automatically rebuild when new file(s)
  # are added to the `licor_data` folder. Right now it isn't working.
  filecount = length(list.files("../licor_data/")),
  raw_licor_data = target(trigger = trigger(change = filecount),
                          command = read_licor_dir("../licor_data/")),
  licor_data = process_licor_data(raw_licor_data, collar_data, plot_data),
  
  # Proximity report that feeds SP's proximity analysis manuscript
  treeProxDat = read_csv(file_in("../inventory_data/collar_to_tree_prox.csv")),
  prox_report = rmarkdown::render(
    knitr_in("proximity_results.Rmd"),
    output_file = file_out("proximity_results.html"),
    quiet = TRUE)
)
