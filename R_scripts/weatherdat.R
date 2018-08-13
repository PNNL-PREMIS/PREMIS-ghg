# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(lubridate)

# Function to replace S/N with descriptive label
swap <- function(file, subfile) {
  wdat <- file %>% 
    read_csv(skip=1) %>%
    gather(label, value, -1:-2) %>% 
    separate(label, sep = "SEN S/N: ", into = c("firstpart", "Sensor_SN")) %>%
    separate(firstpart, sep = ",", into = c("SensorType", "info")) %>%
    select(- info)
  wdat$Timestamp <- mdy_hms(wdat$`Date Time, GMT-04:00`)
  wdat$Sensor_SN <- gsub(")", "", wdat$Sensor_SN)
  
  wdat %>%
    select(-`Date Time, GMT-04:00`) %>%
    left_join(wdat, subfile, by = "Sensor_SN")
  
}

# Read in data
station_info <- read_csv("../inventory_data/wstation_info.csv")

#need to pull out sensor s/n and join with sensor inventory data

ggplot(data = HSLE, aes(x = Timestamp)) + 
  geom_line(aes(y = `20378027`))

# Calculate stdev for each temperature and moisture probe
qc_weather <- HSLE %>%
  summarize(sd(HSLE_T2M_2CM))
