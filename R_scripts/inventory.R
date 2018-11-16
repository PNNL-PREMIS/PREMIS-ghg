# Produce summary statistics of the tree inventory data
# PREMIS-ghg April 2018  
# Ben Bond-Lamberty

make_tree_data <- function(inventory_data, species_codes, plot_data) {
  
  inventory_data <- readd("inventory_data")
  species_codes <- readd("species_codes")
  plot_data <- readd("plot_data")
  
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
  
  trees %>% 
    filter(Site == "SERC") %>% # temporary - only handle SERC
    left_join(select(plot_data, Site, Plot, Plot_area_m2), by = c("Site", "Plot")) 
}


