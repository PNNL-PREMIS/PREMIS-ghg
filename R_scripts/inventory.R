# Produce summary statistics of the tree inventory data
# PREMIS-ghg April 2018  
# Ben Bond-Lamberty

make_tree_data <- function(inventory_data, species_codes, plot_data) {
  
  # Join the two and check for any unknown species code
  inventory_data %>% 
    left_join(species_codes, by = "Species_code") ->
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
  
  # Compute basal area and stocking
  trees %>% 
    mutate(Plot = as.character(Plot)) %>% 
    left_join(select(plot_data, Site, Plot, Plot_area_m2), by = c("Site", "Plot")) ->
    trees_plots
  
  trees_plots
}



# # Histogram of trees by DBH
# p1 <- ggplot(trees, aes(DBH_cm, fill = Species)) + 
#   geom_histogram(position = "stack", binwidth = 5) + 
#   facet_grid(Salinity ~ Elevation)
# print(p1)
# ggsave("../outputs/tree_dbh.pdf", width = 8, height = 5)


# Pie chart of live basal area
# trees_plots %>% 
#   filter(State == "Alive") %>% 
#   group_by(Site, Salinity, Elevation, Species) %>% 
#   summarise(`BA (m2/ha)` = sum((DBH_cm / 100 / 2) ^ 2 * pi, na.rm = TRUE) / mean(Plot_area_m2) * 10000) %>% 
#   mutate(`BA (fraction)` = `BA (m2/ha)` / sum(`BA (m2/ha)`)) ->
#   tp
# p2 <- ggplot(tp, aes(x = "", y = `BA (fraction)`, fill = Species, labels = `BA (fraction)`)) + geom_col() + 
#   coord_polar("y") + 
#   facet_grid(Salinity ~ Elevation)
# print(p2)
# ggsave("../outputs/tree_species.pdf", width = 8, height = 5)
