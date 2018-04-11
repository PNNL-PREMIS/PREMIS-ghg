# Script to graph and visualize licor data
# Stephanie Pennington | created April 2018

# Run read_dir function with licor data, merge with cores_collars.csv
#d <- data.frame(Timestamp = rep(1:5, times = 12), Flux = runif(120), Collar = rep(1:120, each = 5))
licorDat <- read_dir("/Users/penn529/Documents/GitHub/PREMIS-ghg/licor_data/")
collarDat <- read.csv("/Users/penn529/Desktop/PREMIS/cores_collars.csv")
dat <- left_join(licorDat, collarDat)

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- collarDat %>% 
  select(Collar, Lookup_Plot = Plot)

#lookup_table <- select(collarDat, Core, Lookup_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
dat <- left_join(dat, lookup_table, by = c("Core_placement" = "Collar"))

# Extract salinity and elevation information
dat$Salinity <- substr(dat$Plot, 1, 1)
dat$Salinity <- factor(dat$Salinity, levels = c("H", "M", "L"))
dat$Elevation <- substr(dat$Plot, 3, 3)
dat$Elevation <- factor(dat$Elevation, levels = c("L", "M", "H"))

err <- sd(dat$Flux)

#----- Plot time vs. flux -----
gg <- ggplot(dat, aes(x = Timestamp, y = Flux, color = Lookup_Plot, group = Collar)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  facet_grid(Elevation ~ Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) 

#geom_text_repel(data = dat, mapping = aes(x = Timestamp, y = Flux, label = Collar)) 
#scale_color_gradientn(colors = blue2green2red(100))
#scale_color_brewer(palette = "Set1")
#scale_color_manual(values = c("darkolivegreen3", "coral3"))

#----- Plot time vs. flux with error bars -----
ggE <- ggplot(dat, aes(x = Timestamp, y = Flux, color = Lookup_Plot, group = Plot)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  geom_errorbar(data = dat, aes(x = Timestamp, ymin = Flux - err, ymax = Flux + err), color = "black") +
  facet_grid(Elevation ~ Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

#----- Plot temperature vs. flux with regression line -----
temp <- ggplot(dat, aes(x = Timestamp, y = Temperature)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) +
  geom_smooth(method = "lm")
