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
  
  cat("Generating wx diagnotics...")
  # Calculate stdev for each temperature and moisture probe
  qc_wx <- all_sites %>%
    group_by(Site, Sensor_Depth, Sensor_Group, Timestamp) %>%
    summarize(n = n(), meanValue = mean(Value), sdValue = sd(Value))
  
  cat("Generating weather plots...")
  #check down LSLE
  smoisture_wxplot <- ggplot(filter(all_sites, Sensor_Group == "Water Content"), aes(Timestamp, Value, color = Site, group = Sensor_SN)) + 
    facet_wrap(~Sensor_Depth) + 
    geom_line() +
    ggtitle("Soil Moisture Content") +
    labs(x = "Date", y = expression(m^3/m^3))
  
  TRH_wxplot <- ggplot(filter(all_sites, Sensor_Type == "TRH"), aes(Timestamp, Value, color = Sensor_Group, group = Sensor_Group)) + 
    geom_line() +
    facet_wrap(~Site) +
    ggtitle("Atmospheric Temperature (Celsius) and Relative Humidity (%)") +
    labs(x = "Date")
  
  stemp_wxplot <- ggplot(filter(na.omit(all_sites), Sensor_Group == "Temp"), aes(Timestamp, Value, color = Site, group = Sensor_SN)) + 
    facet_wrap(~Sensor_Depth) + 
    geom_line() +
    ggtitle("Soil Temperature at 2CM and 20CM depth") +
    labs(x = "Date", y = "Celsius")
  
  #ggplot(filter(qc_wx, Sensor_Depth == "20CM"), aes(Timestamp, meanValue, color = Site)) +
  #  facet_wrap(~Site, ncol = 1) +
  #  geom_errorbar(aes(x = Timestamp, ymin = meanValue - sdValue, ymax = meanValue + sdValue), color = "black") +
  #  geom_line() +
  #  ggtitle("20CM depth soil temperature with error bars")
  
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
  
  cat("Saving plots...")
  wxfigures <- list()
  wxfigures$smoisture_wxplot <- smoisture_wxplot
  wxfigures$TRH_wxplot <- TRH_wxplot
  wxfigures$stemp_wxplot <- stemp_wxplot
  save(wxfigures, file = "../outputs/wxfigures.rda")
}
