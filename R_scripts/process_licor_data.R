# 
# Stephanie Pennington | March 2018
# Function to process one licor file

library(lubridate)

process_licor_data <- function(raw_data, collar_data, plot_data, temp_data) {
  
  raw_data %>%
    rename(T5 = V4, 
           SMoisture = V3, 
           Collar = Label,      # we record Collar in the label field
           T20 = Comments) %>%  # we record T20 in the comments field
    mutate(T20 = as.numeric(T20),
           Collar = as.integer(Collar)) ->
    rawDat
  
  temp_data %>%
    mutate(Date = dmy(Date)) ->
    temp_data
  
  cat("Joining datasets and calculating...\n")
  
  # Merge these datasets together based on collar number and plot name
  licorDat <- left_join(rawDat, collar_data, by = "Collar") %>% 
    rename(Origin_Plot = Plot) %>%
    select(-Site) %>% 
    left_join(plot_data, by = c("Origin_Plot" = "Plot")) %>%
    rename(Origin_Salinity = Salinity, Origin_Elevation = Elevation) %>%
    select(-Site)
  
  # For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
  # rather, the core number of the hole). We actually need to know the plot. So create a lookup
  # table for this...
  lookup_table <- select(collar_data, Collar, Destination_Plot = Plot)
  
  # ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
  # where each core ENDED UP, not where it STARTED
  licorDat <- left_join(licorDat, lookup_table, by = c("Core_placement" = "Collar")) %>% 
    # Remove duplicate variables
    select(-Longitude, -Latitude, -Plot_area_m2) %>% 
    left_join(plot_data, by = c("Destination_Plot" = "Plot")) %>%
    rename(Dest_Salinity = Salinity, Dest_Elevation = Elevation)
  
  # Merge licor data with 5cm temperature taken by hand due to broken sensor
  licorDat %>% 
    mutate(Date = floor_date(Timestamp, unit = "day")) %>% 
    left_join(temp_data, by = c("Date", "Collar")) -> 
    licorDat
    
  
  
  
  
  # Reorder labels by making them into factors and return
  HML <- c("High", "Medium", "Low")
  licorDat %>% 
    mutate(Origin_Salinity <- factor(Origin_Salinity, levels = HML),
           Origin_Elevation <- factor(Origin_Elevation, levels = HML),
           Dest_Salinity <- factor(Dest_Salinity, levels = HML),
           Dest_Elevation <- factor(Dest_Elevation, levels = HML),
           Date = paste(month(Timestamp), "/", day(Timestamp)),
           Group = paste(Origin_Plot, "->", Destination_Plot),
           Group = if_else(Experiment == "Control", "Control", Group))
  
}


# Calculate daily averages for flux, temp, and soil moisture for each collar
calculate_licor_daily_data <- function(licor_data) {
  cat("Calculating daily averages, CVs, etc...\n")
  licor_data %>% 
    group_by(Date, Experiment, Group, Destination_Plot, Dest_Salinity, Dest_Elevation,
             Origin_Plot, Origin_Salinity, Origin_Elevation, Collar) %>%
    summarise(n = n(), 
              Timestamp = mean(Timestamp),
              meanFlux = mean(Flux), 
              sdFlux = sd(Flux), 
              meanSM = mean(SMoisture), 
              meanT5 = mean(T5), 
              meanT20 = mean(T20)) %>% 
    ungroup
}

process_continuous_data <- function(raw_data) {
  
  # Ports 6 and 8 have no temperature or moisture probes at the moment
  DATE_SENSORS_INSTALLED <- ymd("2018-11-20")
  raw_data %>% 
    filter(Port > 0) %>% 
    rename(T5 = V3, SMoist = V2) %>% 
    mutate(T5 = if_else(Port %in% c(6, 8) & Timestamp < DATE_SENSORS_INSTALLED, NA_real_, T5), 
           SMoist = if_else(Port %in% c(6, 8) & Timestamp < DATE_SENSORS_INSTALLED, NA_real_, SMoist))
}