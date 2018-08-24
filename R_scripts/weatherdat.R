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
    gather(label, Value, -1:-2) %>% 
    separate(label, sep = "SEN S/N: ", into = c("firstpart", "Sensor_SN")) %>%
    separate(firstpart, sep = ",", into = c("Sensor_Group", "info")) %>%
    select(- info)
  wdat$Timestamp <- mdy_hms(wdat$`Date Time, GMT-04:00`)
  wdat$Sensor_SN <- as.integer(gsub(")", "", wdat$Sensor_SN))
 
  wdat <- left_join(wdat, subfile, by = "Sensor_SN") 
  wdat <- separate(wdat, Sensor_Label, sep = "_", into = c("info1", "info2", "Sensor_Depth"))
  wdat <- select(wdat, -`Date Time, GMT-04:00`, -info1, -info2)

}

LSLE <- read_wxdat("../weather_data/LSLE_weather_20180809.csv")
MSLE <- read_wxdat("../weather_data/MSLE_weather_20180809.csv")
HSLE <- read_wxdat("../weather_data/HSLE_weather_20180806.csv")

all_sites <- bind_rows(LSLE, MSLE, HSLE)

#filer()
ggplot(data = HSLE, aes(x = Timestamp, group = Sensor_Type)) + 
  geom_line(aes(y = SensorType == "Temp"))

ggplot(filter(all_sites, Sensor_Group == "Water Content"), aes(Timestamp, Value, color = Site, group = Sensor_SN)) + 
  facet_wrap(~Sensor_Depth) + 
  geom_line()

ggplot(filter(all_sites, Sensor_Type == "TRH"), aes(Timestamp, Value, color = Sensor_Group)) + 
  geom_line()

ggplot(filter(all_sites, Sensor_Group == "Temp"), aes(Timestamp, Value, color = Site, group = Sensor_SN)) + 
  facet_wrap(~Sensor_Depth) + 
  geom_line()

# Calculate stdev for each temperature and moisture probe
qc_weather <- HSLE %>%
  summarize(sd(HSLE_T2M_2CM))
