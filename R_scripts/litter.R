## Function to read in a directory of litter data to combine in a long format for data visualization
## Created 2019-05-29

library(readr)
library(ggplot2)
library(dplyr)

read_litter_data <- function(path) {
# Read in litter directory and combine to one data frame
    litter_data <- list.files(path = path, full.names = TRUE) %>% 
    lapply(read_csv) %>% 
    bind_rows()
    
 #select useful columns 
    litter_data %>% 
      gather(key = "Litter_Type", value = "Mass_g", M_woody:M_leaf_other) %>% 
      select(-Date_weighed, -Notes)
}
