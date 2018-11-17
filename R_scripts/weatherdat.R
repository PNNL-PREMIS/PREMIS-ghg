# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(lubridate)
library(tidyr)

# Read a single weather station file, reshape, parse, and join with station information
read_wxdat <- function(filename) {
  wstation_info <- readd("wstation_info")
  cat("Reading", filename, "...\n")
  filename %>% 
    read_csv(skip = 1, col_types = "icdddddddddd") %>%
    gather(label, Value, -1:-2) %>%  # first two columns are descriptive
    separate(label, sep = ", SEN S/N: ", into = c("firstpart", "Sensor_SN")) %>% # separate, remove unwanted info
    separate(firstpart, sep = ",", into = c("Sensor_Group", "info")) %>% 
    select(-info) ->
    wdat
  wdat$Timestamp <- mdy_hms(wdat$`Date Time, GMT-04:00`)
  wdat$Sensor_SN <- as.integer(gsub(")", "", wdat$Sensor_SN))
  
  wdat %>% 
    left_join(wstation_info, by = "Sensor_SN") %>%  # Join data with station information
    separate(Sensor_Label, sep = "_", into = c("info1", "info2", "Sensor_Depth"), fill = "right") %>% 
    select(-`Date Time, GMT-04:00`, -info1, -info2)
}

# Read all available weather station files, combine, and remove duplicate rows
read_all_wxdat <- function(dir) {
  list.files(dir, pattern = "[0-9]{8}\\.csv$", full.names = TRUE) %>% 
    lapply(read_wxdat) %>% 
    bind_rows %>% 
    distinct
}

if(0) {

  # Read conductivity data
  cat("Reading conductivity data...")
  cond_HSLE <- read_csv("../well_data/HSLE_conductivity_20180806.csv", skip = 2,
                        col_names = c("#", "Timestamp", "Low_Range", "High_Range", "Temp"))
  cond_HSLE$Timestamp <- mdy_hms(cond_HSLE$Timestamp)
  
  cond_MSLE <- read_csv("../well_data/MSLE_conductivity_20180809.csv", skip = 2,
                        col_names = c("#", "Timestamp", "Low_Range", "High_Range", "Temp"))
  cond_MSLE$Timestamp <- mdy_hms(cond_MSLE$Timestamp)
  
  cond_LSLE <- read_csv("../well_data/LSLE_conductivity_20180809.csv", skip = 2,
                        col_names = c("#", "Timestamp", "Low_Range", "High_Range", "Temp"))
  cond_LSLE$Timestamp <- mdy_hms(cond_LSLE$Timestamp)
  
  cat("Plotting conductivity data...")
  ggplot(cond_LSLE, aes(x = Timestamp)) +
    geom_line(aes(y = Low_Range)) +
    geom_line(aes(y = High_Range), linetype = 2)
  
  cat("Saving datasets...")
  write_csv(all_sites, "../weather_data/wx_all_sites.csv")
  write_csv(cond_LSLE, "../well_data/cond_LSLE")
  
}
