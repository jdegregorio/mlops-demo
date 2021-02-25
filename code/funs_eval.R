evaluate_samples <- function(data_pred, data_test) {
  
  df_eval <-
    bind_cols(data_test, data_pred) %>%
    arrange(date) %>%
    mutate(
      pred_lead = 1:n(),
      error_weight = 1 - ((pred_lead - 1) / max(pred_lead)),
      error_raw = volume_total_actual - volume_total_pred,
      error_pct = error_raw / volume_total_actual,
      error_weighted = error_raw * error_weight
    )
  
  
  return(df_eval)
}
