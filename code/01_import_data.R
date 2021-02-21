# The purpose of this script is to import data from the Seattle Open Data Portal


# SETUP -------------------------------------------------------------------

library(tidyverse)
library(here)
library(httr)

# IMPORT DATA -------------------------------------------------------------

# Define target URL
url = "https://data.seattle.gov/api/views/kzjm-xkqj/rows.csv?accessType=DOWNLOAD"

# Download CSV file
GET(
  url = url, 
  write_disk(here("data", "raw", "data_seattle_fire_911.csv"), overwrite=TRUE)
)

