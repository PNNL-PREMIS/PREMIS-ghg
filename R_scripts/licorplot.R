# Script to graph and visualize licor data
# Stephanie Pennington | created April 2018

# Run read_dir function with licor data, merge with cores_collars.csv
#d <- data.frame(Timestamp = rep(1:5, times = 12), Flux = runif(120), Collar = rep(1:120, each = 5))
licorDat <- read_dir("../licor_data/")
collarDat <- read.csv("../design/cores_collars.csv")
dat <- left_join(licorDat, collarDat)
dat <- plyr::rename(dat, c('Plot' = 'Origin_Plot'))

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

#dat$month <- month(dat$Timestamp)
#dat$day <- day(dat$Timestamp)
err <- dat %>% group_by(month, day, Destination_Plot, Origin_Plot, Collar) %>% 
  summarise(n = n(), Flux = mean(Flux), Timestamp = mean(Timestamp)) %>% 
  summarise(meanflux = mean(Flux), sdflux=sd(Flux))

#----- Plot time vs. flux -----
timeflux_plot <- ggplot(dat, aes(x = Timestamp, y = Flux, color = Plot, group = Collar)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  facet_grid(Lookup_Elevation ~ Lookup_Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) 
print(timeflux_plot)
ggsave("../outputs/timeflux.pdf")

#geom_text_repel(data = dat, mapping = aes(x = Timestamp, y = Flux, label = Collar)) 
#scale_color_gradientn(colors = blue2green2red(100))
#scale_color_brewer(palette = "Set1")
#scale_color_manual(values = c("darkolivegreen3", "coral3"))

#----- Plot time vs. flux with error bars -----
ggE <- ggplot(err, aes(x = err$day, y = err$meanflux, color = Destination_Plot, group = Destination_Plot)) +
  geom_point(data = err, size = 1) +
  geom_line(data = err, size = 1) +
  geom_errorbar(data = err, aes(x = err$day, ymin = err$meanflux - err$sdflux, ymax = err$meanflux + err$sdflux), color = "black")# +
  facet_grid(Dest_Elevation ~ Dest_Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

#----- Plot temperature vs. flux with regression line -----
q10_plot <- ggplot(dat, aes(x = Temperature, y = Flux)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  geom_smooth(method = "lm") +
  ggtitle("Temperature vs. Flux") +
  labs(x = "Temperature (°C)", y = "Flux (µmol m-2 s-1)")
print(q10plot)
ggsave("../outputs/q10.pdf")