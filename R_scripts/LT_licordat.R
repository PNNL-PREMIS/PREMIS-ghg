# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

library(tidyr)
library(lubridate)
library(dplyr)
library(readr)
library(ggplot2)
theme_set(theme_bw())

source("read_licor_data.R")


LT_licorDat <- read_licor_dir("../licor_data/longterm_dat/") %>% 
  rename(T5 = V3, SMoist = V2) ->
  LT_licorDat

# Ports 6 and 8 have no temperature or moisture probes at the moment
DATE_SENSORS_INSTALLED <- ymd("2018-11-20")
LT_licorDat %>% 
  mutate(T5 = if_else(Port %in% c(6, 8) & Timestamp < DATE_SENSORS_INSTALLED, NA_real_, T5), 
         SMoist = if_else(Port %in% c(6, 8) & Timestamp < DATE_SENSORS_INSTALLED, NA_real_, SMoist)) ->
  LT_licorDat

save(LT_licorDat, file = "../outputs/LT_licordat.rda")
write_csv(LT_licorDat, "../outputs/LT_licor_data.csv")

ggplot(data = LT_licorDat, aes(x = Timestamp, y = Flux, group = Port, color = Port)) + 
  geom_line() + scale_colour_gradientn(colours = rainbow(9)) + 
  ggtitle("Long Term Chamber Measurements") #+ geom_text_repel()

qplot(Tcham, Flux, data = LT_licorDat, color = Timestamp) + facet_wrap(~Port)

cat("All done.\n")
