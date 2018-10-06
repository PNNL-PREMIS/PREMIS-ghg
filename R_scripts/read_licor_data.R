
#----- Function to parse a file and return data frame -----
read_licor_data <- function(filename) {
  
  filedata <- readLines(filename)  # Read in file
  record_starts <- grep(pattern = "^LI-8100", filedata)
  cat("Reading...", filename, " lines =", length(filedata), "observations =", length(record_starts), "\n")
  
  # Helper function to pull out data from line w/ specific label prefix
  find_parse <- function(tabletext, lbl) {
    line <- tail(grep(lbl, tabletext), n = 1)
    if(length(line)) gsub(lbl, "", tabletext[line]) else ""
  }
  
  results <- tibble(table = seq_along(record_starts),
                    Timestamp = as_datetime(NA),
                    Label = NA_character_,
                    Port = NA_integer_,
                    Flux = NA_character_,
                    R2 = NA_character_,
                    Tcham = NA_real_,
                    V1 = NA_real_,
                    V2 = NA_real_,
                    V3 = NA_real_,
                    V4 = NA_real_,
                    RH = NA_real_,
                    Cdry = NA_real_,
                    Comments = NA_character_)
  
  for (i in seq_along(record_starts)) {
    if(i < length(record_starts)) {
      record_end <- record_starts[i+1]-1 
    } else {
      record_end <- length(filedata)
    }
    record <- filedata[record_starts[i]:record_end]
    # Get rid of blank lines because that can screw up paste(collapse()) below
    record <- record[grep("^$", record, invert = TRUE)]
    #cat(i, record_starts[i], ":", record_end, length(record), "\n")
    
    # Find the data table start
    table_start <- tail(grep("^Type\t", record), n = 1)
    # Look for the next non-numeric line; this marks the end
    table_stop <-  head(grep("^[A-Z]", record[-(1:table_start)]), n = 1) + table_start

    if(length(table_stop) == 0) {
      message("Skipping table ", i, " ", record_starts[i], ":", record_end)
      next()
    }
    # Find names, discarding any trailing 'Annotation' column, and read
    col_names <- strsplit(record[table_start], "\t", fixed = TRUE)[[1]]
    col_names <- col_names[!grepl("Annotation", col_names)]
    #cat("\tReading table at", table_start, ":", tablestops[i], "...\n")
    record[(table_start+1):(table_stop-1)] %>% 
      paste(collapse = "\n") %>% 
      readr::read_tsv(col_names = col_names) ->
      df
    
    index <- which(df$Type == 1)
    results$Timestamp[i] <- mean(df$Date)
    results$Label[i] <- find_parse(record, "^Label:\t")
    results$Port[i] <- find_parse(record, "^Port#:\t")
    results$Flux[i] <- find_parse(record, "^Exp_Flux:\t")
    results$R2[i] <- find_parse(record, "^Exp_R2:\t")
    results$Tcham[i] <- mean(df$Tcham[index])
    results$V1[i] <- mean(df$V1[index])
    results$V2[i] <- mean(df$V2[index])
    results$V3[i] <- mean(df$V3[index])
    results$V4[i] <- mean(df$V4[index])
    results$RH[i] <- mean(df$RH[index])
    results$Cdry[i] <- mean(df$Cdry[index])
    results$Comments[i] <- find_parse(record, "^Comments:\t")
  }
  
  results %>% 
    mutate(Port = as.integer(Port),
           Flux = as.numeric(Flux),
           R2 = as.numeric(R2))
}

#----- Function to loop through directory and call function to read licor data -----
read_licor_dir <- function(path) {
  files <<- list.files(path, pattern = ".81x", full.names = TRUE)
  list <- list()
  for (i in files) {
    list[[i]] <- read_licor_data(i)
  }
  bind_rows(list)
}
