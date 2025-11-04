# 05_optional_classification.R (robust replacement)

library(dplyr)
library(caret)
library(rpart)
library(pROC)
library(ggplot2)

# -------------------------------
# 1) Paths & ensure output folder
# -------------------------------
input_csv <- file.path("D:", "Docx", "CodeExplorer", "R-Language", "Project", "output", "mall_customers_clean.csv")
out_base  <- file.path("D:", "Docx", "CodeExplorer", "R-Language", "Project", "output")
out_plots <- file.path(out_base, "plots")
dir.create(out_plots, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv)

# -------------------------------
# 2) Load and normalize column names
# -------------------------------
mall <- read.csv(input_csv, stringsAsFactors = FALSE)
names_orig <- names(mall)
names_clean <- tolower(names_orig) %>%
  gsub("[. ]+", "_", .) %>%
  gsub("_+$", "", .)
names(mall) <- names_clean

# detect columns (robust)
find_col <- function(names_vec, patterns) {
  for (p in patterns) {
    idx <- grep(p, names_vec, ignore.case = TRUE)
    if (length(idx) > 0) return(names_vec[idx[1]])
  }
  return(NA_character_)
}

gender_col <- find_col(names(mall), c("^gender$", "^genre$", "^sex$"))
age_col    <- find_col(names(mall), c("^age$"))
income_col <- find_col(names(mall), c("annual_income", "income", "annual_income_k"))
spend_col  <- find_col(names(mall), c("spending_score", "spend", "spending_score_1_100"))

cat("Detected columns -> gender:", gender_col, " age:", age_col, " income:", income_col, " spend:", spend_col, "\n")
if (is.na(gender_col) || is.na(age_col) || is.na(income_col) || is.na(spend_col)) {
  stop("Required columns not detected. Available columns: ", paste(names(mall), collapse = ", "))
}

# rename to standard names
mall <- mall %>%
  rename(
    gender = !!gender_col,
    age = !!age_col,
    annual_income = !!income_col,
    spending_score = !!spend_col
  )

# convert types and clean numeric characters if needed
mall$gender <- as.factor(mall$gender)
mall$age <- as.numeric(gsub("[^0-9.-]", "", as.character(mall$age)))
mall$annual_income <- as.numeric(gsub("[^0-9.-]", "", as.character(mall$annual_income)))
mall$spending_score <- as.numeric(gsub("[^0-9.-]", "", as.character(mall$spending_score)))

# drop rows with NA in required cols
mall <- mall %>% filter(!is.na(gender) & !is.na(age) & !is.na(annual_income) & !is.na(spending_score))
cat("Rows after dropping NA:", nrow(mall), "\n")

# -------------------------------
# 3) Prepare data and split
# -------------------------------
set.seed(123)
train_idx <- createDataPartition(mall$gender, p = 0.7, list = FALSE)
train <- mall[train_idx, c("gender","age","annual_income","spending_score")]
test  <- mall[-train_idx, c("gender","age","annual_income","spending_score")]

# ensure factor levels consistent
train$gender <- factor(train$gender)
test$gender  <- factor(test$gender, levels = levels(train$gender))

cat("Training class distribution:\n"); print(table(train$gender))
cat("Test class distribution:\n"); print(table(test$gender))

# -------------------------------
# 4) Decision Tree
# -------------------------------
tree_mod <- rpart(gender ~ ., data = train, method = "class")
# predictions (class)
pred_tree <- predict(tree_mod, test, type = "class")
cm_tree <- confusionMatrix(pred_tree, test$gender)
cat("\nDecision Tree Confusion Matrix:\n"); print(cm_tree)

# -------------------------------
# 5) Logistic Regression (binary)
#    - Works for binary gender (two levels). If >2 levels, this will error.
# -------------------------------
if (nlevels(train$gender) != 2) {
  warning("Gender has not exactly 2 levels. Logistic regression (binomial) requires binary target. Skipping logistic model.")
} else {
  # glm with binomial family: ensure reference level (first) is used; we will predict probability of positive = second level
  # By default, glm models probability of second level if using as.numeric(gender==level2) or use contrasts;
  # easier: get numeric outcome for roc computation later.
  level_pos <- levels(train$gender)[2]  # treated as "positive" for ROC/AUC
  cat("Logistic: positive class set to:", level_pos, "\n")
  
  log_mod <- glm(gender ~ age + annual_income + spending_score, data = train, family = binomial)
  # predicted probabilities of *being* level_pos
  # If predict gives prob of baseline level, get probabilities via model matrix; simpler is to compute:
  prob_log <- predict(log_mod, test, type = "response")
  # Determine which level correspond to success prob: we check predicted class mapping
  # Map predicted probability > 0.5 to level_pos, else to other
  pred_log <- factor(ifelse(prob_log > 0.5, level_pos, levels(train$gender)[1]), levels = levels(train$gender))
  cm_log <- confusionMatrix(pred_log, test$gender)
  cat("\nLogistic Regression Confusion Matrix:\n"); print(cm_log)
  
  # ROC & AUC
  # Build numeric true vector for positive class:
  true_pos_numeric <- as.numeric(test$gender == level_pos)
  roc_obj <- roc(response = true_pos_numeric, predictor = prob_log)
  auc_val <- auc(roc_obj)
  cat("\nLogistic ROC AUC:", round(as.numeric(auc_val), 4), "\n")
  
  # Save ROC plot
  roc_plot_path <- file.path(out_plots, "roc_gender.png")
  png(filename = roc_plot_path, width = 800, height = 600)
  plot(roc_obj, main = paste("ROC - Logistic Regression (AUC =", round(as.numeric(auc_val), 3), ")"))
  dev.off()
  cat("ROC plot saved to:", roc_plot_path, "\n")
}

# -------------------------------
# 6) Save models (optional) and end
# -------------------------------
# saveRDS(tree_mod, file = file.path(out_base, "tree_gender_model.rds"))
# if binary and created: saveRDS(log_mod, file = file.path(out_base, "logistic_gender_model.rds"))

cat("Classification script finished.\n")
