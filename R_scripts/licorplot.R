# Script to graph and visualize licor data
# Stephanie Pennington | created April 2018

library(tidyr)
library(ggplot2)
theme_set(theme_bw())
library(ggrepel)
library(dplyr)
library(readr)

cat("Reading data...\n")
licorDat <- get(load("../outputs/licordat.rda"))
licorDat$Dest_Elevation <- factor(paste(licorDat$Dest_Elevation, "elevation"), 
                             levels = c("Low elevation", "Medium elevation", "High elevation"))
licorDat$Dest_Salinity <- factor(paste(licorDat$Dest_Salinity, "salinity"), 
                            levels = c("Low salinity", "Medium salinity", "High salinity"))

# Calculate daily averages for flux, temp, and soil moisture for each collar
cat("Calculating daily averages, CVs, etc...\n")
daily_dat <- licorDat %>%
  group_by(Date, Experiment, Group, Destination_Plot, Dest_Salinity, Dest_Elevation,
           Origin_Plot, Origin_Salinity, Origin_Elevation,Collar) %>%
  summarise(n = n(), 
            Timestamp = mean(Timestamp),
            meanFlux = mean(Flux), sdFlux = sd(Flux), 
            meanSM = mean(SMoisture), meanTemp = mean(T5))

# Calculate treaetments means and s.d.
daily_dat_means <- daily_dat %>% 
  ungroup %>% 
  mutate(ControlGroup = if_else(Group == "Control", "Control (true)", "Transplant")) %>% 
  group_by(Experiment, Origin_Plot, Dest_Salinity, Dest_Elevation, Destination_Plot, Date, Group, ControlGroup) %>%  
  summarise(Timestamp = mean(Timestamp), sdFlux = sd(meanFlux), meanFlux = mean(meanFlux), meanSM = mean(meanSM))
daily_dat_means$Experiment[daily_dat_means$Origin_Plot == daily_dat_means$Destination_Plot] <- "Control"

# Calculate standard deviation and CV between collars at each plot
cv_btwn_collars <- licorDat %>% 
  group_by(Date, Group, Experiment, Collar) %>%
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  summarize( n = n(), CV = sd(Flux) / mean(Flux), meanflux = mean(Flux), sdflux=sd(Flux),
             Timestamp = mean(Timestamp), Collars = paste(Collar, collapse = " "))

# Calculate CV between observations
cv_btwn_obs <- licorDat %>% 
  group_by(Date, Group, Collar) %>% 
  summarise(CV = sd(Flux) / mean(Flux), n = n(), Timestamp = mean(Timestamp))

# Calculate mean flux of all 3 observations in the meas. and the first 2 obs. in the meas.
fluxMean <- licorDat %>% 
  group_by(Date, Group, Collar) %>%
  summarize(n = n(), mean_gt_2 = mean(Flux), mean_2 = mean(Flux[1:2]))

cat("Making plots...\n")

#----- Plot time vs. flux at DESTINATION plot-----
timeflux_plot_dest <- ggplot(daily_dat, aes(x = Timestamp, y = meanFlux, color = Group, group = Collar)) +
  geom_point() +
  geom_line() +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Flux over time - destination plots") +
  labs(x = "Date", y = expression(Flux~(µmol~CO[2]~m^-2~s^-1))) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(timeflux_plot_dest)
#ggsave("../outputs/timeflux_dest.pdf", width = 8, height = 5)

timeflux_plot_dest_means <- ggplot(daily_dat_means, aes(x = Timestamp, y = meanFlux, color = Experiment, group = Group)) +
  geom_point() +
  geom_line(aes(linetype = ControlGroup)) +
  geom_errorbar(aes(ymin = meanFlux - sdFlux, ymax = meanFlux + sdFlux)) +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Flux over time - destination plots") +
  labs(x = "Date", y = expression(Flux~(µmol~CO[2]~m^-2~s^-1))) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(timeflux_plot_dest_means)

sm_plot_dest_means <- ggplot(daily_dat_means, aes(x = Timestamp, y = meanSM, color = Experiment, group = Group)) +
  geom_point() +
  geom_line(aes(linetype = ControlGroup)) +
#  geom_errorbar(aes(ymin = meanFlux - sdFlux, ymax = meanFlux + sdFlux)) +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  ggtitle("Soil moisture over time - destination plots") +
  labs(x = "Date") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(sm_plot_dest_means)

#----- Plot time vs. flux at ORIGIN plot-----
timeflux_plot_origin <- ggplot(daily_dat, aes(x = Timestamp, y = meanFlux, color = Group, group = Collar)) +
  geom_point() +
  geom_line() +
  facet_grid(Origin_Elevation ~ Origin_Salinity) +
  ggtitle("Flux over time - origin plots") +
  labs(x = "Date", y = expression(Flux~(µmol~CO[2]~m^-2~s^-1))) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
print(timeflux_plot_origin)
#ggsave("../outputs/timeflux_origin.p

#----- Plot time vs. flux with error bars -----
ggE <- ggplot(cv_btwn_collars, aes(x = Timestamp, y = meanflux, group = Group, color = Experiment)) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = meanflux - sdflux, ymax = meanflux + sdflux)) +
  facet_wrap(~ Group, ncol = 3) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(x = "Date", y = expression(Flux~(µmol~CO[2]~m^-2~s^-1))) +
  ggtitle("Treatment means and errors")
print(ggE)

#----- Plot temperature vs. flux with regression line -----
q10_plot <- ggplot(daily_dat, aes(x = meanTemp, y = meanFlux, color = Dest_Elevation)) +
  geom_point() +
  geom_smooth(method = "lm") +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Temperature (degC)", y = "Flux (µmol m-2 s-1)")
print(q10_plot)
#ggsave("../outputs/q10.pdf")

#----- Plot collar CV (within treatment) over time -----
ggCV_btwn_collars <- ggplot(data = cv_btwn_collars, aes(x = Timestamp, y = CV, color = Group)) +
  geom_point() +
  ggtitle("Coefficient of Variation Between Collars")
print(ggCV_btwn_collars)
#ggsave("../outputs/cv_btwn_exp.pdf")

#----- Plot observation CV (within collar) over time -----
ggCV_btwn_obs <- ggplot(cv_btwn_obs, aes(x = Timestamp, y = CV)) +
  geom_point() +
  ggtitle("Coefficient of Variation Between Measurements")
print(ggCV_btwn_obs)

#----- Plot time vs. soil moisture -----
timesm_plot <- ggplot(daily_dat, aes(x = Timestamp, y = meanSM, color = Group, group = Collar)) +
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
var_test <- ggplot(fluxMean, aes(x = mean_gt_2, y = mean_2, color = n)) + 
  geom_abline(slope = 1, intercept = 0, color = "blue") +
  geom_point() + 
  labs(x = "Mean flux of all measurements", y = "Mean flux of first 2 measurements") +
  ggtitle("Mean Flux Per Collar (µmol m-2 s-1)")
print(var_test)
#ggsave("../diagnostics/mean_test.png")

figures <- list()
figures$timeflux_plot_dest <- timeflux_plot_dest
figures$timeflux_plot_dest_means <- timeflux_plot_dest_means
figures$sm_plot_dest_means <- sm_plot_dest_means
figures$timeflux_plot_origin <- timeflux_plot_origin
figures$var_test <- var_test
figures$ggCV_btwn_collars <- ggCV_btwn_collars
figures$ggCV_btwn_obs <- ggCV_btwn_obs
figures$q10_plot <- q10_plot
figures$ggE <- ggE
figures$timesm_plot <- timesm_plot
save(figures, file = "../outputs/figures.rda")

cat("All done.\n")
