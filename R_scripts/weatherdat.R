# Process and analyze weather station data
# Stephanie Pennington | Created July 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)

read_weather_data <- function(path) {
  list <- list()
  for (i in path) {
    list[[i]] <- read_csv(i)
  }
}