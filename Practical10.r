library(dplyr)
library(ggplot2)
library(factoextra)

# Load dataset (only numeric features)
data("iris")
iris_data <- iris [, 1:4]

# 1. Elbow Method to find optimal K
fviz_nbclust(iris_data, kmeans, method = "wss") + labs(title = "Elbow Method for Optimal K") # nolint

# 2. Apply K-means clustering with K=3
set.seed(123)
kmeans_model <- kmeans(iris_data, centers = 3, nstart = 20)

# 3. Cluster assignments
kmeans_model$cluster [1:10]
table(kmeans_model$cluster, iris$Species)

# 4. Visualize clusters
fviz_cluster(kmeans_model, data = iris_data, ellipse.type = "norm", palette = "jco", ggtheme = theme_minimal()) # nolint



# Exercise Questions -------------------------------------------->


set.seed(123)
# Qs 1  -------------------------------------------------------->
data(iris)
iris_data <- iris[, 1:4]

k4_iris <- kmeans(iris_data, centers = 4, nstart = 25)

# Cluster assignments (first 15)
print(k4_iris$cluster[1:15])

# Cross-tabulation vs true species
ct1 <- table(Cluster = k4_iris$cluster, Species = iris$Species)
print(ct1)

# Simple cluster-to-species "purity" per cluster
purity <- apply(ct1, 1, function(x) max(x)/sum(x))
print(round(purity, 3))

# Visualize clusters (PCA-based)
fviz_cluster(k4_iris, data = iris_data, ellipse.type = "norm", palette = "jco", ggtheme = theme_minimal(), main = "Qs 1 - K=4 clusters on iris (PCA projection)") # nolint


# Qs 2  -------------------------------------------------------->
data(mtcars)
mtcars_sel <- mtcars %>% select(mpg, hp, wt)

# Scale features (important for k-means)
mtcars_scaled <- scale(mtcars_sel)

# Choose K
k_mtcars <- kmeans(mtcars_scaled, centers = 3, nstart = 25)
mtcars$cluster <- factor(k_mtcars$cluster)

# Show cluster sizes
print(table(mtcars$cluster))

# Cluster centers in original scale (approximated)
centers_unscaled <- t(apply(k_mtcars$centers, 1, function(r) r * apply(mtcars_sel,2,sd) + apply(mtcars_sel,2,mean))) # nolint
colnames(centers_unscaled) <- colnames(mtcars_sel)
print(round(centers_unscaled, 2))

# Show per-cluster descriptive stats (original scale)
cluster_summary <- mtcars %>% group_by(cluster) %>% summarise(across(c(mpg, hp, wt), list(mean = mean, sd = sd), .names = "{.col}_{.fn}"), n = n()) %>% arrange(cluster) # nolint
print(cluster_summary)

# Visualization (PCA-based)
fviz_cluster(k_mtcars, data = mtcars_scaled, ellipse.type = "norm", ggtheme = theme_minimal(), main = "Qs 2 - mtcars clusters (mpg,hp,wt)") # nolint

# Interpretation guide (printable)
cat("\nInterpretation guide for mtcars clusters:\n")
cat("- Check cluster centers above. Higher mpg + lower hp/wt => likely more 'efficient' cars.\n") # nolint
cat("- Clusters with high hp and high wt and low mpg indicate 'powerful/heavy, low mpg' group.\n") # nolint


# Qs 3  -------------------------------------------------------->
fviz_nbclust(iris_data, kmeans, method = "wss") + labs(title = " Qs 3 - Elbow method (Iris) - within-cluster sum of squares") # nolint


# Qs 4  -------------------------------------------------------->
k3_iris <- kmeans(iris_data, centers = 3, nstart = 25)
fviz_cluster(k3_iris, data = iris_data, ellipse.type = "norm", palette = "aaas", ggtheme = theme_minimal(), main = "Qs 4 - K=3 clusters on iris (PCA projection)") # nolint


# Qs 5  -------------------------------------------------------->
iris_sepal <- iris[, c("Sepal.Length", "Sepal.Width")]

# scale then kmeans
iris_sepal_scaled <- scale(iris_sepal)
k_sepal <- kmeans(iris_sepal_scaled, centers = 3, nstart = 25)

# table vs species
ct_sepal <- table(Cluster = k_sepal$cluster, Species = iris$Species)
print(ct_sepal)

# Plot
fviz_cluster(k_sepal, data = iris_sepal_scaled, ellipse.type = "norm", geom = "point", stand = FALSE, ggtheme = theme_minimal(), main = "Qs 5 - Clusters on Sepal features (K=3)") # nolint

# Show cluster means (original scale)
centers_sepal_unscaled <- t(apply(k_sepal$centers, 1, function(r) r * apply(iris_sepal,2,sd) + apply(iris_sepal,2,mean))) # nolint
print(round(centers_sepal_unscaled, 2))