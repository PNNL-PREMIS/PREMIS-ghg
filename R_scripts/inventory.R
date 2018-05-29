# Produce summary statistics of the tree inventory data
# PREMIS-ghg April 2018  
# Ben Bond-Lamberty

library(readr)
library(ggplot2)
theme_set(theme_bw())
library(dplyr)

# Read the inventory data file
print("Reading the inventory data file...")
read_csv("../inventory_data/inventory.csv", col_types = "ccccdccc") ->
  trees

trees$Salinity <- paste("Salinity", substr(trees$Plot, 1, 1))
trees$Salinity <- factor(trees$Salinity, levels = paste("Salinity", c("H", "M", "L")))
trees$Elevation <- paste("Elevation", substr(trees$Plot, 3, 3))
trees$Elevation <- factor(trees$Elevation, levels = paste("Elevation", c("H", "M", "L")))

# Read the plot data file
print("Reading the plot data file...")
read_csv("../design/plots.csv", col_types = "cccccci") ->
  plots

# Histogram of trees by DBH
p1 <- ggplot(trees, aes(DBH_cm, fill = Species)) + 
  geom_histogram(position = "stack", binwidth = 5) + 
  facet_grid(Salinity ~ Elevation)
print(p1)
ggsave("../outputs/tree_dbh.pdf")

# Compute basal area and stocking
trees %>% 
  mutate(Plot = as.character(Plot)) %>% 
  left_join(plots, by = c("Site", "Plot")) ->
  trees_plots

trees_plots %>% 
  group_by(Site, Plot) %>% 
  summarise(n = n(), Plot_area_m2 = mean(Plot_area_m2)) %>% 
  mutate(`Trees (/ha)` = n / Plot_area_m2 * 10000) %>% 
  print

trees_plots %>% 
  group_by(Site, Plot) %>% 
  summarise(`BA (m2/ha)` = sum((DBH_cm / 100 / 2) ^ 2 * pi, na.rm = TRUE) / mean(Plot_area_m2) * 10000) %>% 
  print

print("All done.")
