# Read a test file - parse it for "Label" and "Lin_Flux" lines 
# Stephanie Pennington | March 2018

library(tidyr)
library(lubridate)
library(dplyr)
library(readr)

#----- Function to parse a file and return data frame -----
read_LTlicor_data <- function(filename) {
  file <- readLines(filename)  # Read in file
  cat("Reading...", filename, " lines =", length(file), "\n")
  
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  nobs <- length(file[grepl("^Obs#:", file)])
  date <- file[which(grepl("^Type", file)) + 1]
  port <- file[grepl("^Port#:", file)]
  
  # Find beginning and end indices of raw data for each measurment
  tablestarts <- grep("^Type", file)
  tablestops <- grep("^CrvFitStatus:", file)
  
  # Average values and place in matrix to be added to final df
  tcham <- matrix()
  t5 <- matrix()
  smoist <- matrix()
  for (i in seq_along(tablestarts)) {
    df <- readr::read_tsv(filename, skip = tablestarts[i], n_max = tablestops[i] - tablestarts[i] - 1,
                          col_names = c("Type", "Etime", "Date", "Tcham", "Pressure", "H2O", "CO2", 
                                        "Cdry", "Tbench", "V1", "V2", "V3",
                                        "V4", "LATITUDE", "LONGITUDE", "STATUS", "SPEED", "COURSE", 
                                        "RH", "Tboard", "Vin", "CO2ABS", "H2OABS", "Hour", "DOY",
                                        "RAWCO2", "RAWCO2REF", "RAWH2O", "RAWH2OREF"),
                                        col_types = "ddTdddddddddddddddddddddddddd")
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
  sPort <- separate(data.frame(port), port, into = c("name", "port"), sep = "\\t")
  
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
         Port = as.numeric(sPort$port),
         T5 = as.numeric(t5),
         Tcham = as.numeric(tcham),
         SMoisture = as.numeric(smoist))
}

read_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  bind_rows(list)
}

rawDat <- read_dir("../licor_data/longterm_dat/")
save(LT_licorDat, file = "../outputs/LT_licordat.rda")
write_csv(LT_licorDat, "../outputs/LT_licor_data.csv")

ggplot(data = LT_test, aes(x = Timestamp, y = Flux, group = Port, color = Port)) + 
  geom_line() +scale_colour_gradientn(colours = rainbow(9)) + 
  ggtitle("Long Term Chamber Measurements") #+
  geom_text_repel()
cat("All done.\n")