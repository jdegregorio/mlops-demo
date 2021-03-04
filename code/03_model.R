# The purpose of this script is to create a baseline "dummy" model as a
# benchmark.


# SETUP -------------------------------------------------------------------

# Import packages
library(tidyverse)
library(lubridate)
library(here)
library(rsample)
library(yaml)
library(kableExtra)

# Source dummy model functions
source(here("code", "funs_eval.R"))


# LOAD DATA ---------------------------------------------------------------

df_fire_agg <- read_rds(here("data", "processed", "df_fire_agg.rds"))


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

# Gets the last day in the training data for use for prediction (i.e. naive)
train_dummy <- function(df_train) {

  df_train %>%
    arrange(date) %>%
    mutate(volume_total_pred = lag(volume_total_actual, 2)) %>%
    filter(date == max(date)) %>%
    pull(volume_total_pred)

}

# Repeat the last available training observation to predict over window
predict_dummy <- function(model_dummy, new_data) {

  tibble::tibble(volume_total_pred = rep(model_dummy, nrow(new_data)))

}


# EVALUATE MODEL ----------------------------------------------------------

# Make predictions for each sample, then evaluate
grid_samples <- grid_samples %>%
  mutate(
    fit = map(data_train, train_dummy),
    data_pred = map2(fit, data_test, predict_dummy),
    data_eval = map2(data_test, data_pred, evaluate_samples)
  )

# Unnest grid
df_eval <- grid_samples %>%
  select(id, data_eval) %>%
  unnest(data_eval)

# Summarize metrics by forecast lead across samples
df_eval_sum <- df_eval %>%
  group_by(pred_lead) %>%
  summarize(
    mape_raw = mean(abs(error_pct)),
    rmse_raw = sqrt(sum(error_raw^2) / n()),
    rmse_wei = sqrt(sum(error_wei^2) / n())
  ) %>%
  ungroup()

# Compute overall metrics
mape_raw <- df_eval_sum %>% pull(mape_raw) %>% mean()
rmse_raw <- df_eval_sum %>% pull(rmse_raw) %>% mean()
rmse_wei <- df_eval_sum %>% pull(rmse_wei) %>% mean()

# Summarize metrics in lists for tracking
ls_mape_raw <- as.list(df_eval_sum$mape_raw)
ls_rmse_raw <- as.list(df_eval_sum$rmse_raw)
ls_rmse_wei <- as.list(df_eval_sum$rmse_wei)

names(ls_mape_raw) <- df_eval_sum$pred_lead
names(ls_rmse_raw) <- df_eval_sum$pred_lead
names(ls_rmse_wei) <- df_eval_sum$pred_lead

ls_pred_lead <- list(
  mape_raw = ls_mape_raw,
  rmse_raw = ls_rmse_raw,
  rmse_wei = ls_rmse_wei
)

ls_metrics <- list(
  pred_lead = ls_pred_lead,
  overall = list(mape_raw = mape_raw, rmse_raw = rmse_raw, rmse_wei = rmse_wei)
)
  
# Plot MAPE by forecast lead
p_mape_lead <-
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

# Plot MAPE by forecast year
p_mape_year <- df_eval %>%
  mutate(year = year(date)) %>%
  ggplot(aes(y = fct_rev(as_factor(year)), x = error_pct)) +
  ggridges::geom_density_ridges(alpha = 0.25, fill = "black") +
  scale_x_continuous(labels = scales::percent, limits = c(-0.75, 0.75)) +
  theme_light() +
  labs(
    title = "Percent Error Distribution by Over Time",
    x = "Error Percentage",
    y = "Prediction Year"
  )

# Save metrics
write_yaml(ls_metrics, here("data", "metrics", "metrics.yaml"))
write_rds(df_eval, here("data", "metrics", "df_eval.rds"))
write_rds(df_eval_sum, here("data", "metrics", "df_eval_sum.rds"))
ggsave(
  here("data", "metrics", "plot_mape_lead.jpg"),
  plot = p_mape_lead, height = 4, width = 6, dpi = 1000
)
ggsave(
  here("data", "metrics", "plot_mape_year.jpg"),
  plot = p_mape_year, height = 4, width = 6, dpi = 1000
)


# FIT MODEL (ALL DATA) ----------------------------------------------------

# Train model
model_fit <- train_dummy(df_all)

# Save model
write_rds(model_fit, here("data", "model", "model.rds"))
