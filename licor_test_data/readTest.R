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
  
  slabel <- separate(data.frame(label), label,into = c("name", "label"), sep = "\\t")  # Separate into data frame
  sflux <- separate(data.frame(flux), flux, into = c("name", "flux"), sep = "\\t")
  sr2 <- separate(data.frame(r2), r2, into = c("name", "r2"), sep = "\\t")
  sdate <- separate(data.frame(date), date, into = c("type", "etime", "date", "time"), 
                     sep = "[:space:]" , extra = "drop") 
  
  tstamp <- ymd_hms((paste(sdate$date, sdate$time)))  # Parse into "POSIXct/POSIXt" - formatted timestamp
  
  ## NOTE: Create warning for length mismatch, decide what to do if true
  #if (nrow(slabel) != nrow(flux)) {
  #warning("Row lengths do not match")
  #}
  
  test <<- data.frame(Label = slabel$label,
                     Timestamp = tstamp,
                     Flux = as.numeric(sflux$flux),
                     R2 = as.numeric(sr2$r2))
  
  return(test)
}

read_licor_data("Test51117.81x")
read_licor_data("SampleMultiplex.81x")
read_licor_data("SR_burn_28_july-201720910.81x")



# Label will hold collar #
# We will join (merge) this with 