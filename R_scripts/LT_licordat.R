# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

library(tidyr)
library(lubridate)
library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_bw())

source("read_licor_data.R")


LT_licorDat <- read_licor_dir("../licor_data/longterm_dat/")
save(LT_licorDat, file = "../outputs/LT_licordat.rda")
write_csv(LT_licorDat, "../outputs/LT_licor_data.csv")

ggplot(data = LT_licorDat, aes(x = Timestamp, y = Flux, group = Port, color = Port)) + 
  geom_line() + scale_colour_gradientn(colours = rainbow(9)) + 
  ggtitle("Long Term Chamber Measurements") #+ geom_text_repel()

cat("All done.\n")
