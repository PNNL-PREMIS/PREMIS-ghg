# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

#----- Function to parse a file and return data frame -----
packages <- c("tidyr", "lubridate", "ggplot2", "plyr", "dplyr", "colorRamps")
lapply(packages, library, character.only = TRUE)

read_licor_data <- function(filename) {
  file <- readLines(filename)  # Read in file
  cat("Reading...", filename, " lines =", length(file), "\n")
  
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  nobs <- length(file[grepl("^Obs#:", file)])
  date <- file[which(grepl("^Type", file)) + 1]
  temp <- file[grepl("^Comments:", file)]
  
  # Separate into data frame
  sLabel <- separate(data.frame(label), label,into = c("name", "label"), sep = "\\t")  
  sFlux <- separate(data.frame(flux), flux, into = c("name", "flux"), sep = "\\t")
  sR2 <- separate(data.frame(r2), r2, into = c("name", "r2"), sep = "\\t")
  sDate <- separate(data.frame(date), date, into = c("type", "etime", "date", "time"), 
                    sep = "[:space:]" , extra = "drop") 
  sTemp <- separate(data.frame(temp), temp, into = c("name", "temp"), sep = "\\t")
  
  tstamp <- ymd_hms((paste(sDate$date, sDate$time)))  # Parse into "POSIXct/POSIXt" - formatted timestamp
  lengths <- c(nrow(sLabel),nrow(sFlux), nrow(sR2), nrow(sDate))
  
  # Warning if missing a variable 
  if (!all(nrow(sLabel) == lengths)) {
    stop(sprintf("Variable lengths do not match \n File: %s \n nLabel:%s \n nFlux:%s \n nR2:%s \n nDate:%s \n", 
                 filename, nrow(sLabel), nrow(sFlux), nrow(sR2), nrow(sDate)))
  }
  
  data.frame(Collar = as.numeric(sLabel$label),
             Timestamp = tstamp,
             Flux = as.numeric(sFlux$flux),
             R2 = as.numeric(sR2$r2),
             Temperature = as.numeric(sTemp$temp),
             stringsAsFactors = FALSE)
}

# Test function with sample data
read_licor_data("Test51117.81x")
read_licor_data("SampleMultiplex.81x")
read_licor_data("SR_burn_28_july-201720910.81x")

#----- Function to loop through directory and call function to read licor data -----
read_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  ldply(list)
}

apple <- read_dir("/Users/penn529/Desktop/apple_data/")
x <- read_dir("/Users/penn529/Desktop/PREMIS/licor_test_data/")
read_dir("/Users/penn529/Desktop/PREMIS/licor_test_data/SJ_6_1_16/")
plant <- read_dir("/Users/penn529/Desktop/plant_data/")
licorDat <- read_dir("/Users/penn529/Documents/GitHub/PREMIS-ghg/licor_data/")

# Create practice df with multiple collars
# merge with cores_collars.csv
# practice plotting with ggplot
d <- data.frame(Timestamp = rep(1:5, times = 12), Flux = runif(120), Collar = rep(1:120, each = 5))
collarDat <- read.csv("/Users/penn529/Desktop/PREMIS/cores_collars.csv")
y <- merge(d, collarDat)


dat <- left_join(licorDat, collarDat)


# For any transplant core X, we know (in "Core_placement") the hole in which it ended up (or
# rather, the core number of the hole). We actually need to know the plot. So create a lookup
# table for this...
lookup_table <- collarDat %>% 
  select(Collar, Lookup_Plot = Plot)


#lookup_table <- select(collarDat, Core, Lookup_Plot = Plot)

# ...and then merge back into main data frame. Now "Lookup_Plot" holds the plot info for
# where each core ENDED UP, not where it STARTED
dat <- left_join(y, lookup_table, by = c("Core_placement" = "Collar"))


# Extract salinity and elevation information
dat$Salinity <- substr(dat$Plot, 1, 1)
dat$Salinity <- factor(dat$Salinity, levels = c("H", "M", "L"))
dat$Elevation <- substr(dat$Plot, 3, 3)
dat$Elevation <- factor(dat$Elevation, levels = c("L", "M", "H"))

gg <- ggplot(dat, aes(x = Timestamp, y = Flux, color = Lookup_Plot, group = Collar)) +
  geom_point(data = dat, size = 1) +
  geom_line(data = dat, size = 1) + #scale_color_gradientn(colors = blue2green2red(100)) +
  facet_grid(Elevation ~ Salinity) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) #+
  geom_text_repel(data = dat, mapping = aes(x = Timestamp, y = Flux, label = Collar)) 

  #scale_color_brewer(palette = "Set1")
  #scale_color_manual(values = c("darkolivegreen3", "coral3"))  #plot separately based on Label


