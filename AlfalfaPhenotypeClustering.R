# ==============================================================================
# Alfalfa Phenotype Clustering Analysis
# 修复：变量作用域问题 (解决 function coercion error)
# ==============================================================================

# 1. 环境准备 ------------------------------------------------------------------
required_packages <- c("dplyr", "readr", "cluster", "dendextend", "RColorBrewer", "stringr")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages, repos="https://cran.rstudio.com/")

library(dplyr)
library(readr)
library(cluster)
library(dendextend)
library(RColorBrewer)
library(stringr)

# 2. 稳健的数据加载 ------------------------------------------------------------
raw_df <- NULL

# 优先级 1: 检查环境中的 'RawData_Phenotype'
if(exists("RawData_Phenotype") && is.data.frame(get("RawData_Phenotype"))) {
  raw_df <- get("RawData_Phenotype")
  message(">>> 成功加载环境变量: RawData_Phenotype")
  
  # 优先级 2: 检查环境中的 'pheno_data'
} else if(exists("pheno_data") && is.data.frame(get("pheno_data"))) {
  raw_df <- get("pheno_data")
  message(">>> 成功加载环境变量: pheno_data")
  
  # 优先级 3: 检查环境中的 'data' (且不是函数)
} else if(exists("data") && is.data.frame(get("data"))) {
  raw_df <- get("data")
  message(">>> 成功加载环境变量: data")
  
  # 优先级 4: 读取 CSV
} else if(file.exists("RawData_Phenotype.xlsx - Sheet1.csv")) {
  raw_df <- read_csv("RawData_Phenotype.xlsx - Sheet1.csv", show_col_types = FALSE)
  message(">>> 已读取 CSV 文件")
  
} else {
  vars <- ls()
  stop(paste("错误：未找到有效数据！当前环境中的变量:", paste(vars, collapse=", ")))
}

# 3. 数据清洗 ------------------------------------------------------------------
message("正在清洗数据...")

all_cols <- names(raw_df)
idx_group <- grep("Group", all_cols, ignore.case = TRUE)[1]
idx_height <- grep("Height", all_cols, ignore.case = TRUE)[1]
idx_node  <- grep("Internode", all_cols, ignore.case = TRUE)[1]

if(is.na(idx_group) || is.na(idx_height) || is.na(idx_node)) {
  message("警告：按名称匹配失败，尝试按位置提取(1,3,4)...")
  if(ncol(raw_df) >= 4) {
    clean_df <- raw_df[, c(1, 3, 4)]
  } else {
    stop("错误：数据列数不足。")
  }
} else {
  clean_df <- raw_df[, c(idx_group, idx_height, idx_node)]
}

colnames(clean_df) <- c("Group", "Height", "Internode")

clean_df <- clean_df %>%
  mutate(
    Height = suppressWarnings(as.numeric(Height)),
    Internode = suppressWarnings(as.numeric(Internode))
  ) %>%
  filter(!is.na(Group) & Group != "") %>%
  filter(!is.na(Height) & !is.na(Internode))

message(paste("清洗后有效样本数:", nrow(clean_df)))
if(nrow(clean_df) < 2) stop("错误：有效数据不足。")

# 4. 聚合计算 ------------------------------------------------------------------
summarized_df <- clean_df %>%
  group_by(Group) %>%
  summarise(
    Avg_Height = mean(Height),
    Avg_Internode = mean(Internode),
    Count = n()
  ) %>%
  filter(Count > 0)

# 5. 输出目录 ------------------------------------------------------------------
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
folder_name <- paste0("Alfalfa_Cluster_Final_", timestamp)
dir.create(folder_name, showWarnings = FALSE)

write_csv(summarized_df, file.path(folder_name, "01_Group_Averages.csv"))

# 6. 聚类分析 (全局计算) -------------------------------------------------------
if(nrow(summarized_df) < 3) stop("错误：Group数量少于3，无法聚类。")

# 准备矩阵
mat <- as.matrix(summarized_df[, c("Avg_Height", "Avg_Internode")])
rownames(mat) <- summarized_df$Group # 确保矩阵有行名

# 标准化与距离
mat_scaled <- scale(mat)
dist_mat <- dist(mat_scaled, method = "euclidean")
hc <- hclust(dist_mat, method = "ward.D2")

# 自动 K 值
heights <- hc$height
k <- 2
if(length(heights) > 1) {
  k_opt <- length(heights) - which.max(diff(heights)) + 1
  k <- max(2, min(k_opt, 10))
}

# 【关键修改】：在全局作用域计算 clusters 变量
# 这样它既是 vector 又能在后续步骤被访问
clusters_vec <- cutree(hc, k = k) 

# 7. 绘图 ----------------------------------------------------------------------
cols <- brewer.pal(n = 12, name = "Set3")
if(k <= 12) cluster_cols <- cols[1:k] else cluster_cols <- colorRampPalette(cols)(k)

dend <- as.dendrogram(hc)
dend <- dend %>%
  color_branches(k = k, col = cluster_cols) %>%
  color_labels(k = k, col = cluster_cols) %>%
  set("branches_lwd", 2) %>%
  set("labels_cex", 0.6)

plot_func <- function() {
  par(mar = c(8, 4, 4, 2)) 
  plot(dend, 
       main = "Alfalfa Phenotypic Clustering",
       ylab = "Euclidean Distance",
       xlab = "")
  mtext("Groups", side = 1, line = 5, cex = 0.8)
  
  legend("topright", legend = paste("Cluster", 1:k), 
         fill = cluster_cols, bty = "n", border = NA, cex = 0.8)
  
  # 使用全局变量 clusters_vec
  ordered_cols <- cluster_cols[clusters_vec[order.dendrogram(dend)]]
  colored_bars(colors = ordered_cols, dend = dend, rowLabels = "Cluster", y_shift = -0.05 * max(hc$height))
}

pdf(file.path(folder_name, "02_Cluster_Tree.pdf"), width = 14, height = 8)
plot_func()
dev.off()

png(file.path(folder_name, "02_Cluster_Tree.png"), width = 14, height = 8, units = "in", res = 300)
plot_func()
dev.off()

# 8. 结果保存 (修复点) ---------------------------------------------------------
# 使用全局变量 clusters_vec，并显式指定 names
res_df <- data.frame(
  Group = names(clusters_vec), 
  Cluster = as.numeric(clusters_vec) # 确保是数值
) %>%
  left_join(summarized_df, by = "Group") %>%
  arrange(Cluster)

write_csv(res_df, file.path(folder_name, "03_Cluster_Results.csv"))

message(paste("全部完成！结果已保存至:", folder_name))
