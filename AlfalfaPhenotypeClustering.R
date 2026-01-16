# ==============================================================================
# Alfalfa Phenotype Clustering (Colorblind-Friendly Edition)
# 特点：深色低饱和度配色 (Dark2)，增强对比度，适合色弱人士阅读
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

# 优先级 3: 检查环境中的 'data' (非函数)
} else if(exists("data") && is.data.frame(get("data"))) {
  raw_df <- get("data")
  message(">>> 成功加载环境变量: data")

# 优先级 4: 读取 CSV
} else if(file.exists("RawData_Phenotype.xlsx - Sheet1.csv")) {
  raw_df <- read_csv("RawData_Phenotype.xlsx - Sheet1.csv", show_col_types = FALSE)
  message(">>> 已读取 CSV 文件")

} else {
  vars <- ls()
  stop(paste("错误：未找到有效数据！当前环境变量:", paste(vars, collapse=", ")))
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
folder_name <- paste0("Alfalfa_Cluster_Dark_", timestamp)
dir.create(folder_name, showWarnings = FALSE)

write_csv(summarized_df, file.path(folder_name, "01_Group_Averages.csv"))

# 6. 聚类分析 (全局计算) -------------------------------------------------------
if(nrow(summarized_df) < 3) stop("错误：Group数量少于3，无法聚类。")

# 准备矩阵
mat <- as.matrix(summarized_df[, c("Avg_Height", "Avg_Internode")])
rownames(mat) <- summarized_df$Group

# 标准化与距离
mat_scaled <- scale(mat)
dist_mat <- dist(mat_scaled, method = "euclidean")
hc <- hclust(dist_mat, method = "ward.D2")

# 自动 K 值
heights <- hc$height
k <- 2
if(length(heights) > 1) {
  k_opt <- length(heights) - which.max(diff(heights)) + 1
  k <- max(2, min(k_opt, 8)) # 限制K最大为8，因为Dark2色板只有8色，多了不好看
}

# 全局变量 clusters_vec
clusters_vec <- cutree(hc, k = k) 

# 7. 绘图 (深色低饱和度配色优化) -----------------------------------------------

# 配色方案：使用 Dark2
# Dark2 特点：深色、哑光、对比度高，适合色弱阅读
base_cols <- brewer.pal(n = 8, name = "Dark2")

if(k <= 8) {
  cluster_cols <- base_cols[1:k]
} else {
  # 如果 K > 8，使用 colorRampPalette 基于 Dark2 进行深色扩展
  cluster_cols <- colorRampPalette(base_cols)(k)
}

dend <- as.dendrogram(hc)
dend <- dend %>%
  color_branches(k = k, col = cluster_cols) %>%
  color_labels(k = k, col = cluster_cols) %>%
  set("branches_lwd", 2.5) %>%      # 加粗线条，提高可视性
  set("labels_cex", 0.7) %>%        # 调整字体大小
  set("labels_col", cluster_cols[clusters_vec[order.dendrogram(dend)]]) # 确保标签颜色匹配

plot_func <- function() {
  par(mar = c(8, 4, 4, 2)) 
  plot(dend, 
       main = "Alfalfa Phenotypic Clustering (Colorblind-Friendly)",
       ylab = "Euclidean Distance",
       xlab = "")
  mtext("Groups", side = 1, line = 5, cex = 0.9, font = 2) # 加粗字体
  
  legend("topright", legend = paste("Cluster", 1:k), 
         fill = cluster_cols, bty = "n", border = NA, cex = 0.9,
         title = "Clusters")
  
  # 底部色块
  ordered_cols <- cluster_cols[clusters_vec[order.dendrogram(dend)]]
  colored_bars(colors = ordered_cols, dend = dend, rowLabels = "Cluster", y_shift = -0.05 * max(hc$height))
}

# 导出 PDF
pdf(file.path(folder_name, "02_Cluster_Tree_Dark.pdf"), width = 14, height = 8)
plot_func()
dev.off()

# 导出 PNG (高分辨)
png(file.path(folder_name, "02_Cluster_Tree_Dark.png"), width = 14, height = 8, units = "in", res = 300)
plot_func()
dev.off()

# 8. 结果保存 ------------------------------------------------------------------
res_df <- data.frame(
  Group = names(clusters_vec), 
  Cluster = as.numeric(clusters_vec)
) %>%
  left_join(summarized_df, by = "Group") %>%
  arrange(Cluster)

write_csv(res_df, file.path(folder_name, "03_Cluster_Results.csv"))

message(paste("分析完成！结果已保存至:", folder_name))
message("提示：已应用 Dark2 配色方案，增强了色弱人士的可读性。")
