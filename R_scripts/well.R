# Created 10/2019 to fix timestamp issue on data downloaded 8/28/2019 and 9/13/2019
# Stephanie Pennington

library(readr)
library(tidyr)
library(dplyr)
library(lubridate)

# Read in last known data with correct timestamp
read_csv("../well_data/HSLE_20180716-20190624.csv", skip = 1) %>% 
  mutate(Timestamp = mdy_hms(`Date Time, GMT-04:00`, tz = "America/New_York")) %>% 
  rename(Low_Range = `Low Range, ??S/cm (LGR S/N: 20370966_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate, SEN S/N: 20370966)`,
         High_Range = `High Range, ??S/cm (LGR S/N: 20370966_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate, SEN S/N: 20370966)`,
         Temp_degF = `Temp, ??F (LGR S/N: 20370966_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate_duplicate, SEN S/N: 20370966)`) %>% 
  select(Timestamp, Low_Range, High_Range, Temp_degF) -> hsle_full

# Read in wonky data
hsle_20190913 <- read_csv("../well_data/HSLE_20190913.csv", skip = 1)
hsle_20190828 <- read_csv("../well_data/HSLE_20190828.csv", skip = 1)

# Create time sequence starting at the end of the correct time series
time_seq1 <- tibble(Timestamp = seq(mdy_hms("06/24/19 10:53:57 AM", tz = "America/New_York"), 
                                   by = "30 min", length.out = nrow(hsle_20190828)))

time_seq2 <- tibble(Timestamp = seq(mdy_hms("08/28/19 12:23:57", tz = "America/New_York"), 
                                    by = "30 min", length.out = nrow(hsle_20190913)))

# Bind sequence with wonky dataset and replace bad time sequence
hsle_20190828 %>%
  cbind(time_seq1) %>% 
  rename(Low_Range = `Low Range, ??S/cm (LGR S/N: 20370966, SEN S/N: 20370966)`,
         High_Range = `High Range, ??S/cm (LGR S/N: 20370966, SEN S/N: 20370966)`,
         Temp_degF = `Temp, ??F (LGR S/N: 20370966, SEN S/N: 20370966)`) %>% 
  select(Timestamp, Low_Range, High_Range, Temp_degF) %>% 
  head(-2) -> hsle_1

hsle_20190913 %>% 
  cbind(time_seq2) %>% 
  rename(Low_Range = `Low Range, ??S/cm (LGR S/N: 20370966, SEN S/N: 20370966)`,
         High_Range = `High Range, ??S/cm (LGR S/N: 20370966, SEN S/N: 20370966)`,
         Temp_degF = `Temp, ??F (LGR S/N: 20370966, SEN S/N: 20370966)`) %>% 
  select(Timestamp, Low_Range, High_Range, Temp_degF) %>% 
  head(-2) -> hsle_2

# Form one dataset
bind_rows(hsle_full, hsle_1, hsle_2) -> HSLE_20180716_20190913

write.csv(HSLE_20180716_20190913, "../well_data/HSLE_20180716-20190913.csv")


