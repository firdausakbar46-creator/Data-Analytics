# ============================================================
# LABORATORY QUALITY RISK DECISION SUPPORT MODEL
# ============================================================


required_packages <- c(
  "tidyverse",
  "readxl",
  "janitor",
  "lubridate",
  "tidymodels",
  "broom",
  "glmnet"
)

missing_packages <- required_packages[
  !required_packages %in% rownames(installed.packages())
]

if (length(missing_packages) > 0) {
  
  install.packages(
    missing_packages,
    dependencies = TRUE
  )
  
}

invisible(
  lapply(
    required_packages,
    library,
    character.only = TRUE
  )
)

set.seed(123)


# ============================================================
# 1. CONFIGURATION
# ============================================================

file <- "C:/Users/Asus/Downloads/data analytics project 1/data gacoan/supplier quality risk/bank_data_laboratory.xlsx"

raw_sheet <- "Raw Data"
master_sheet <- "Master_Standard"

output_dir <- file.path(
  dirname(file),
  "output_quality_risk"
)

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# Business Risk Threshold
RISK_LOW <- 0.30
RISK_HIGH <- 0.70

# Classification threshold
CLASS_THRESHOLD <- 0.50


# ============================================================
# 2. HELPER FUNCTIONS
# ============================================================


# ------------------------------------------------------------
# 2.1 Safe Numeric Conversion
# ------------------------------------------------------------

to_num <- function(x) {
  
  if (is.numeric(x)) {
    return(as.numeric(x))
  }
  
  x <- as.character(x)
  
  x <- str_squish(x)
  
  x[
    x %in% c(
      "",
      "NA",
      "N/A",
      "NULL",
      "-"
    )
  ] <- NA_character_
  
  # Remove comma thousands separator
  x <- str_replace_all(
    x,
    ",",
    ""
  )
  
  # Extract normal number or scientific notation
  extracted <- str_extract(
    x,
    "[-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?"
  )
  
  result <- suppressWarnings(
    as.numeric(extracted)
  )
  
  return(result)
}


# ------------------------------------------------------------
# 2.2 Safe Date Conversion
# ------------------------------------------------------------

to_date <- function(x) {
  
  if (inherits(x, "Date")) {
    return(x)
  }
  
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }
  
  if (is.numeric(x)) {
    
    return(
      as.Date(
        x,
        origin = "1899-12-30"
      )
    )
    
  }
  
  result <- suppressWarnings(
    parse_date_time(
      as.character(x),
      orders = c(
        "d/m/Y",
        "d-m-Y",
        "Y-m-d",
        "m/d/Y",
        "m-d-Y",
        "d.m.Y"
      )
    )
  )
  
  return(as.Date(result))
}


# ------------------------------------------------------------
# 2.3 Safe Division
# ------------------------------------------------------------

safe_divide <- function(a, b) {
  
  ifelse(
    b == 0,
    NA_real_,
    a / b
  )
  
}


# ============================================================
# 3. IMPORT DATA
# ============================================================

raw <- read_excel(
  file,
  sheet = raw_sheet
) %>%
  clean_names()

master <- read_excel(
  file,
  sheet = master_sheet
) %>%
  clean_names()


# ============================================================
# 4. REQUIRED COLUMN VALIDATION
# ============================================================

required_raw <- c(
  "testing_id",
  "data_type",
  "test_type",
  "date",
  "item",
  "factory",
  "before_after",
  "supplier",
  "sampel_type",
  "parameter",
  "score"
)

required_master <- c(
  "standard_id",
  "data_type",
  "item",
  "before_after",
  "parameter",
  "operator",
  "min",
  "max",
  "berlaku_mulai",
  "berlaku_sampai"
)


missing_raw <- setdiff(
  required_raw,
  names(raw)
)

missing_master <- setdiff(
  required_master,
  names(master)
)


if (length(missing_raw) > 0) {
  
  stop(
    paste(
      "Kolom Raw Data berikut tidak ditemukan:",
      paste(
        missing_raw,
        collapse = ", "
      )
    )
  )
  
}


if (length(missing_master) > 0) {
  
  stop(
    paste(
      "Kolom Master_Standard berikut tidak ditemukan:",
      paste(
        missing_master,
        collapse = ", "
      )
    )
  )
  
}


# ============================================================
# 5. CLEAN RAW DATA
# ============================================================

raw <- raw %>%
  
  mutate(
    
    raw_row_id = row_number(),
    
    across(
      where(is.character),
      ~ str_to_upper(
        str_squish(.x)
      )
    ),
    
    score_raw = as.character(score),
    
    score = to_num(score),
    
    date = to_date(date)
    
  )


# ============================================================
# 6. CLEAN MASTER STANDARD
# ============================================================

master <- master %>%
  
  mutate(
    
    master_row_id = row_number(),
    
    across(
      where(is.character),
      ~ str_to_upper(
        str_squish(.x)
      )
    ),
    
    operator = str_replace_all(
      operator,
      "≤",
      "<="
    ),
    
    operator = str_replace_all(
      operator,
      "≥",
      ">="
    ),
    
    min = to_num(min),
    
    max = to_num(max),
    
    berlaku_mulai = to_date(
      berlaku_mulai
    ),
    
    berlaku_sampai = to_date(
      berlaku_sampai
    )
    
  )


# ============================================================
# 7. BASIC DATA AUDIT
# ============================================================

cat("\n")
cat("====================================================\n")
cat("DATA AUDIT\n")
cat("====================================================\n")

cat(
  "Raw Data rows      :",
  nrow(raw),
  "\n"
)

cat(
  "Master Standard    :",
  nrow(master),
  "\n"
)

cat(
  "Raw missing date   :",
  sum(is.na(raw$date)),
  "\n"
)

cat(
  "Raw missing score  :",
  sum(is.na(raw$score)),
  "\n"
)

cat(
  "Master missing min :",
  sum(is.na(master$min)),
  "\n"
)

cat(
  "Master missing max :",
  sum(is.na(master$max)),
  "\n"
)


# ============================================================
# 8. MATCH RAW DATA TO MASTER STANDARD
# ============================================================

candidate_match <- raw %>%
  
  left_join(
    
    master,
    
    by = c(
      "data_type",
      "item",
      "before_after",
      "parameter"
    )
    
  ) %>%
  
  mutate(
    
    standard_valid =
      !is.na(date) &
      !is.na(berlaku_mulai) &
      date >= berlaku_mulai &
      (
        is.na(berlaku_sampai) |
          date <= berlaku_sampai
      )
    
  )


# ============================================================
# 9. AUDIT STANDARD OVERLAP
# ============================================================

overlap_audit <- candidate_match %>%
  
  filter(
    standard_valid
  ) %>%
  
  count(
    raw_row_id,
    name = "number_of_matching_standards"
  ) %>%
  
  filter(
    number_of_matching_standards > 1
  )


cat("\n")
cat("====================================================\n")
cat("STANDARD MATCHING AUDIT\n")
cat("====================================================\n")

cat(
  "Raw rows with >1 valid standard:",
  nrow(overlap_audit),
  "\n"
)


# ============================================================
# 10. SELECT BEST STANDARD
# ============================================================

matched_data <- candidate_match %>%
  
  filter(
    standard_valid
  ) %>%
  
  arrange(
    
    raw_row_id,
    
    desc(berlaku_mulai),
    
    desc(master_row_id)
    
  ) %>%
  
  group_by(
    raw_row_id
  ) %>%
  
  slice(
    1
  ) %>%
  
  ungroup()


# ============================================================
# 11. MATCHING SUMMARY
# ============================================================

matched_ids <- unique(
  matched_data$raw_row_id
)

unmatched_data <- raw %>%
  
  filter(
    !raw_row_id %in% matched_ids
  )


cat("\n")
cat("Matched rows       :",
    nrow(matched_data),
    "\n")

cat(
  "Unmatched rows     :",
  nrow(unmatched_data),
  "\n"
)


# ============================================================
# 12. CREATE PASS / FAILURE TARGET
# ============================================================

data <- matched_data %>%
  
  mutate(
    
    reported_operator =
      case_when(
        
        str_detect(
          score_raw,
          "^<"
        ) ~ "<",
        
        str_detect(
          score_raw,
          "^>"
        ) ~ ">",
        
        TRUE ~ ""
        
      ),
    
    result = case_when(
      
      # ------------------------------------------------------
      # Missing score
      # ------------------------------------------------------
      
      is.na(score) ~
        "MISSING_SCORE",
      
      
      # ------------------------------------------------------
      # Operator <
      # ------------------------------------------------------
      
      operator == "<" &
        reported_operator == "<" &
        !is.na(max) &
        score <= max ~
        
        "PASS",
      
      
      operator == "<" &
        reported_operator == "<" &
        !is.na(max) &
        score > max ~
        
        "UNDETERMINED",
      
      
      operator == "<" &
        reported_operator != "<" &
        !is.na(max) &
        score < max ~
        
        "PASS",
      
      
      operator == "<" &
        reported_operator != "<" &
        !is.na(max) &
        score >= max ~
        
        "FAILURE",
      
      
      # ------------------------------------------------------
      # Operator <=
      # ------------------------------------------------------
      
      operator == "<=" &
        !is.na(max) &
        score <= max ~
        
        "PASS",
      
      
      operator == "<=" &
        !is.na(max) &
        score > max ~
        
        "FAILURE",
      
      
      # ------------------------------------------------------
      # Operator =
      # Range Min - Max
      # ------------------------------------------------------
      
      operator == "=" &
        !is.na(min) &
        !is.na(max) &
        score >= min &
        score <= max ~
        
        "PASS",
      
      
      operator == "=" &
        !is.na(min) &
        !is.na(max) &
        (
          score < min |
            score > max
        ) ~
        
        "FAILURE",
      
      
      # ------------------------------------------------------
      # Operator >
      # ------------------------------------------------------
      
      operator == ">" &
        !is.na(min) &
        score > min ~
        
        "PASS",
      
      
      operator == ">" &
        !is.na(min) &
        score <= min ~
        
        "FAILURE",
      
      
      # ------------------------------------------------------
      # Operator >=
      # ------------------------------------------------------
      
      operator == ">=" &
        !is.na(min) &
        score >= min ~
        
        "PASS",
      
      
      operator == ">=" &
        !is.na(min) &
        score < min ~
        
        "FAILURE",
      
      
      # ------------------------------------------------------
      # Fallback
      # ------------------------------------------------------
      
      TRUE ~
        
        "UNDETERMINED"
      
    )
    
  )


# ============================================================
# 13. TARGET AUDIT
# ============================================================

target_audit <- data %>%
  
  count(
    result
  )


cat("\n")
cat("====================================================\n")
cat("TARGET AUDIT\n")
cat("====================================================\n")

print(
  target_audit
)


# ============================================================
# 14. MODELING DATA
# ============================================================

model_data <- data %>%
  
  filter(
    result %in% c(
      "PASS",
      "FAILURE"
    )
  ) %>%
  
  mutate(
    
    failure = factor(
      result,
      levels = c(
        "PASS",
        "FAILURE"
      )
    ),
    
    month = factor(
      month(date),
      levels = 1:12,
      labels = month.abb
    )
    
  ) %>%
  
  select(
    
    failure,
    
    date,
    
    supplier,
    
    item,
    
    factory,
    
    parameter,
    
    data_type,
    
    test_type,
    
    before_after,
    
    sampel_type,
    
    month
    
  )


# ============================================================
# 15. CHECK MODEL DATA
# ============================================================

cat("\n")
cat("====================================================\n")
cat("MODEL DATA\n")
cat("====================================================\n")

cat(
  "Observations:",
  nrow(model_data),
  "\n"
)

print(
  table(
    model_data$failure
  )
)


if (nrow(model_data) < 50) {
  
  warning(
    "Jumlah observasi < 50. Model mungkin tidak stabil."
  )
  
}


class_counts <- table(
  model_data$failure
)

if (length(class_counts) < 2) {
  
  stop(
    "Target hanya memiliki satu kelas."
  )
  
}

if (min(class_counts) < 5) {
  
  warning(
    "Jumlah FAILURE atau PASS sangat sedikit. Evaluasi model dapat tidak stabil."
  )
  
}


# ============================================================
# 16. HISTORICAL FAILURE RATE
# ============================================================

supplier_history <- model_data %>%
  
  group_by(
    supplier
  ) %>%
  
  summarise(
    
    total_test = n(),
    
    failure = sum(
      failure == "FAILURE"
    ),
    
    pass = sum(
      failure == "PASS"
    ),
    
    failure_rate =
      failure / total_test,
    
    .groups = "drop"
    
  ) %>%
  
  arrange(
    desc(failure_rate)
  )


cat("\n")
cat("====================================================\n")
cat("SUPPLIER HISTORICAL FAILURE RATE\n")
cat("====================================================\n")

print(
  supplier_history
)


# ============================================================
# 17. TIME-BASED TRAIN / TEST SPLIT
# ============================================================

model_data <- model_data %>%
  
  filter(
    !is.na(date)
  ) %>%
  
  arrange(
    date
  )


unique_dates <- sort(
  unique(
    model_data$date
  )
)


if (length(unique_dates) < 2) {
  
  stop(
    "Tidak cukup variasi tanggal untuk time-based train/test split."
  )
  
}


# Find candidate cutoff closest to 80%
candidate_indices <- 1:(length(unique_dates) - 1)

split_candidates <- map_dfr(
  
  candidate_indices,
  
  function(i) {
    
    cutoff_date <- unique_dates[i]
    
    train_tmp <- model_data %>%
      
      filter(
        date <= cutoff_date
      )
    
    test_tmp <- model_data %>%
      
      filter(
        date > cutoff_date
      )
    
    tibble(
      
      index = i,
      
      cutoff = cutoff_date,
      
      train_n = nrow(train_tmp),
      
      test_n = nrow(test_tmp),
      
      train_classes =
        n_distinct(train_tmp$failure),
      
      test_classes =
        n_distinct(test_tmp$failure)
      
    )
    
  }
  
)


valid_splits <- split_candidates %>%
  
  filter(
    
    train_classes >= 2,
    
    test_n > 0
    
  ) %>%
  
  mutate(
    
    distance_from_80 =
      abs(
        train_n /
          (train_n + test_n) -
          0.80
      )
    
  ) %>%
  
  arrange(
    distance_from_80
  )


if (nrow(valid_splits) == 0) {
  
  stop(
    "Tidak ditemukan cutoff tanggal yang memungkinkan TRAIN memiliki dua kelas."
  )
  
}


cutoff <- valid_splits$cutoff[1]


train <- model_data %>%
  
  filter(
    date <= cutoff
  )

test <- model_data %>%
  
  filter(
    date > cutoff
  )


cat("\n")
cat("====================================================\n")
cat("TIME-BASED SPLIT\n")
cat("====================================================\n")

cat(
  "Cutoff:",
  format(
    cutoff,
    "%d-%m-%Y"
  ),
  "\n"
)

cat(
  "Train:",
  nrow(train),
  "\n"
)

cat(
  "Test:",
  nrow(test),
  "\n"
)

cat("\nTRAIN:\n")

print(
  table(
    train$failure
  )
)

cat("\nTEST:\n")

print(
  table(
    test$failure
  )
)


# ============================================================
# 18. RECIPE
# ============================================================

recipe_model <- recipe(
  
  failure ~
    supplier +
    item +
    factory +
    parameter +
    data_type +
    test_type +
    before_after +
    sampel_type +
    month,
  
  data = train
  
) %>%
  
  # Missing categorical values
  step_unknown(
    all_nominal_predictors()
  ) %>%
  
  # Rare categories
  step_other(
    all_nominal_predictors(),
    threshold = 0.01
  ) %>%
  
  # New categories appearing in test/future data
  step_novel(
    all_nominal_predictors(),
    new_level = "NEW"
  ) %>%
  
  # Remove zero variance
  step_zv(
    all_predictors()
  ) %>%
  
  # Convert categorical variables to dummy variables
  step_dummy(
    all_nominal_predictors()
  ) %>%
  
  # Final zero variance check
  step_zv(
    all_predictors()
  )


# ============================================================
# 19. REGULARIZED LOGISTIC REGRESSION
# ============================================================

logistic_model <- logistic_reg(
  
  penalty = tune(),
  
  mixture = 0
  
) %>%
  
  set_engine(
    "glmnet"
  ) %>%
  
  set_mode(
    "classification"
  )

# ============================================================
# 20. WORKFLOW
# ============================================================

workflow_model <- workflow() %>%
  
  add_recipe(
    recipe_model
  ) %>%
  
  add_model(
    logistic_model
  )


# ============================================================
# 21. CROSS VALIDATION INSIDE TRAINING DATA
# ============================================================

train_class_counts <- table(
  train$failure
)

v_folds <- min(
  5,
  min(train_class_counts)
)

v_folds <- max(
  2,
  v_folds
)


set.seed(123)

cv_folds <- vfold_cv(
  
  train,
  
  v = v_folds,
  
  strata = failure
  
)


cat("\n")
cat("Cross-validation folds:",
    v_folds,
    "\n")


# ============================================================
# 22. PENALTY GRID
# ============================================================

penalty_grid <- grid_regular(
  
  penalty(
    range = c(
      -4,
      0
    )
  ),
  
  levels = 15
  
)


# ============================================================
# 23. MODEL TUNING
# ============================================================

cat("\n")
cat("====================================================\n")
cat("TUNING LOGISTIC REGRESSION\n")
cat("====================================================\n")


set.seed(123)

tuned_model <- tune_grid(
  
  workflow_model,
  
  resamples = cv_folds,
  
  grid = penalty_grid,
  
  metrics = metric_set(
    roc_auc,
    pr_auc
  ),
  
  control = control_grid(
    save_pred = TRUE,
    verbose = TRUE
  )
  
)


# ============================================================
# 24. BEST MODEL
# ============================================================

best_model <- select_best(
  
  tuned_model,
  
  metric = "roc_auc"
  
)


cat("\n")
cat("BEST MODEL:\n")

print(
  best_model
)


# ============================================================
# 25. FINALIZE MODEL
# ============================================================

final_workflow <- finalize_workflow(
  
  workflow_model,
  
  best_model
  
)


# ============================================================
# 26. FINAL TRAINING
# ============================================================

cat("\n")
cat("====================================================\n")
cat("FINAL MODEL TRAINING\n")
cat("====================================================\n")


set.seed(123)

fit_model <- fit(
  
  final_workflow,
  
  data = train
  
)


cat(
  "\nModel berhasil dibuat.\n"
)


# ============================================================
# 27. PREDICTION
# ============================================================

prediction <- test %>%
  
  bind_cols(
    
    predict(
      fit_model,
      test,
      type = "prob"
    )
    
  ) %>%
  
  mutate(
    
    failure_probability =
      .pred_FAILURE,
    
    predicted_class = factor(
      
      if_else(
        failure_probability >= CLASS_THRESHOLD,
        "FAILURE",
        "PASS"
      ),
      
      levels = c(
        "PASS",
        "FAILURE"
      )
      
    ),
    
    risk_level = case_when(
      
      failure_probability < RISK_LOW ~
        "LOW",
      
      failure_probability < RISK_HIGH ~
        "MEDIUM",
      
      TRUE ~
        "HIGH"
      
    )
    
  )


# ============================================================
# 28. CONFUSION MATRIX
# ============================================================

actual <- factor(
  
  prediction$failure,
  
  levels = c(
    "PASS",
    "FAILURE"
  )
  
)

predicted <- factor(
  
  prediction$predicted_class,
  
  levels = c(
    "PASS",
    "FAILURE"
  )
  
)


cm <- table(
  
  Actual = actual,
  
  Predicted = predicted
  
)


cat("\n")
cat("====================================================\n")
cat("CONFUSION MATRIX\n")
cat("====================================================\n")

print(
  cm
)


TN <- cm["PASS", "PASS"]

FP <- cm["PASS", "FAILURE"]

FN <- cm["FAILURE", "PASS"]

TP <- cm["FAILURE", "FAILURE"]


# ============================================================
# 29. MODEL METRICS
# ============================================================

accuracy_value <- safe_divide(
  TP + TN,
  TP + TN + FP + FN
)

precision_value <- safe_divide(
  TP,
  TP + FP
)

recall_value <- safe_divide(
  TP,
  TP + FN
)

specificity_value <- safe_divide(
  TN,
  TN + FP
)

f1_value <- safe_divide(
  2 * precision_value * recall_value,
  precision_value + recall_value
)

npv_value <- safe_divide(
  TN,
  TN + FN
)

brier_score <- mean(
  
  (
    if_else(
      prediction$failure == "FAILURE",
      1,
      0
    ) -
      prediction$failure_probability
  )^2,
  
  na.rm = TRUE
  
)


# ROC-AUC
roc_auc_value <- NA_real_

if (
  n_distinct(
    prediction$failure
  ) == 2
) {
  
  roc_auc_value <- roc_auc(
    
    prediction,
    
    truth = failure,
    
    .pred_FAILURE,
    
    event_level = "second"
    
  )$.estimate
  
}


metrics <- tibble(
  
  metric = c(
    
    "Accuracy",
    
    "Precision",
    
    "Recall",
    
    "Specificity",
    
    "F1",
    
    "NPV",
    
    "ROC-AUC",
    
    "Brier Score"
    
  ),
  
  value = c(
    
    accuracy_value,
    
    precision_value,
    
    recall_value,
    
    specificity_value,
    
    f1_value,
    
    npv_value,
    
    roc_auc_value,
    
    brier_score
    
  )
  
)


cat("\n")
cat("====================================================\n")
cat("MODEL PERFORMANCE\n")
cat("====================================================\n")

print(
  metrics
)


# ============================================================
# 30. TOP RISK PREDICTIONS
# ============================================================

decision <- prediction %>%
  
  select(
    
    date,
    
    supplier,
    
    item,
    
    factory,
    
    parameter,
    
    before_after,
    
    failure,
    
    predicted_class,
    
    failure_probability,
    
    risk_level
    
  ) %>%
  
  arrange(
    
    desc(
      failure_probability
    )
    
  )


cat("\n")
cat("====================================================\n")
cat("TOP 20 FAILURE RISK\n")
cat("====================================================\n")

print(
  head(
    decision,
    20
  )
)


# ============================================================
# 31. RISK DISTRIBUTION
# ============================================================

risk_summary <- prediction %>%
  
  count(
    risk_level
  ) %>%
  
  mutate(
    
    percentage =
      n / sum(n)
    
  )


cat("\n")
cat("====================================================\n")
cat("RISK DISTRIBUTION\n")
cat("====================================================\n")

print(
  risk_summary
)


# ============================================================
# 32. SUPPLIER RISK SUMMARY
# ============================================================

supplier_risk <- prediction %>%
  
  group_by(
    supplier
  ) %>%
  
  summarise(
    
    observations = n(),
    
    avg_failure_probability =
      mean(
        failure_probability,
        na.rm = TRUE
      ),
    
    high_risk_count =
      sum(
        risk_level == "HIGH"
      ),
    
    actual_failure_rate =
      mean(
        failure == "FAILURE"
      ),
    
    .groups = "drop"
    
  ) %>%
  
  arrange(
    
    desc(
      avg_failure_probability
    )
    
  )


# ============================================================
# 33. LOGISTIC REGRESSION COEFFICIENTS
# ============================================================

glmnet_fit <- extract_fit_parsnip(
  
  fit_model
  
)$fit


coefficient_matrix <- as.matrix(
  
  coef(
    glmnet_fit,
    s = best_model$penalty
  )
  
)


risk_factors <- tibble(
  
  term =
    rownames(
      coefficient_matrix
    ),
  
  estimate =
    as.numeric(
      coefficient_matrix[, 1]
    )
  
) %>%
  
  filter(
    
    term != "(Intercept)",
    
    estimate != 0
    
  ) %>%
  
  mutate(
    
    odds_ratio =
      exp(
        estimate
      ),
    
    absolute_effect =
      abs(
        estimate
      )
    
  ) %>%
  
  arrange(
    
    desc(
      absolute_effect
    )
    
  )


cat("\n")
cat("====================================================\n")
cat("RISK FACTORS\n")
cat("====================================================\n")

print(
  risk_factors
)


# ============================================================
# 34. ROC CURVE DATA
# ============================================================

roc_data <- NULL

if (
  n_distinct(
    prediction$failure
  ) == 2
) {
  
  roc_data <- roc_curve(
    
    prediction,
    
    truth = failure,
    
    .pred_FAILURE,
    
    event_level = "second"
    
  )
  
}


# ============================================================
# 35. CALIBRATION DATA
# ============================================================

calibration_data <- prediction %>%
  
  mutate(
    
    actual_failure =
      if_else(
        failure == "FAILURE",
        1,
        0
      ),
    
    probability_bin = cut(
      
      failure_probability,
      
      breaks = seq(
        0,
        1,
        by = 0.10
      ),
      
      include.lowest = TRUE
      
    )
    
  ) %>%
  
  group_by(
    probability_bin
  ) %>%
  
  summarise(
    
    mean_predicted =
      mean(
        failure_probability,
        na.rm = TRUE
      ),
    
    actual_failure_rate =
      mean(
        actual_failure,
        na.rm = TRUE
      ),
    
    n = n(),
    
    .groups = "drop"
    
  )


# ============================================================
# 36. VISUALIZATION 1
# TARGET DISTRIBUTION
# ============================================================

plot_target <- model_data %>%
  
  count(
    failure
  ) %>%
  
  ggplot(
    aes(
      x = failure,
      y = n
    )
  ) +
  
  geom_col() +
  
  labs(
    
    title =
      "Distribusi PASS vs FAILURE",
    
    x =
      "Result",
    
    y =
      "Jumlah Observasi"
    
  ) +
  
  theme_minimal()


ggsave(
  
  file.path(
    output_dir,
    "01_target_distribution.png"
  ),
  
  plot_target,
  
  width = 8,
  
  height = 5,
  
  dpi = 300
  
)


# ============================================================
# 37. VISUALIZATION 2
# SUPPLIER FAILURE RATE
# ============================================================

plot_supplier <- supplier_history %>%
  
  slice_max(
    
    order_by =
      failure_rate,
    
    n = 15
    
  ) %>%
  
  ggplot(
    
    aes(
      x = reorder(
        supplier,
        failure_rate
      ),
      
      y = failure_rate
    )
    
  ) +
  
  geom_col() +
  
  coord_flip() +
  
  scale_y_continuous(
    
    labels =
      scales::percent_format()
    
  ) +
  
  labs(
    
    title =
      "Top Supplier berdasarkan Historical Failure Rate",
    
    x =
      "Supplier",
    
    y =
      "Failure Rate"
    
  ) +
  
  theme_minimal()


ggsave(
  
  file.path(
    output_dir,
    "02_supplier_failure_rate.png"
  ),
  
  plot_supplier,
  
  width = 9,
  
  height = 7,
  
  dpi = 300
  
)


# ============================================================
# 38. VISUALIZATION 3
# RISK PROBABILITY DISTRIBUTION
# ============================================================

plot_probability <- prediction %>%
  
  ggplot(
    
    aes(
      x =
        failure_probability
    )
    
  ) +
  
  geom_histogram(
    
    bins = 20
    
  ) +
  
  geom_vline(
    
    xintercept =
      RISK_LOW,
    
    linetype = "dashed"
    
  ) +
  
  geom_vline(
    
    xintercept =
      RISK_HIGH,
    
    linetype = "dashed"
    
  ) +
  
  scale_x_continuous(
    
    labels =
      scales::percent_format()
    
  ) +
  
  labs(
    
    title =
      "Distribusi Failure Probability",
    
    x =
      "Predicted Failure Probability",
    
    y =
      "Jumlah Observasi"
    
  ) +
  
  theme_minimal()


ggsave(
  
  file.path(
    output_dir,
    "03_failure_probability_distribution.png"
  ),
  
  plot_probability,
  
  width = 9,
  
  height = 6,
  
  dpi = 300
  
)


# ============================================================
# 39. VISUALIZATION 4
# ROC CURVE
# ============================================================

if (!is.null(roc_data)) {
  
  plot_roc <- roc_data %>%
    
    ggplot(
      
      aes(
        x = 1 - specificity,
        y = sensitivity
      )
      
    ) +
    
    geom_line(
      
      linewidth = 1
      
    ) +
    
    geom_abline(
      
      linetype = "dashed"
      
    ) +
    
    labs(
      
      title =
        paste0(
          "ROC Curve — AUC = ",
          round(
            roc_auc_value,
            3
          )
        ),
      
      x =
        "1 - Specificity",
      
      y =
        "Sensitivity"
      
    ) +
    
    theme_minimal()
  
  
  ggsave(
    
    file.path(
      output_dir,
      "04_roc_curve.png"
    ),
    
    plot_roc,
    
    width = 8,
    
    height = 6,
    
    dpi = 300
    
  )
  
}


# ============================================================
# 40. VISUALIZATION 5
# CALIBRATION PLOT
# ============================================================

plot_calibration <- calibration_data %>%
  
  ggplot(
    
    aes(
      x = mean_predicted,
      y = actual_failure_rate
    )
    
  ) +
  
  geom_abline(
    
    linetype = "dashed"
    
  ) +
  
  geom_point(
    
    size = 3
    
  ) +
  
  geom_line() +
  
  scale_x_continuous(
    
    limits = c(
      0,
      1
    ),
    
    labels =
      scales::percent_format()
    
  ) +
  
  scale_y_continuous(
    
    limits = c(
      0,
      1
    ),
    
    labels =
      scales::percent_format()
    
  ) +
  
  labs(
    
    title =
      "Calibration Plot",
    
    x =
      "Predicted Failure Probability",
    
    y =
      "Actual Failure Rate"
    
  ) +
  
  theme_minimal()


ggsave(
  
  file.path(
    output_dir,
    "05_calibration_plot.png"
  ),
  
  plot_calibration,
  
  width = 8,
  
  height = 6,
  
  dpi = 300
  
)


# ============================================================
# 41. VISUALIZATION 6
# SUPPLIER PREDICTED RISK
# ============================================================

plot_supplier_risk <- supplier_risk %>%
  
  slice_max(
    
    order_by =
      avg_failure_probability,
    
    n = 15
    
  ) %>%
  
  ggplot(
    
    aes(
      
      x = reorder(
        supplier,
        avg_failure_probability
      ),
      
      y =
        avg_failure_probability
      
    )
    
  ) +
  
  geom_col() +
  
  coord_flip() +
  
  scale_y_continuous(
    
    labels =
      scales::percent_format()
    
  ) +
  
  labs(
    
    title =
      "Supplier Ranking berdasarkan Predicted Failure Risk",
    
    x =
      "Supplier",
    
    y =
      "Average Predicted Failure Probability"
    
  ) +
  
  theme_minimal()


ggsave(
  
  file.path(
    output_dir,
    "06_supplier_predicted_risk.png"
  ),
  
  plot_supplier_risk,
  
  width = 9,
  
  height = 7,
  
  dpi = 300
  
)


# ============================================================
# 42. EXPORT DATA
# ============================================================

write_csv(
  
  data,
  
  file.path(
    output_dir,
    "01_clean_data_with_target.csv"
  )
  
)


write_csv(
  
  unmatched_data,
  
  file.path(
    output_dir,
    "02_unmatched_raw_data.csv"
  )
  
)


write_csv(
  
  overlap_audit,
  
  file.path(
    output_dir,
    "03_standard_overlap_audit.csv"
  )
  
)


write_csv(
  
  target_audit,
  
  file.path(
    output_dir,
    "04_target_audit.csv"
  )
  
)


write_csv(
  
  supplier_history,
  
  file.path(
    output_dir,
    "05_supplier_failure_rate.csv"
  )
  
)


write_csv(
  
  metrics,
  
  file.path(
    output_dir,
    "06_model_metrics.csv"
  )
  
)


write_csv(
  
  decision,
  
  file.path(
    output_dir,
    "07_failure_risk_prediction.csv"
  )
  
)


write_csv(
  
  supplier_risk,
  
  file.path(
    output_dir,
    "08_supplier_predicted_risk.csv"
  )
  
)


write_csv(
  
  risk_factors,
  
  file.path(
    output_dir,
    "09_logistic_risk_factors.csv"
  )
  
)


write_csv(
  
  calibration_data,
  
  file.path(
    output_dir,
    "10_calibration_data.csv"
  )
  
)


write_csv(
  
  tuned_model %>%
    collect_metrics(),
  
  file.path(
    output_dir,
    "11_tuning_results.csv"
  )
  
)


# ============================================================
# 43. SAVE MODEL
# ============================================================

saveRDS(
  
  fit_model,
  
  file.path(
    output_dir,
    "logistic_regression_ridge_model.rds"
  )
  
)


# ============================================================
# 44. FINAL SUMMARY
# ============================================================

cat("\n\n")

cat("====================================================\n")
cat("LABORATORY QUALITY RISK MODEL — COMPLETED\n")
cat("====================================================\n")

cat(
  "Raw data                  :",
  nrow(raw),
  "\n"
)

cat(
  "Matched data              :",
  nrow(matched_data),
  "\n"
)

cat(
  "Unmatched data            :",
  nrow(unmatched_data),
  "\n"
)

cat(
  "Modeling observations     :",
  nrow(model_data),
  "\n"
)

cat(
  "Train observations        :",
  nrow(train),
  "\n"
)

cat(
  "Test observations         :",
  nrow(test),
  "\n"
)

cat(
  "Cutoff date               :",
  format(
    cutoff,
    "%d-%m-%Y"
  ),
  "\n"
)

cat(
  "Accuracy                  :",
  round(
    accuracy_value,
    4
  ),
  "\n"
)

cat(
  "Precision                 :",
  round(
    precision_value,
    4
  ),
  "\n"
)

cat(
  "Recall                    :",
  round(
    recall_value,
    4
  ),
  "\n"
)

cat(
  "Specificity               :",
  round(
    specificity_value,
    4
  ),
  "\n"
)

cat(
  "F1                        :",
  round(
    f1_value,
    4
  ),
  "\n"
)

cat(
  "ROC-AUC                   :",
  round(
    roc_auc_value,
    4
  ),
  "\n"
)

cat(
  "Brier Score               :",
  round(
    brier_score,
    4
  ),
  "\n"
)

cat(
  "\nOutput directory:\n",
  output_dir,
  "\n"
)

cat(
  "====================================================\n"
)
