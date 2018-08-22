# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(lubridate)
library(tidyr)

# Function to replace S/N with descriptive label
read_wxdat <- function(file) {
  subfile <- read_csv("../inventory_data/wstation_info.csv")
  wdat <- file %>% 
    read_csv(skip=1) %>%
    gather(label, value, -1:-2) %>% 
    separate(label, sep = "SEN S/N: ", into = c("firstpart", "Sensor_SN")) %>%
    separate(firstpart, sep = ",", into = c("SensorType", "info")) %>%
    select(- info)
  wdat$Timestamp <- mdy_hms(wdat$`Date Time, GMT-04:00`)
  wdat$Sensor_SN <- as.integer(gsub(")", "", wdat$Sensor_SN))
 
  wdat <- left_join(wdat, subfile, by = "Sensor_SN") 
  wdat <- select(wdat, -`Date Time, GMT-04:00`)
}

LSLE <- read_wxdat("../weather_data/20377496_LSLE_20180718.csv")
MSLE <- read_wxdat("../weather_data/20377497_MSLE_20180718.csv")
HSLE <- read_wxdat("../weather_data/20377498_HSLE_20180718.csv")


ggplot(data = HSLE, aes(x = Timestamp, group = Sensor_Type)) + 
  geom_line(aes(y = SensorType == "Temp"))

# Calculate stdev for each temperature and moisture probe
qc_weather <- HSLE %>%
  summarize(sd(HSLE_T2M_2CM))
