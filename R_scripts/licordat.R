# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

library(tidyr)
library(lubridate)
library(dplyr)
library(readr)

source("read_licor_data.R")


read_licor_dir("../licor_data/") %>%
  select(-Port) %>%           # not continuous data, so remove
  rename(T20 = Comments) %>%  # we record T20 in the comments field
  rename(Collar = Label) %>%  # we record Collar in the Label field
  mutate(T20 = as.numeric(T20),
         Collar = as.numeric(Collar)) ->
  rawDat
# `collarDat` holds information about the collars, based on collar number: 
# its origin plot, and (if a transplant collar) into what hole it ended up 
collarDat <- read_csv("../design/cores_collars.csv", col_types = "cciiicic")
# `plotDat` holds information based on the plot code: longitude, latitude,
# area, and salinity/elevation levels
plots <- read_csv("../design/plots.csv", col_types = "ccccddi")

cat("Joining datasets and calculating...\n")

# Merge these three datasets together based on collar number and plot name
licorDat <- left_join(rawDat, collarDat, by = "Collar") %>% 
  rename(Origin_Plot = Plot) %>%
  select(-Site) %>% 
  left_join(plots, by = c("Origin_Plot" = "Plot")) %>%
  rename(Origin_Salinity = Salinity, Origin_Elevation = Elevation) %>%
  select(-Site)

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- select(collarDat, Collar, Destination_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
licorDat <- left_join(licorDat, lookup_table, by = c("Core_placement" = "Collar")) %>% 
  # Remove duplicate variables
  select(-Longitude, -Latitude, -Plot_area_m2) %>% 
  left_join(plots, by = c("Destination_Plot" = "Plot")) %>%
  rename(Dest_Salinity = Salinity, Dest_Elevation = Elevation)

# Reorder labels by making them into factors
HML <- c("High", "Medium", "Low")
licorDat %>% 
  mutate(Origin_Salinity <- factor(Origin_Salinity, levels = HML),
         Origin_Elevation <- factor(Origin_Elevation, levels = HML),
         Dest_Salinity <- factor(Dest_Salinity, levels = HML),
         Dest_Elevation <- factor(Dest_Elevation, levels = HML),
         Date = paste(month(Timestamp), "/", day(Timestamp)),
         Group = paste(Origin_Plot, "->", Destination_Plot),
         Group = if_else(Experiment == "Control", "Control", Group)) ->
  licorDat

cat("Saving data...\n")
save(licorDat, file = "../outputs/licordat.rda")
write_csv(licorDat, "../outputs/licor_data.csv")
cat("All done.\n")
