# 01_load_and_clean.R
library(dplyr)

# Load
data_path <- "D:/Docx/CodeExplorer/R-Language/Project/data/Mall_Customers.csv"   # adjust if running from repo root when sourcing # nolint
mall <- read.csv(data_path, stringsAsFactors = FALSE)

# Quick inspect
str(mall)
head(mall)
summary(mall)

# Clean names:
colnames(mall) <- gsub("[. ]+", "_", colnames(mall))
colnames(mall) <- gsub("__+", "_", colnames(mall))
colnames(mall) <- gsub("\\.+$", "", colnames(mall))
colnames(mall) <- gsub("^X", "", colnames(mall))
colnames(mall) <- tolower(colnames(mall))

colnames(mall)


# Check for missing values
colSums(is.na(mall))

# Remove duplicates (if any)
mall <- mall %>% distinct()

# Convert types
mall$gender <- as.factor(mall$gender)
mall$customerid <- as.character(mall$customerid)
mall$age <- as.numeric(mall$age)
mall$annual_income_k <- as.numeric(mall$annual_income_k)
mall$spending_score_1_100_ <- as.numeric(mall$spending_score_1_100_)

# Save cleaned data (optional)
write.csv(mall, file = "D:/Docx/CodeExplorer/R-Language/Project/output/mall_customers_clean.csv", row.names = FALSE) # nolint

cat("Data loaded and cleaned. Rows:", nrow(mall), "Columns:", ncol(mall), "\n")