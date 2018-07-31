# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)

#read_weather_data <- function(path) {
#  files <<- list.files(path, pattern = ".csv", full.names = TRUE)
#  list <- list()
#  for (i in files) {
#    list[[i]] <- read_csv(i)
#  }
#}
#c <- read_weather_data("../weather_data/")

# Function to replace S/N with descriptive label
swap <- function(file, subfile) {
  for (i in 3:ncol(file)) {
    n <- which(subfile$Sensor_SN == colnames(file)[i])
    colnames(file)[i] <- c(subfile$Sensor_Label[n])
  }
}

for (i in 3:ncol(HSLE)) {
  n <- which(station_info$Sensor_SN == colnames(HSLE)[i])
  colnames(HSLE)[i] <- c(station_info$Sensor_Label[n])
}

# Read in data
station_info <- read_csv("../inventory_data/wstation_info.csv")

#need to pull out sensor s/n and join with sensor inventory data
HSLE <- read_csv("../weather_data/20377498_HSLE_20180621.csv",
                 col_names = c("Record", "Timestamp", "20353471", "20353472", "20362711", "20362712", "20372264", "20372265", 
                               "20378026", "20378027", "20378787", "20378787"))
ggplot(data = HSLE, aes(x = Timestamp)) + 
  geom_line(aes(y = `20378027`))

# Calculate stdev for each temperature and moisture probe
qc_weather <- HSLE %>%
  summarize(sd(HSLE_T2M_2CM))

