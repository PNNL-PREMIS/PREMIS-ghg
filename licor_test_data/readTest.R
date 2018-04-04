# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington March 2018

# Parse a file and return data frame

packages <- c("tidyr", "lubridate", "ggplot2", "plyr")
lapply(packages, library, character.only = TRUE)

read_licor_data <- function(filename) {
  file <- readLines(filename)  # Read in file
  cat("Reading...", filename, " lines =", length(file), "\n")
  
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  nobs <- length(file[grepl("^Obs#:", file)])
  date <- file[which(grepl("^Type", file)) + 1]
  
  # Separate into data frame
  sLabel <- separate(data.frame(label), label,into = c("name", "label"), sep = "\\t")  
  sFlux <- separate(data.frame(flux), flux, into = c("name", "flux"), sep = "\\t")
  sR2 <- separate(data.frame(r2), r2, into = c("name", "r2"), sep = "\\t")
  sDate <- separate(data.frame(date), date, into = c("type", "etime", "date", "time"), 
                     sep = "[:space:]" , extra = "drop") 
  
  tstamp <- ymd_hms((paste(sDate$date, sDate$time)))  # Parse into "POSIXct/POSIXt" - formatted timestamp
  lengths <- c(nrow(sLabel),nrow(sFlux), nrow(sR2), nrow(sDate))
  
  # Warning if missing a variable 
  if (!all(nrow(sLabel) == lengths)) {
  
    stop(sprintf("Variable lengths do not match \n File: %s \n nLabel:%s \n nFlux:%s \n nR2:%s \n nDate:%s \n", 
                 filename, nrow(sLabel), nrow(sFlux), nrow(sR2), nrow(sDate)))
  }
  
  data.frame(Collar = sLabel$label,
                     Timestamp = tstamp,
                     Flux = as.numeric(sFlux$flux),
                     R2 = as.numeric(sR2$r2),
                     stringsAsFactors = FALSE)
}

read_licor_data("Test51117.81x")
read_licor_data("SampleMultiplex.81x")
read_licor_data("SR_burn_28_july-201720910.81x")

# Function to loop through directory and call function to read licor data
read_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  ldply(list)
}

apple <- read_dir("apple_data/")
x <- read_dir("/Users/penn529/Desktop/PREMIS/licor_test_data/")
read_dir("/Users/penn529/Desktop/PREMIS/licor_test_data/SJ_6_1_16/")


# Create practice df with 50-60 collars
# merge with cores_collars.csv
# practice plotting with ggplot
d <- data.frame(Timestamp = rep(1:5, times = 12), Flux = runif(120), Collar = rep(1:120, each = 5))
collardata <- read.csv("../design/cores_collars.csv")
y <- merge(d, collardata)

color = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]

# Reorder facet levels
y$Plot <- factor(y$Plot, levels = c("HSLE", "MSLE", "LSLE", "HSME", "MSME", "LSME", "HSHE", "MSHE", "LSHE"))

gg <- ggplot(y, aes(x = Timestamp, y = Flux, color = Experiment, group = Collar)) 
gg1 <- gg + geom_point(data = y, size = 1)
gg2 <- gg1 + geom_line(data = y, size = 0.5) + scale_color_brewer(palette = "Set1")
#+ scale_color_gradientn(colors = primary.colors(15, steps = 3, no.white = TRUE))
gg3 <- gg2 + facet_wrap(~ Plot) 
#scale_color_manual(values = c("darkolivegreen3", "coral3"))  #plot separately based on Label
#+ geom_text(data = y, mapping = aes(x = Timestamp, y = Flux, label = Collar)) 

