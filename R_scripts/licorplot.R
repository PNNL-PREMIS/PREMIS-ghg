# Script to graph and visualize licor data
# Stephanie Pennington | created April 2018

library(ggplot2)
theme_set(theme_bw())
library(ggrepel)
library(lubridate)
library(dplyr)
library(readr)

# Run read_dir function with licor data, merge with cores_collars.csv
#d <- data.frame(Timestamp = rep(1:5, times = 12), Flux = runif(120), Collar = rep(1:120, each = 5))
cat("Reading datasets...\n")
source("licordat.R")
licorDat <- read_dir("../licor_data/")
# `collarDat` holds information about the collars, based on collar number: its origin plot, and
# (if a transplant collar) into what hole it ended up 
collarDat <- read_csv("../design/cores_collars.csv", col_types = "cciiicic")
# `plotDat` holds information based on the plot code: longitude, latitude, area, 
# and salinity/elevation levels
plotDat <- read_csv("../design/plots.csv", col_types = "ccccddi")

cat("Joining datasets and calculating...\n")

# Merge these three datasets together based on collar number and plot name
licorDat %>% 
  left_join(collarDat, by = "Collar") %>% 
  rename(Origin_Plot = Plot) %>%
  select(-Site) %>% 
  left_join(plotDat, by = c("Origin_Plot" = "Plot")) %>%
  rename(Origin_Salinity = Salinity, Origin_Elevation = Elevation) %>%
  select(-Site) ->
  licorDat_full

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- select(collarDat, Collar, Destination_Plot = Plot)

# ...and then merge back into main data frame. Note that "Destination_Plot" holds the plot info
# for where each core ENDED UP, not where it STARTED
licorDat_full %>% 
  left_join(lookup_table, by = c("Core_placement" = "Collar")) %>% 
  # Remove duplicate variables
  select(-Longitude, -Latitude, -Plot_area_m2) %>% 
  left_join(plotDat, by = c("Destination_Plot" = "Plot")) %>%
  rename(Dest_Salinity = Salinity, Dest_Elevation = Elevation) ->
  licorDat_full

# Reorder labels by making them into factors
HML <- c("High", "Medium", "Low")
licorDat_full %>% 
  mutate(Origin_Salinity <- factor(Origin_Salinity, levels = HML),
         Origin_Elevation <- factor(Origin_Elevation, levels = HML),
         Dest_Salinity <- factor(Dest_Salinity, levels = HML),
         Dest_Elevation <- factor(Dest_Elevation, levels = HML),
         Date = paste(month(Timestamp), "/", day(Timestamp)),
         Group = paste(Origin_Plot, "->", Destination_Plot),
         Group = if_else(Experiment == "Control", "Control", Group)) ->
  licorDat_full

# Calculate daily averages for flux, temp, and soil moisture for each collar
daily_dat <- licorDat_full %>%
  group_by(Date, Experiment, Group, Destination_Plot, Dest_Salinity, Dest_Elevation,
           Origin_Plot, Origin_Salinity, Origin_Elevation,Collar) %>%
  summarise(n = n(), 
            Timestamp = mean(Timestamp),
            meanFlux = mean(Flux), sdFlux = sd(Flux), 
            meanSM = mean(SMoisture), meanTemp = mean(T5))

# Calculate standard deviation between collars at each plot
collar_to_collar_err <- licorDat_full %>% 
  group_by(Date, Experiment, Group, Destination_Plot, Origin_Plot, Collar) %>% 
  # First calculate collar means...
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  # ...and then plot mean and standard deviations
  summarise(n = n(), meanflux = mean(Flux), sdflux=sd(Flux),
            Timestamp = mean(Timestamp), Collars = paste(Collar, collapse = " "))

# Calculate CV for flux measurements
cv <- licorDat_full %>% 
  group_by(Date, Group, Collar) %>% 
  summarise(CV = sd(Flux) / mean(Flux), n = n())

# Calculate mean flux of all 3 observations in the meas. and the first 2 obs. in the meas.
fmean <- licorDat_full %>% 
  group_by(Date, Group, Collar) %>%
  summarize(n = n(), mean_gt_2 = mean(Flux), mean_2 = mean(Flux[1:2]))

cat("Making plots...\n")

#----- Plot time vs. flux -----
timeflux_plot <- ggplot(daily_dat, aes(x = Timestamp, y = meanFlux, color = Group, group = Collar)) +
  geom_point() +
  geom_line() +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Flux over time") +
  labs(x = "Date", y = "Flux (µmol m-2 s-1)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(timeflux_plot)
#ggsave("../outputs/timeflux.pdf", width = 8, height = 5)

#----- Plot time vs. flux with error bars -----
ggE <- ggplot(collar_to_collar_err, aes(x = Timestamp, y = sdflux, color = Group)) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = (sdflux/meanflux) - sdflux, ymax = (sdflux/meanflux) + sdflux), color = "black") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(ggE)

#----- Plot temperature vs. flux with regression line -----
q10_plot <- ggplot(daily_dat, aes(x = meanTemp, y = meanFlux, color = Dest_Elevation)) +
  geom_point() +
  geom_line(size = 1) +
  geom_smooth(method = "lm") +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Temperature (degC)", y = "Flux (µmol m-2 s-1)")
print(q10_plot)
#ggsave("../outputs/q10.pdf")

#----- Plot collar vs. CV with regression line -----
ggCV <- ggplot(data = cv, aes(x = Collar, y = CV, color = n)) +
  geom_point() +
  ggtitle("Coefficient of Variation")
#geom_text_repel(data = cv, aes(label = Collar))
print(ggCV)
#ggsave("../outputs/cv.pdf")

#----- Plot time vs. soil moisture -----
timesm_plot <- ggplot(daily_dat, aes(x = Date, y = meanSM, color = Group, group = Collar)) +
  geom_point() +
  geom_line() +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  ggtitle("Soil Moisture Over Time")
print(timesm_plot)
#ggsave("../outputs/timesm.pdf")

#----- Plot mean flux with all 3 measurements vs. mean flux with only first two meas. -----
# This is to test whether reducing observation size from 3 to 2 observations per measurement changes..
# .. the flux
var_test <- ggplot(fmean, aes(x = mean_gt_2, y = mean_2, color = n)) + 
  geom_abline(slope = 1, intercept = 0, color = "blue") +
  geom_point() + 
  labs(x = "Mean flux of all measurements", y = "Mean flux of first 2 measurements") +
  ggtitle("Mean Flux Per Collar (µmol m-2 s-1)")
print(var_test)
#ggsave("../diagnostics/mean_test.png")

figures <- list()
figures$timesm_plot <- timesm_plot 
figures$var_test <- var_test
figures$ggCV <- ggCV
figures$q10_plot <- q10_plot
figures$ggE <- ggE
figures$timeflux_plot <- timeflux_plot
save(figures, file = "../outputs/figures.rda")

cat("All done.\n")
