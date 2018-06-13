# Process and analyze tree proximity with Licor flux data
# Stephanie Pennington | Created June 2018

library(readr)
library(dplyr)

# ----- Step 1: Read tree data -----
cat("Reading tree proximity data...\n")
proxDat <- read_csv("../inventory_data/collar_proximity.csv")
proxDat$Tag <- as.character(proxDat$Tag)

# ----- Step 2: QC/error check -----
#create error message
#plot

# ----- Step 3: Read Licor and tre inventory data -----
cat("Reading Licor data...\n")
licorDat <- get(load("../outputs/licordat.rda"))
treeDat <- read_csv("../inventory_data/inventory.csv")

# ----- Step 4: Join datasets by collar -----
cat("Joining datasets...\n")
collar_to_tree_prox <- select(proxDat, -Date) %>% 
  left_join(licorDat, by = "Collar") %>%
  left_join(treeDat, by = "Tag")

# ----- Step 5: Plot distance vs. number of trees at each collar -----
ggplot(data = collar_to_tree_prox, aes(x = Distance_m, y = ))