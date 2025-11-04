# 04_cluster_profile.R
library(dplyr)

mall <- read.csv("D:/Docx/CodeExplorer/R-Language/Project/output/mall_customers_with_clusters.csv")
mall$cluster <- factor(mall$cluster)

# Cluster sizes
print(table(mall$cluster))

# Cluster summary (means)
cluster_summary <- mall %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    avg_age = round(mean(age, na.rm = TRUE),1),
    avg_income = round(mean(annual_income, na.rm = TRUE), 1),
    avg_spend = round(mean(spending_score, na.rm = TRUE), 1)
  ) %>% arrange(cluster) # nolint

print(cluster_summary)
write.csv(cluster_summary, "D:/Docx/CodeExplorer/R-Language/Project/output/tables/cluster_summary.csv", row.names = FALSE) # nolint

# Show a few customers per cluster (useful for presentation)
head_customers <- mall %>% group_by(cluster) %>% slice_head(n = 5)
write.csv(head_customers, "D:/Docx/CodeExplorer/R-Language/Project/output/tables/sample_customers_per_cluster.csv", row.names = FALSE) # nolint
print(head_customers)