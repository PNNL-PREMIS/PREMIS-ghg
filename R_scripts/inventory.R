# Produce summary statistics of the tree inventory data
# PREMIS-ghg April 2018  
# Ben Bond-Lamberty

library(readr)
library(ggplot2)
theme_set(theme_bw())
library(dplyr)

# Read the inventory and species codes data files
print("Reading the inventory data file...")
trees <- read_csv("../inventory_data/inventory.csv", col_types = "ccccdccc")
species_codes <- read_csv("../inventory_data/species_codes.csv", col_types = "ccc")

# Join the two and check for any unknown species code
trees %>% 
  left_join(species_codes, by = "Species_code") -> #%>% 
#  mutate(Species = if_else(is.na(Species_code), "???", Species),
#         Species_common = if_else(is.na(Species_code), "???", Species_common)) ->
  trees

unmatched <- filter(trees, is.na(Species))
if(nrow(unmatched)) {
  warning("Species codes not found:", unique(unmatched$Species_code))  
}

trees$Salinity <- paste("Salinity", substr(trees$Plot, 1, 1))
trees$Salinity <- factor(trees$Salinity, levels = paste("Salinity", c("H", "M", "L")))
trees$Elevation <- paste("Elevation", substr(trees$Plot, 3, 3))
trees$Elevation <- factor(trees$Elevation, levels = paste("Elevation", c("H", "M", "L")))

# Temporary - only plot SERC
trees <- filter(trees, Site == "SERC")

# Read the plot data file
print("Reading the plot data file...")
read_csv("../design/plots.csv", col_types = "cccccci") ->
  plots

# Histogram of trees by DBH
p1 <- ggplot(trees, aes(DBH_cm, fill = Species)) + 
  geom_histogram(position = "stack", binwidth = 5) + 
  facet_grid(Salinity ~ Elevation)
print(p1)
ggsave("../outputs/tree_dbh.pdf", width = 8, height = 5)


# Compute basal area and stocking
trees %>% 
  mutate(Plot = as.character(Plot)) %>% 
  left_join(select(plots, Site, Plot, Plot_area_m2), by = c("Site", "Plot")) ->
  trees_plots

# Pie chart of live basal area
trees_plots %>% 
  filter(State == "Alive") %>% 
  group_by(Site, Salinity, Elevation, Species) %>% 
  summarise(`BA (m2/ha)` = sum((DBH_cm / 100 / 2) ^ 2 * pi, na.rm = TRUE) / mean(Plot_area_m2) * 10000) %>% 
  mutate(`BA (fraction)` = `BA (m2/ha)` / sum(`BA (m2/ha)`)) ->
  tp
p2 <- ggplot(tp, aes(x = "", y = `BA (fraction)`, fill = Species, labels = `BA (fraction)`)) + geom_col() + 
  coord_polar("y") + 
  facet_grid(Salinity ~ Elevation)
print(p2)
ggsave("../outputs/tree_species.pdf", width = 8, height = 5)


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
