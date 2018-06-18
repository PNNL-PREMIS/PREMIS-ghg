# Process and analyze tree proximity with Licor flux data
# Stephanie Pennington | Created June 2018

library(readr)
library(dplyr)
library(ggplot2)
library(ggrepel)

# ----- Step 1: Read tree data -----
cat("Reading tree proximity data...\n")
proxDat <- read_csv("../inventory_data/collar_proximity.csv")
proxDat$Tag <- as.character(proxDat$Tag)

# ----- Step 2: QC/error check -----
# Warning generated if duplicate tag/tree is found
cat("Checking for duplicate trees...\n")
if (all(duplicated(proxDat$Tag) == FALSE) == FALSE) {
  stop(sprintf("\n Tags duplicated: %s", proxDat$Tag[duplicated(proxDat$Tag)]))
} else {
  cat("No duplicates found.")
}

# ----- Step 3: Read Licor and tre inventory data -----
cat("Reading Licor data...\n")
licorDat <- get(load("../outputs/licordat.rda"))
treeDat <- read_csv("../inventory_data/inventory.csv")

# ----- Step 4: Join datasets by collar -----
cat("Joining datasets...\n")
collar_to_tree_prox <- select(proxDat, -Date) %>% 
  left_join(treeDat, by = "Tag") %>%
  left_join(licorDat, by = "Collar")
  
collar_to_tree_prox$BA_sqcm <- (pi/(4*1000))*((collar_to_tree_prox$DBH_cm)^2)


# ----- Step 5: Plot distance vs. number of trees at each collar -----
tree_frequency <- proxDat %>% group_by(Collar, Distance_m) %>%  
  summarize(tree_num=n()) %>%
  mutate(n=cumsum(tree_num))

tree_dist <- ggplot(data = tree_frequency, aes(x = Distance_m, y = n, group = Collar, color = Collar)) +
  geom_line() +
#  geom_text_repel(aes(label = Collar)) +
  scale_color_gradient(low = "red", high = "purple") +
  ggtitle("Cumulative distribution of trees")
