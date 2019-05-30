## Script to process and plot litter data
## Created 2019-05-29

library(readr)
library(ggplot2)

litter_data <- list.files(path = "../litter_data/") %>% lapply(read_csv)
