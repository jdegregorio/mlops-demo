# The purpose of this script is to create a baseline "dummy" model as a
# benchmark.


# SETUP -------------------------------------------------------------------

# Import packages
library(tidyverse)
library(here)
library(arrow)
library(rsample)

# Source dummy model functions
source(here("code", "funs_eval.R"))

# LOAD DATA ---------------------------------------------------------------

df_fire_agg <- read_parquet(here("data", "processed", "df_fire_agg.parquet"))


# CREATE DUMMY MODEL FEATURE SET ------------------------------------------

# Define simple feature set for dummy model - no features needed
df_all <- df_fire_agg %>% 
  select(date, volume_total_actual = volume_total)


# SPLIT DATA --------------------------------------------------------------

splits_rolling <- rolling_origin(
  df_all, 
  initial = 365*3, 
  assess = 7, 
  skip = 25,
  lag = 0,
  cumulative = TRUE
)

grid_samples <- splits_rolling %>%
  mutate(
    data_train = map(splits, training),
    data_test = map(splits, testing)
  )


# TRAIN MODEL -------------------------------------------------------------

# NO TRAINING REQUIRED - see dummy model functions

# Gets the last day in the training data for use for prediction (i.e. random walk)
train_dummy <- function(df_train) {
  
  df_train %>%
    arrange(date) %>%
    mutate(volume_total_pred = lag(volume_total_actual, 2)) %>%
    filter(date == max(date)) %>%
    pull(volume_total_pred)
  
}

# Repeat the last available training observation to predict over window
predict_dummy <- function(model_dummy, new_data) {
  
  tibble(volume_total_pred = rep(model_dummy, nrow(new_data)))
  
}


# EVALUATE MODEL ----------------------------------------------------------

# Make predictions for each sample, then evaluate
grid_samples <- grid_samples %>%
  mutate(
    fit= map(data_train, train_dummy),
    data_pred = map2(fit, data_test, predict_dummy),
    data_eval = map2(data_test, data_pred, evaluate_samples)
  )

# Unnest grid
df_eval <- grid_samples %>%
  select(id, data_eval) %>%
  unnest(data_eval)

# Summarize metrics
df_eval_sum <- df_eval %>%
  group_by(pred_lead) %>%
  summarize(
    mape_raw = mean(abs(error_pct)),
    rmse_raw = sqrt(sum(error_raw^2) / n()),
    rmse_weighted = sqrt(sum(error_weighted^2) / n())
  ) %>%
  ungroup()
  
# Plot MAPE
p_mape <- 
  df_eval %>%
  ggplot(aes(y = fct_rev(as_factor(pred_lead)), x = error_pct)) +
  ggridges::geom_density_ridges(alpha = 0.25, fill = "black") +
  scale_x_continuous(labels = scales::percent) +
  theme_light() +
  labs(
    title = "Percent Error Distribution by Forecast Lead",
    x = "Error Percentage",
    y = "Prediction Lead (Days)"
  )

# Save metrics
ggsave(here("data", "metrics", "plot_mape.jpg"), plot = p_mape, height = 4, width = 6, dpi = 1000)
write_parquet(df_eval, here("data", "metrics", "df_eval.parquet"))
write_parquet(df_eval_sum, here("data", "metrics", "df_eval_sum.parquet"))
