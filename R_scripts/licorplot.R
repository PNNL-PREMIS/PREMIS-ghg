# Script to graph and visualize licor data
# Stephanie Pennington | created April 2018

library(tidyr)
library(ggplot2)
theme_set(theme_bw())
library(ggrepel)
library(dplyr)
library(readr)

dat <- get(load("../outputs/licordat.rda"))

# Calculate daily averages for flux, temp, and soil moisture for each collar
daily_dat <- dat %>%
  group_by(Date, Experiment, Group, Destination_Plot, Dest_Salinity, Dest_Elevation,
<<<<<<< HEAD
           Origin_Plot, Origin_Salinity, Origin_Elevation, Collar) %>%
  summarise(n = n(), meanFlux = mean(Flux), sdFlux = sd(Flux), meanSM = mean(SMoisture), meanTemp = mean(T5))
=======
           Origin_Plot, Origin_Salinity, Origin_Elevation,Collar) %>%
  summarise(n = n(), 
            Timestamp = mean(Timestamp),
            meanFlux = mean(Flux), sdFlux = sd(Flux), 
            meanSM = mean(SMoisture), meanTemp = mean(T5))
>>>>>>> d5449efa767c194ef999b8d092e7fa188b4ea94f

# Calculate standard deviation between collars at each plot
collar_to_collar_err <- dat %>% 
  group_by(Date, Experiment, Group, Destination_Plot, Origin_Plot, Collar) %>% 
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  summarise(n = n(), meanflux = mean(Flux), sdflux=sd(Flux),
            Timestamp = mean(Timestamp), Collars = paste(Collar, collapse = " "))

# Calculate CV between observations
cv_obs <- dat %>% 
  group_by(Date, Group, Collar) %>% 
  summarise(CV = sd(Flux) / mean(Flux), n = n())

# Calculate CV between groups
cv_exp <- dat %>% 
  group_by(Date, Group, Experiment) %>%
  summarize(CV = sd(Flux) / mean(Flux), n = n())

# Calculate mean flux of all 3 observations in the meas. and the first 2 obs. in the meas.
fmean <- dat %>% 
  group_by(Date, Group, Collar) %>%
  summarize(mean3 = mean(Flux), mean2 = mean(Flux[1:2]))

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
var_test <- ggplot(fmean, aes(x = mean3, y = mean2)) + 
  geom_abline(slope = 1, intercept = 0, color = "blue") +
  geom_point() + 
  labs(x = "Mean flux of all measurements", y = "Mean flux of first 2 measurements") +
  ggtitle("Mean Flux Per Collar (µmol m-2 s-1)")
print(var_test)
#ggsave("../diagnostics/mean_test.png")

#----- Plot CV between observations over time -----
ggCV_obs <- ggplot(cc_obs, aes()) 


figures <- list()
figures$timesm_plot <- timesm_plot 
figures$var_test <- var_test
figures$ggCV <- ggCV
figures$q10_plot <- q10_plot
figures$ggE <- ggE
figures$timeflux_plot <- timeflux_plot
save(figures, file = "../outputs/figures.rda")
