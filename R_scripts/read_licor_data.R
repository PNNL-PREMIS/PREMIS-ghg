
#----- Function to parse a file and return data frame -----
read_licor_data <- function(filename) {
  
  file <- readLines(filename)  # Read in file
  nobs <- length(file[grepl("^Obs#:", file)])
  cat("Reading...", filename, " lines =", length(file), "observations =", nobs, "\n")
  
  record_sep <- grep(pattern = "^$", file)
  
  find_parse <- function(tabletext, lbl) {
    line <- tail(grep(lbl, tabletext), n = 1)
    if(length(line)) gsub(lbl, "", tabletext[line]) else ""
  }
  label <- file[grepl("^Label:", file)]  # Pull out variables
  flux <- file[grepl("^Lin_Flux:", file)]
  r2 <- file[grepl("^Lin_R2:", file)]
  date <- file[which(grepl("^Type", file)) + 1]
  comments <- file[grepl("^Comments:", file)]
  port <- file[grepl("^Port#:", file)]  # may or may not be present
  
  results <- tibble(table = seq_along(record_sep),
                    Timestamp = as_datetime(NA),
                    Label = NA_character_,
                    Port = NA_integer_,
                    Flux = NA_character_,
                    R2 = NA_character_,
                    T5 = NA_character_,
                    Tcham = NA_character_,
                    SMoist = NA_character_,
                    Comments = NA_character_)
  
  previous_table_end <- 0
  for (i in seq_along(record_sep)) {
    tabletext <- file[(previous_table_end + 1):record_sep[i]]
    #cat(i, length(tabletext), " ")
    #browser()
    # Find the table start and stop
    table_start <- tail(grep("^Type\t", tabletext), n = 1)
    table_stop <- tail(grep("^CrvFitStatus:\t", tabletext), n = 1)
    if(length(table_stop) == 0) {
      message("Skipping table", i, previous_table_end + 1:record_sep[i])
      next()
    }
    # Find names, discarding any trailing 'Annotation' column
    col_names <- strsplit(file[table_start], "\t", fixed = TRUE)[[1]]
    col_names <- col_names[!grepl("Annotation", col_names)]
    #cat("\tReading table at", table_start, ":", tablestops[i], "...\n")
    tabletext[(table_start+1):(table_stop-1)] %>% 
      paste(collapse = "\n") %>% 
      readr::read_tsv(col_names = col_names) ->
      df
    
    index <- which(df$Type == 1)
    results$Timestamp[i] <- mean(df$Date)
    results$Label[i] <- find_parse(tabletext, "^Label:\t")
    results$Port[i] <- find_parse(tabletext, "^Port#:\t")
    results$Flux[i] <- find_parse(tabletext, "^Exp_Flux:\t")
    results$R2[i] <- find_parse(tabletext, "^Exp_R2:\t")
    results$T5[i] <- mean(df$V4[index])
    results$Tcham[i] <- mean(df$Tcham[index])
    results$SMoist[i] <- mean(df$V3[index])
    results$Comments[i] <- find_parse(tabletext, "^Comments:\t")
    previous_table_end <- record_sep[i]
  }

  results %>% 
    mutate(Port = as.integer(Port),
           Flux = as.numeric(Flux),
           R2 = as.numeric(R2),
           T5 = as.numeric(T5),
           Tcham = as.numeric(Tcham),
           SMoist = as.numeric(SMoist))
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
