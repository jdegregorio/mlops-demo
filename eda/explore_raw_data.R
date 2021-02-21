# The purpose of this script is to explore and profile the raw data source


# SETUP -------------------------------------------------------------------

library(tidyverse)
library(lubridate)
library(here)
library(summarytools)
library(kableExtra)


# LOAD DATA ---------------------------------------------------------------

# Load data
df_fire <- read_csv(here("data", "raw", "data_seattle_fire_911.csv"))

# Adjust types
df_fire <- df_fire %>% mutate(Datetime = mdy_hms(Datetime))


# CREATE DATA PREVIEW -----------------------------------------------------

df_fire %>%
  sample_n(100) %>%
  kbl() %>%
  kable_styling() %>%
  save_kable(here("eda", "raw_data_sample.html"))

# SUMMARIZE THE DATA ------------------------------------------------------

# Run dataframe summary
st_dfsum <- dfSummary(df_fire)

# Save report
print(
  st_dfsum, 
  file = here("eda", "raw_data_summary.html"),
  report.title = "Raw Data Summary"
)

# Detailed frequency table for "TYPE" column
st_freq <- df_fire %>%
  mutate(Type = as_factor(Type)) %>%
  pull(Type) %>%
  freq(order = "freq")

# Save report
st_freq %>%
  kbl() %>%
  kable_styling() %>%
  save_kable(here("eda", "raw_data_freq_type.html"))


# EXPLORE TEMPORAL ELEMENTS OF DATA ---------------------------------------

# Visualize all call volumes over time (by month)
df_fire %>%
  mutate(date = floor_date(as_date(Datetime), unit = "month")) %>%
  filter(date < floor_date(Sys.Date(), unit = "month")) %>%
  count(date) %>%
  ggplot(aes(x = date, y = n)) +
  geom_line(alpha = 0.8, color = "dodgerblue3") +
  theme_light() +
  labs(
    title = "Call Volume over Time",
    x = "Date",
    y = "Monthly Call Volume"
  ) +
  ggsave(
    here("eda", "plot_monthly_volume.jpg"),
    height = 4, width = 12, dpi = 1000
  )


# Visualize seasonal call volume
df_fire %>%
  mutate(
    date = as_date(Datetime),
    month = month(date, label = TRUE, abbr = TRUE),
    year = year(date)
  ) %>%
  filter(date < floor_date(Sys.Date(), unit = "year")) %>%
  count(month, year) %>%
  ggplot(aes(x = month, y = n, color = year, group = year)) +
  geom_line(alpha = 0.8) +
  theme_light() +
  labs(
    title = "Call Volume Seasonality",
    x = "Month",
    y = "Call Volume",
    color = "Year"
  ) +
  ggsave(
    here("eda", "plot_seasonal.jpg"),
    height = 4, width = 12, dpi = 1000
  )


# Visualize day of week trends
df_fire %>%
  mutate(
    date = as_date(Datetime),
    weekday = wday(date, label = TRUE, abbr = TRUE)
  ) %>%
  count(weekday) %>%
  ggplot(aes(x = weekday, y = n)) +
  geom_col(alpha = 0.6, fill = "dodgerblue3", color = "grey50") +
  theme_light() +
  labs(
    title = "Day of Week Trend",
    x = "Weekday",
    y = "# of Calls"
  ) +
  ggsave(
    here("eda", "plot_weekday_trend.jpg"),
    height = 4, width = 12, dpi = 1000
  )
