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
source("licordat.R")
licorDat <- read_dir("../licor_data/")
collarDat <- read_csv("../design/cores_collars.csv")
plots <- read_csv("../design/plots.csv")

dat <- left_join(licorDat, collarDat, by = "Collar") %>% 
  rename(Origin_Plot = Plot) %>%
  select(-Site)
dat <- left_join(dat, plots, by = c("Origin_Plot" = "Plot")) %>%
  rename(Origin_Salinity = Salinity, Origin_Elevation = Elevation) %>%
  select(-Site)

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- collarDat %>% 
  select(Collar, Destination_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
dat <- left_join(dat, lookup_table, by = c("Core_placement" = "Collar")) %>% 
  # Remove duplicate variables
  select(-Longitude, -Latitude, -Plot_area_m2)
dat <- left_join(dat, plots, by = c("Destination_Plot" = "Plot")) %>%
  rename(Dest_Salinity = Salinity, Dest_Elevation = Elevation)

# Reorder labels
dat$Origin_Salinity <- factor(dat$Origin_Salinity, levels = c("High", "Medium", "Low"))
dat$Origin_Elevation <- factor(dat$Origin_Elevation, levels = c("Low", "Medium", "High"))
dat$Dest_Salinity <- factor(dat$Dest_Salinity, levels = c("High", "Medium", "Low"))
dat$Dest_Elevation <- factor(dat$Dest_Elevation, levels = c("Low", "Medium", "High"))

dat$Date <- paste(month(dat$Timestamp), "/", day(dat$Timestamp))
dat$Group <- paste(dat$Origin_Plot, "->", dat$Destination_Plot)
dat$Group[dat$Experiment == "Control"] <- "Control"

# Calculate daily averages for flux, temp, and soil moisture for each collar
daily_dat <- dat %>%
  group_by(Date, Experiment, Group, Destination_Plot, Dest_Salinity, Dest_Elevation,
           Origin_Plot, Origin_Salinity, Origin_Elevation,Collar) %>%
  summarise(n = n(), meanFlux = mean(Flux), sdFlux = sd(Flux), meanSM = mean(SMoisture), meanTemp = mean(T5))

# Calculate standard deviation between collars at each plot
collar_to_collar_err <- dat %>% 
  group_by(Date, Experiment, Group, Destination_Plot, Origin_Plot, Collar) %>% 
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  summarise(n = n(), meanflux = mean(Flux), sdflux=sd(Flux),
            Timestamp = mean(Timestamp), Collars = paste(Collar, collapse = " "))

# Calculate CV for flux measurements
cv <- dat %>% 
  group_by(Date, Group, Collar) %>% 
  summarise(CV = sd(Flux) / mean(Flux), n = n())

# Calculate mean flux of all 3 observations in the meas. and the first 2 obs. in the meas.
fmean <- dat %>% 
  group_by(Date, Group, Collar) %>%
  summarize(mean3 = mean(Flux), mean2 = mean(Flux[1:2]))

#----- Plot time vs. flux -----
timeflux_plot <- ggplot(daily_dat, aes(x = Date, y = meanFlux, color = Group, group = Collar)) +
  geom_point() +
  geom_line() +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Flux over time") +
  labs(x = "Date", y = "Flux (umol m-2 s-1)") +
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
q10_plot <- ggplot(daily_dat, aes(x = meanTemp, y = meanFlux)) +
  geom_point() +
  geom_line(size = 1) +
  geom_smooth(method = "lm") +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Temperature (oC)", y = "Flux (umol m-2 s-1)")
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
var_test <- ggplot(fmean, aes(x = mean3, y = mean2)) + 
  geom_abline(slope = 1, intercept = 0, color = "blue") +
  geom_point() + 
  labs(x = "Mean flux of all measurements", y = "Mean flux of first 2 measurements") +
  ggtitle("Mean Flux Per Collar (umol m-2 s-1)")
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
