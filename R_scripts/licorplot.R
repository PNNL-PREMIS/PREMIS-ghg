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
licorDat <- read_dir("../licor_data/")
collarDat <- read_csv("../design/cores_collars.csv")
dat <- left_join(licorDat, collarDat, by = "Collar") %>% 
  rename(Origin_Plot = Plot)

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- collarDat %>% 
  select(Collar, Destination_Plot = Plot)

#lookup_table <- select(collarDat, Core, Lookup_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
dat <- left_join(dat, lookup_table, by = c("Core_placement" = "Collar"))

# Extract salinity and elevation information
dat$Dest_Salinity <- substr(dat$Destination_Plot, 1, 1)
dat$Dest_Salinity <- factor(dat$Dest_Salinity, levels = c("H", "M", "L"))
dat$Dest_Elevation <- substr(dat$Destination_Plot, 3, 3)
dat$Dest_Elevation <- factor(dat$Dest_Elevation, levels = c("L", "M", "H"))

# Extract salinity and elevation information
dat$Origin_Salinity <- substr(dat$Origin_Plot, 1, 1)
dat$Origin_Salinity <- factor(dat$Origin_Salinity, levels = c("H", "M", "L"))
dat$Origin_Elevation <- substr(dat$Origin_Plot, 3, 3)
dat$Origin_Elevation <- factor(dat$Origin_Elevation, levels = c("L", "M", "H"))

dat$Month <- month(dat$Timestamp)
dat$Day <- day(dat$Timestamp)
dat$Time <- time(dat$Timestamp)
# Calculate standard deviation between collars at each plot
err <- dat %>% 
  group_by(Month,Day, Destination_Plot, Origin_Plot, Collar) %>% 
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  summarise(meanflux = mean(Flux), sdflux=sd(Flux))

# Calculate CV for flux measurements
cv <- dat %>% 
  group_by(Month, Collar) %>% 
  summarise(CV = sd(Flux) / mean(Flux), n = n())

# Calculate mean flux of all 3 observations in the meas. and the first 2 obs. in the meas.
fmean <- dat %>% 
  group_by(Month, Day, Collar) %>%
  summarize(mean3 = mean(Flux), mean2 = mean(Flux[1:2]))

#----- Plot time vs. flux -----
timeflux_plot <- ggplot(dat, aes(x = Timestamp, y = Flux, color = Origin_Plot, group = Collar)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 0.5) +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Date", y = "Flux (umol m-2 s-1)")
print(timeflux_plot)
ggsave("../outputs/timeflux.pdf")

#geom_text_repel(data = dat, mapping = aes(x = Timestamp, y = Flux, label = Collar)) 
#scale_color_gradientn(colors = blue2green2red(100))
#scale_color_brewer(palette = "Set1")
#scale_color_manual(values = c("darkolivegreen3", "coral3"))

#----- Plot time vs. flux with error bars -----
ggE <- ggplot(err, aes(x = err$Day, y = err$meanflux, color = Destination_Plot)) +
  geom_point(data = err, size = 1) +
  geom_line(data = err, size = 1) +
  geom_errorbar(data = err, aes(x = err$Day, ymin = err$meanflux - err$sdflux, ymax = err$meanflux + err$sdflux), color = "black") #+
facet_grid(Dest_Elevation ~ Dest_Salinity) #+
theme(axis.text.x = element_text(angle = 90, hjust = 1))
#print(ggE)


#----- Plot temperature vs. flux with regression line -----
q10_plot <- ggplot(dat, aes(x = T20, y = Flux)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  geom_smooth(method = "lm") +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Temperature (oC)", y = "Flux (umol m-2 s-1)")
#print(q10_plot)
#ggsave("../outputs/q10.pdf")

#----- Plot collar vs. CV with regression line -----
ggCV <- ggplot(data = cv, aes(x = Collar, y = CV, color = n)) +
  geom_point() +
  ggtitle("Coefficient of Variation")
#geom_text_repel(data = cv, aes(label = Collar))
#print(ggCV)
#ggsave("../outputs/cv.pdf")

#----- Plot time vs. soil moisture -----
timesm_plot <- ggplot(dat, aes(x = Timestamp, y = SMoisture, color = Origin_Plot, group = Collar)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 0.5) +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  ggtitle("Soil Moisture Over Time")
#print(timesm_plot)
#ggsave("../outputs/timesm.pdf")

#----- Plot mean flux with all 3 measurements vs. mean flux with only first two meas. -----
# This is to test whether reducing observation size from 3 to 2 observations per measurement changes..
# .. the flux
var_test <- ggplot(fmean, aes(x = mean3, y = mean2)) + 
  geom_abline(slope = 1, intercept = 0, color = "blue") +
  geom_point() + 
  labs(x = "Mean flux of all measurements", y = "Mean flux of first 2 measurements") +
  ggtitle("Mean Flux Per Collar (umol m-2 s-1)")
#print(var_test)
#ggsave("../diagnostics/mean_test.png")

figures <- list()
figures$timesm_plot <- timesm_plot 
figures$var_test <- var_test
figures$ggCV <- ggCV
figures$q10_plot <- q10_plot
figures$ggE <- ggE
figures$timeflux_plot <- timeflux_plot
save(figures, file = "../outputs/figures.rda")
