# The purpose of this script is to prepare the raw data for modeling, includuing
# feature development and transformations.


# SETUP -------------------------------------------------------------------

library(tidyverse)
library(lubridate)
library(chron)
library(here)
library(arrow)


# LOAD RAW DATA -----------------------------------------------------------

# Specify schema
raw_schema <- cols(
  "Address" = col_character(),
  "Type" = col_factor(ordered = FALSE),
  "Datetime" = col_character(),
  "Latitude" = col_number(),
  "Longitude" = col_number(),
  "Report Location" = col_skip(),
  "Incident Number" = col_character()
)

# Read from disk
df_fire_raw <- read_csv(
  file = here("data", "raw", "data_seattle_fire_911.csv"),
  col_types = raw_schema
)


# BASIC CLEANING ----------------------------------------------------------

# Initialize prepared data
df_fire <- df_fire_raw

# Select and rename columns
df_fire <- df_fire %>%
  rename_with(str_to_lower) %>%
  select(
    id = `incident number`,
    type,
    address,
    datetime,
    latitude,
    longitude
  )

# Parse datetime string
df_fire <- df_fire %>%
  mutate(
    datetime = mdy_hms(datetime),
    date = as_date(datetime)
  )

# Arrange by datetime
df_fire <- df_fire %>%
  arrange(datetime)

# Remove last date (i.e. likely incomplete data)
df_fire <- df_fire %>%
  filter(date != max(date))

# DEFINE INCIDENT-LEVEL FEATURES --------------------------------------------

# Create time-based features
df_fire <- df_fire %>%
  mutate(
    hour = hour(datetime)
  )


# AGGREGATE DAILY VOLUMES  --------------------------------------------------

# Total daily call volumes)
df_fire_agg_total <- df_fire %>%
  count(date, name = "volume_total")

# Aggregate temporal features by hour of each day, then pivot
df_fire_agg_hour <- df_fire %>%
  mutate(
    hour = str_pad(hour, width = 2, side = "left", pad = "0")
  ) %>%
  count(date, hour, name = "volume_hour") %>%
  arrange(hour) %>%
  pivot_wider(
    names_from = hour,
    names_prefix = "volume_hour_",
    values_from = volume_hour,
    values_fill = list(volume_hour = 0)
  )


# MERGE COMPLETE SERIES ---------------------------------------------------

# Validate complete time series (i.e. no missing dates)
df_fire_agg <- 
  df_fire_agg_total %>%
  complete(date = full_seq(date, period = 1), fill = list(volume_total = 0)) 

# Join time-based aggregated features
df_fire_agg <- df_fire_agg %>%
  left_join(df_fire_agg_hour, by = "date")


# DEFINE DATE-BASED FEATURES ----------------------------------------------

# Add descriptive features for each date
df_fire_agg <- df_fire_agg %>%
  mutate(
    year = year(date),
    month = month(date),
    day_month = day(date),
    day_week = wday(date),
    is_weekend = is.weekend(date),
    is_holiday = is.holiday(date)
  )


# WRITE TO DISK -----------------------------------------------------------

write_parquet(df_fire_agg, here("data", "processed", "df_fire_agg.parquet"))
