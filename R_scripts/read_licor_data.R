
#----- Function to parse a file and return data frame -----
read_licor_data <- function(filename) {
  
  file <- readLines(filename)  # Read in file
  nobs <- length(file[grepl("^Obs#:", file)])
  cat("Reading...", filename, " lines =", length(file), "observations =", nobs, "\n")
  
  record_starts <- grep(pattern = "^LI-8100", file)
  
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
                    T5 = NA_character_,
                    Tcham = NA_character_,
                    SMoisture = NA_character_,
                    Comments = NA_character_)
  
  for (i in seq_along(record_starts)) {
    if(i < length(record_starts)) {
      record_end <- record_starts[i+1]-1 
    } else {
      record_end <- length(file)
    }
    record <- file[record_starts[i]:record_end]
    # Get rid of blank lines because that can screw up paste(collapse()) below
    record <- record[grep("^$", record, invert = TRUE)]
    cat(i, record_starts[i], ":", record_end, length(record), "\n")
    
    # Find the table start and stop
    table_start <- tail(grep("^Type\t", record), n = 1)
    table_stop <- tail(grep("^CrvFitStatus:\t", record), n = 1)
    if(length(table_stop) == 0) {
      message("Skipping table ", i, " ", record_starts[i], ":", record_end)
      next()
    }
    # Find names, discarding any trailing 'Annotation' column
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
    results$T5[i] <- mean(df$V4[index])
    results$Tcham[i] <- mean(df$Tcham[index])
    results$SMoisture[i] <- mean(df$V3[index])
    results$Comments[i] <- find_parse(record, "^Comments:\t")
  }
  
  results %>% 
    mutate(Port = as.integer(Port),
           Flux = as.numeric(Flux),
           R2 = as.numeric(R2),
           T5 = as.numeric(T5),
           Tcham = as.numeric(Tcham),
           SMoisture = as.numeric(SMoisture))
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
