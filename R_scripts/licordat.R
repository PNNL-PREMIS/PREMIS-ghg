# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

library(tidyr)
library(lubridate)
library(dplyr)
library(readr)

#----- Function to parse a file and return data frame -----
read_licor_data <- function(filename) {
  file <- readLines(filename)  # Read in file
  cat("Reading...", filename, " lines =", length(file), "\n")
  
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  nobs <- length(file[grepl("^Obs#:", file)])
  date <- file[which(grepl("^Type", file)) + 1]
  temp20 <- file[grepl("^Comments:", file)]

  # Find beginning and end indices of raw data for each measurment
  tablestarts <- grep("^Type", file)
  tablestops <- grep("^CrvFitStatus", file)
  
  # Average values and place in matrix to be added to final df
  tcham <- matrix()
  t5 <- matrix()
  smoist <- matrix()
  for (i in seq_along(tablestarts)) {
    df <- readr::read_tsv(filename, skip = tablestarts[i], n_max = tablestops[i] - tablestarts[i] - 1,
                   col_names = c("Type", "Etime", "Date", "Tcham", "Pressure", "H2O", "CO2", 
                               "Cdry", "Tbench", "T1", "T2", "T3", "T4", "V1", "V2", "V3",
                               "V4", "LATITUDE", "LONGITUDE", "STATUS", "SPEED", "COURSE", 
                               "RH", "Tboard", "Vin", "CO2ABS", "H2OABS", "Hour", "DOY",
                               "RAWCO2", "RAWCO2REF", "RAWH2O", "RAWH2OREF"),
                   col_types = "ddTdddddddddddddddddddddddddddddd")
    index <- which(df$Type == 1)
    tcham[i] <- round(mean(df$Tcham[index]), digits = 2)
    t5[i] <- round(mean(df$V4[index]), digits = 2)
    smoist[i] <- round(mean(df$V3[index]), digits = 2)
  }
  
  # Separate into data frame
  sLabel <- separate(data.frame(label), label,into = c("name", "label"), sep = "\\t")  
  sFlux <- separate(data.frame(flux), flux, into = c("name", "flux"), sep = "\\t")
  sR2 <- separate(data.frame(r2), r2, into = c("name", "r2"), sep = "\\t")
  sDate <- separate(data.frame(date), date, into = c("type", "etime", "date", "time"), 
                    sep = "[:space:]" , extra = "drop") 
  sTemp20 <- separate(data.frame(temp20), temp20, into = c("name", "temp20"), sep = "\\t")
  
  tstamp <- ymd_hms((paste(sDate$date, sDate$time)))  # Parse into "POSIXct/POSIXt" - formatted timestamp
  lengths <- c(nrow(sLabel),nrow(sFlux), nrow(sR2), nrow(sDate))
  
  # Warning if missing a variable 
  if (!all(nrow(sLabel) == lengths)) {
    stop(sprintf("Variable lengths do not match \n File: %s \n nLabel:%s \n nFlux:%s \n nR2:%s \n nDate:%s \n", 
                 filename, nrow(sLabel), nrow(sFlux), nrow(sR2), nrow(sDate)))
  }
  
  tibble(Collar = as.numeric(sLabel$label),
         Timestamp = tstamp,
         Flux = as.numeric(sFlux$flux),
         R2 = as.numeric(sR2$r2),
         T20 = as.numeric(sTemp20$temp20),
         T5 = as.numeric(t5),
         Tcham = as.numeric(tcham),
         SMoisture = as.numeric(smoist))
}

#----- Function to loop through directory and call function to read licor data -----
read_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  bind_rows(list)
}

licorDat <- read_dir("../licor_data/")
collarDat <- read_csv("../design/cores_collars.csv")
plots <- read_csv("../design/plots.csv")

dat <- left_join(licorDat, collarDat, by = "Collar") %>% 
  rename(Origin_Plot = Plot) %>%
  select(-Site)
dat <- left_join(dat, plots, by = c("Origin_Plot" = "Plot")) %>%
  rename(Origin_Salinity = Salinity, Origin_Elevation = Elevation) %>%
  select(-Site)

# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- collarDat %>% 
  select(Collar, Destination_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
dat <- left_join(dat, lookup_table, by = c("Core_placement" = "Collar")) %>% 
  # Remove duplicate variables
  select(-Longitude, -Latitude, -Plot_area_m2)
dat <- left_join(dat, plots, by = c("Destination_Plot" = "Plot")) %>%
  rename(Dest_Salinity = Salinity, Dest_Elevation = Elevation)

# Reorder labels
dat$Origin_Salinity <- factor(dat$Origin_Salinity, levels = c("High", "Medium", "Low"))
dat$Origin_Elevation <- factor(dat$Origin_Elevation, levels = c("Low", "Medium", "High"))
dat$Dest_Salinity <- factor(dat$Dest_Salinity, levels = c("High", "Medium", "Low"))
dat$Dest_Elevation <- factor(dat$Dest_Elevation, levels = c("Low", "Medium", "High"))

dat$Date <- paste(month(dat$Timestamp), "/", day(dat$Timestamp))
dat$Group <- paste(dat$Origin_Plot, "->", dat$Destination_Plot)
dat$Group[dat$Experiment == "Control"] <- "Control"

save(dat, file = "../outputs/licordat.rda")