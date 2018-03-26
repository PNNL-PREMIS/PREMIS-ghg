# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington March 2018

# Parse a file and return data frame

setwd("/Users/penn529/Desktop/PREMIS/licor_test_data/")
library(tidyr)
library(lubridate)

read_licor_data <- function(filename) {
  file <- readLines(filename)  # Read in file
  
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  nobs <- length(file[grepl("^Obs#:", file)])
  date <- file[which(grepl("^Type", file)) + 1]
  
  sLabel <- separate(data.frame(label), label,into = c("name", "label"), sep = "\\t")  # Separate into data frame
  sFlux <- separate(data.frame(flux), flux, into = c("name", "flux"), sep = "\\t")
  sR2 <- separate(data.frame(r2), r2, into = c("name", "r2"), sep = "\\t")
  sDate <- separate(data.frame(date), date, into = c("type", "etime", "date", "time"), 
                     sep = "[:space:]" , extra = "drop") 
  
  tstamp <- ymd_hms((paste(sDate$date, sDate$time)))  # Parse into "POSIXct/POSIXt" - formatted timestamp

  lengths <- c(nrow(sLabel),nrow(sFlux), nrow(sR2), nrow(sDate))
  
  # Warning if missing a variable 
  if (!all(nrow(sLabel) == lengths)) {
  
    stop(sprintf("Variable lengths do not match \n nLabel:%s \n nFlux:%s \n nR2:%s \n nDate:%s \n", 
                 nrow(sLabel), nrow(sFlux), nrow(sR2), nrow(sDate)))
  }
  
  test <- data.frame(Label = sLabel$label,
                     Timestamp = tstamp,
                     Flux = as.numeric(sFlux$flux),
                     R2 = as.numeric(sR2$r2))
  
  return(test)
}

read_licor_data("Test51117.81x")
read_licor_data("SampleMultiplex.81x")
read_licor_data("SR_burn_28_july-201720910.81x")



# Label will hold collar #
# We will join (merge) this with 