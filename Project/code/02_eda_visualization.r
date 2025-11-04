# 02_eda_visualization.R
library(dplyr)
library(ggplot2)
library(scales)
library(gridExtra)

mall <- read.csv("D:/Docx/CodeExplorer/R-Language/Project/output/mall_customers_clean.csv", stringsAsFactors = FALSE) # nolint
mall$gender <- as.factor(mall$gender)

# Basic stats
summary_stats <- mall %>% summarise(
  n = n(),
  age_mean = mean(age, na.rm = TRUE),
  income_mean = mean(annual_income_k, na.rm=TRUE),
  spend_mean = mean(spending_score_1_100_, na.rm=TRUE)
)
print(summary_stats)
write.csv(summary_stats, "D:/Docx/CodeExplorer/R-Language/Project/output/tables/summary_stats.csv", row.names = FALSE) # nolint

# Histogram: annual income
p1 <- ggplot(mall, aes(x = annual_income_k)) +
  geom_histogram(bins = 15, fill = "steelblue", color = "black") +
  labs(title = "Distribution of Annual Income (k$)", x = "Annual Income (k$)", y = "Count") # nolint

# Histogram: spending score
p2 <- ggplot(mall, aes(x = spending_score_1_100_)) +
  geom_histogram(bins = 15, fill = "darkorange", color = "black") +
  labs(title = "Distribution of Spending Score (1-100)", x = "Spending Score", y = "Count") # nolint

# Boxplot income by gender
p3 <- ggplot(mall, aes(x=gender, y=annual_income_k, fill=gender)) +
  geom_boxplot() + labs(title = "Annual income by Gender", x="Gender", y="Annual Income (k$)") + # nolint
  theme(legend.position = "none")

# Boxplot spending by gender
p4 <- ggplot(mall, aes(x=gender, y=spending_score_1_100_, fill=gender)) +
  geom_boxplot() + labs(title = "Spending Score by Gender", x="Gender", y="Spending Score") + # nolint
  theme(legend.position = "none")

# Scatter: income vs spending colored by gender
p5 <- ggplot(mall, aes(x = annual_income_k, y = spending_score_1_100_, color = gender)) + # nolint
  geom_point(size=3, alpha=0.7) +
  labs(title = "Annual Income vs Spending Score", x = "Annual Income (k$)", y = "Spending Score") # nolint

# Save plots
# dir.create("../output/plots", recursive = TRUE, showWarnings = FALSE) # nolint
ggsave("D:/Docx/CodeExplorer/R-Language/Project/output/plots/income_hist.png", p1, width = 6, height = 4) # nolint
ggsave("D:/Docx/CodeExplorer/R-Language/Project/output/plots/spend_hist.png", p2, width = 6, height = 4) # nolint
ggsave("D:/Docx/CodeExplorer/R-Language/Project/output/plots/income_by_gender_box.png", p3, width = 6, height = 4) # nolint
ggsave("D:/Docx/CodeExplorer/R-Language/Project/output/plots/spend_by_gender_box.png", p4, width = 6, height = 4) # nolint
ggsave("D:/Docx/CodeExplorer/R-Language/Project/output/plots/income_vs_spend.png", p5, width = 6, height = 4) # nolint

# Print quick grid
gridExtra::grid.arrange(p1, p2, p5, ncol = 2)