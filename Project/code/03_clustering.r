# 03_clustering.R (robust, full replacement)
# Run from project root: Rscript code/03_clustering.R

# ---------------------------
# 0) Install / load required packages (only installs missing)
# ---------------------------

# load libraries
library(dplyr)
library(ggplot2)
library(factoextra)
library(cluster)
library(NbClust)
library(gridExtra)

# ---------------------------
# 1) Paths & output folders
# ---------------------------
# Update this if your path differs
input_csv <- file.path("D:", "Docx", "CodeExplorer", "R-Language", "Project", "output", "mall_customers_clean.csv")
out_base  <- file.path("D:", "Docx", "CodeExplorer", "R-Language", "Project", "output")
out_plots <- file.path(out_base, "plots")
out_tables <- file.path(out_base, "tables")

dir.create(out_plots, recursive = TRUE, showWarnings = FALSE)
dir.create(out_tables, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_csv)) stop("Input CSV not found: ", input_csv)

# ---------------------------
# 2) Read data and detect columns (robust)
# ---------------------------
mall <- read.csv(input_csv, stringsAsFactors = FALSE)
cat("Loaded rows:", nrow(mall), "cols:", ncol(mall), "\n")
cat("Original column names:\n"); print(names(mall))

# normalize names for detection
names_orig <- names(mall)
names_clean <- tolower(names_orig) %>%
  gsub("[. ]+", "_", .) %>%
  gsub("_+$", "", .)
names(mall) <- names_clean
cat("Cleaned col names:\n"); print(names(mall))

# helper to find a column by a list of patterns
find_col <- function(df_names, patterns) {
  for (p in patterns) {
    idx <- grep(p, df_names, ignore.case = TRUE)
    if (length(idx) > 0) return(df_names[idx[1]])
  }
  return(NA_character_)
}

income_col <- find_col(names(mall), c("annual_income", "income", "annual_income_k", "annual_income_k_"))
spend_col  <- find_col(names(mall), c("spending_score", "spend", "spending_score_1_100", "spending_score_1_100_"))
age_col    <- find_col(names(mall), c("\\bage\\b", "^age$"))
gender_col <- find_col(names(mall), c("gender", "genre", "^sex$"))

cat("Detected columns:\n")
print(list(income = income_col, spending = spend_col, age = age_col, gender = gender_col))

if (any(is.na(c(income_col, spend_col)))) {
  stop("Could not detect required income/spending columns. Available columns:\n", paste(names(mall), collapse = ", "))
}

# rename to standard names
mall <- mall %>%
  rename(
    annual_income = !!income_col,
    spending_score = !!spend_col
  )

# Convert types numeric
mall$annual_income <- as.numeric(gsub("[^0-9.-]", "", as.character(mall$annual_income)))
mall$spending_score <- as.numeric(gsub("[^0-9.-]", "", as.character(mall$spending_score)))

# optional convert age/gender if present
if (!is.na(age_col)) mall$age <- as.numeric(gsub("[^0-9.-]", "", as.character(mall[[age_col]])))
if (!is.na(gender_col)) mall$gender <- as.factor(mall[[gender_col]])

# drop rows with missing required features
mall <- mall %>% filter(!is.na(annual_income) & !is.na(spending_score))
cat("After removing NA rows, rows =", nrow(mall), "\n")

# ---------------------------
# 3) Prepare features and scale
# ---------------------------
features <- mall %>% select(annual_income, spending_score)
features_scaled <- scale(features)

# ---------------------------
# 4) Elbow & Silhouette plots (save)
# ---------------------------
p_elbow <- fviz_nbclust(features_scaled, kmeans, method = "wss") +
  labs(title = "Elbow Method for Optimal K (Income & Spending)")
ggsave(filename = file.path(out_plots, "elbow.png"), plot = p_elbow, width = 7, height = 5)

p_sil <- fviz_nbclust(features_scaled, kmeans, method = "silhouette") +
  labs(title = "Average Silhouette Width for K (Income & Spending)")
ggsave(filename = file.path(out_plots, "silhouette.png"), plot = p_sil, width = 7, height = 5)

cat("Saved elbow and silhouette plots to:", out_plots, "\n")

# ---------------------------
# 5) NbClust (single call) - robust extraction of majority K
# ---------------------------
# NbClust can take time; run it and handle return shape
set.seed(123)
nb <- tryCatch(
  NbClust(data = features_scaled, distance = "euclidean", min.nc = 2, max.nc = 10, method = "kmeans"),
  error = function(e) { warning("NbClust error: ", e$message); return(NULL) }
)

bestK <- NA_integer_
if (!is.null(nb) && !is.null(nb$Best.nc)) {
  b <- nb$Best.nc
  # b can be matrix or vector
  votes <- NULL
  if (is.matrix(b)) {
    # first row often contains 'Number_clusters' per index
    votes <- as.numeric(b[1, ])
  } else if (is.vector(b) || is.numeric(b)) {
    votes <- as.numeric(b)
  }
  votes <- votes[!is.na(votes)]
  if (length(votes) > 0) {
    vote_tbl <- sort(table(votes), decreasing = TRUE)
    bestK <- as.integer(names(vote_tbl)[1])
    cat("NbClust majority vote suggests K =", bestK, "\n")
  } else {
    cat("NbClust returned Best.nc but no usable votes.\n")
  }
} else {
  cat("NbClust not available or returned NULL.\n")
}

# ---------------------------
# 6) Decide K (respect NbClust if available, else fallback)
# ---------------------------
if (is.na(bestK)) {
  # fallback strategy: pick K with highest silhouette average from 2:10 (compute quickly)
  sil_avgs <- sapply(2:10, function(k) {
    km_tmp <- kmeans(features_scaled, centers = k, nstart = 10)
    ss <- silhouette(km_tmp$cluster, dist(features_scaled))
    mean(ss[, "sil_width"], na.rm = TRUE)
  })
  k_sil_best <- which.max(sil_avgs) + 1  # +1 because index starts at 1 -> k=2
  cat("Fallback silhouette-based best K =", k_sil_best, "\n")
  bestK <- k_sil_best
}

K <- bestK
cat("Final chosen K =", K, "\n")

# ---------------------------
# 7) Run kmeans with chosen K
# ---------------------------
set.seed(123)
km <- kmeans(features_scaled, centers = K, nstart = 50)

# attach cluster labels
mall$cluster <- factor(km$cluster)

# Save full data with cluster labels
out_csv_clusters <- file.path(out_base, "mall_customers_with_clusters.csv")
write.csv(mall, out_csv_clusters, row.names = FALSE)
cat("Saved cluster assignments to:", out_csv_clusters, "\n")

# ---------------------------
# 8) Diagnostics and summaries (print + save)
# ---------------------------
# cluster counts
counts <- table(mall$cluster)
print(counts)

# cluster centers (scaled)
cat("Cluster centers (scaled):\n"); print(km$centers)

# convert centers back to original scale
orig_means <- apply(features, 2, mean)
orig_sds   <- apply(features, 2, sd)
centers_unscaled <- t(apply(km$centers, 1, function(r) r * orig_sds + orig_means))
colnames(centers_unscaled) <- colnames(features)
cat("Cluster centers (original scale):\n"); print(round(centers_unscaled, 2))

# per-cluster summary (original scale)
cluster_summary <- mall %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    avg_age = if ("age" %in% names(mall)) round(mean(age, na.rm = TRUE),1) else NA_real_,
    avg_income = round(mean(annual_income, na.rm = TRUE),2),
    sd_income  = round(sd(annual_income, na.rm = TRUE),2),
    avg_spend  = round(mean(spending_score, na.rm = TRUE),2),
    sd_spend   = round(sd(spending_score, na.rm = TRUE),2)
  ) %>% arrange(as.numeric(cluster))

print(cluster_summary)
write.csv(cluster_summary, file.path(out_tables, "cluster_summary.csv"), row.names = FALSE)
cat("Saved cluster summary to:", file.path(out_tables, "cluster_summary.csv"), "\n")

# ---------------------------
# 9) Visualizations: PCA cluster plot + scatter plot (Income vs Spending)
# ---------------------------
p_cluster <- fviz_cluster(km, data = features_scaled, geom = "point", stand = FALSE,
                          ellipse.type = "norm", palette = "jco", ggtheme = theme_minimal()) +
  labs(title = paste("K-means Clusters (K =", K, ") - PCA projection (Income vs Spending)"))
ggsave(file.path(out_plots, "kmeans_clusters_pca.png"), p_cluster, width = 8, height = 6)

p_scatter <- ggplot(mall, aes(x = annual_income, y = spending_score, color = cluster)) +
  geom_point(size=3, alpha=0.85) +
  labs(title = paste("Income vs Spending (K =", K, ")"), x = "Annual Income (k$)", y = "Spending Score") +
  theme_minimal()
ggsave(file.path(out_plots, "income_spend_clusters.png"), p_scatter, width = 8, height = 6)

cat("Saved cluster plots to:", out_plots, "\n")

# ---------------------------
# 10) Done
# ---------------------------
cat("Clustering complete. Review plots and cluster_summary.csv for interpretation.\n")