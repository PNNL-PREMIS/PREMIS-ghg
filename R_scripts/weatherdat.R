# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)

read_weather_data <- function(path) {
  files <<- list.files(path, pattern = ".csv", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_csv(i)
  }
}

c <- read_weather_data("../weather_data/")

#need to pull out sensor s/n and join with sensor inventory data
HSLE <- read_csv("../weather_data/20377498_HSLE_20180621.csv")
test<- grep("SEN S/N:", HSLE)
