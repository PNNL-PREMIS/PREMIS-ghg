# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

#----- Function to parse a file and return data frame -----
packages <- c("tidyr", "lubridate", "dplyr")
lapply(packages, library, character.only = TRUE)

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
    df <- read.table(filename, skip = tablestarts[i] - 1, header = TRUE, 
               nrows = tablestops[i] - tablestarts[i] - 1, sep = "\t", fill = TRUE)
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

# Test function with sample data
#read_licor_data("Test51117.81x")
#read_licor_data("SampleMultiplex.81x")
#read_licor_data("SR_burn_28_july-201720910.81x")

#----- Function to loop through directory and call function to read licor data -----
read_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  bind_rows(list)
}

