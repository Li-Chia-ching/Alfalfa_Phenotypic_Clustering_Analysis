# 7. 绘图 (修正版：解决色块破碎问题) -------------------------------------------

# 重新计算树对象（确保状态一致）
dend <- as.dendrogram(hc)

# 1. 设置树枝颜色和标签
dend <- dend %>%
  set("branches_col", "black") %>%  # 树枝全黑
  set("branches_lwd", 1.5) %>%      # 加粗
  color_labels(k = k, col = cluster_cols) %>% # 标签根据Cluster着色
  set("labels_cex", 0.7)

# 2. 【核心修复】计算底部色块的正确顺序
# 获取树状图目前从左到右的叶子索引
dend_order <- order.dendrogram(dend)

# 按照这个视觉顺序，提取对应的 Cluster 编号
ordered_clusters <- clusters_vec[dend_order]

# 将编号映射为颜色
ordered_cols <- cluster_cols[ordered_clusters]

# 【关键步骤】去除向量的名字！
# 这防止了 colored_bars 试图再次自动排序，强制它按视觉顺序绘图
ordered_cols <- unname(ordered_cols) 

plot_func <- function() {
  # 调整边距 (下边距留大一点给色块和标签)
  par(mar = c(10, 4, 4, 2)) 
  
  plot(dend, 
       main = "Alfalfa Phenotypic Clustering (Colorblind-Friendly)",
       sub = paste("Method: Euclidean Dist + Ward.D2 | k =", k),
       ylab = "Euclidean Distance",
       xlab = "")
  
  mtext("Groups", side = 1, line = 6, cex = 0.9, font = 2)
  
  legend("topright", legend = paste("Cluster", 1:k), 
         fill = cluster_cols, bty = "n", border = NA, cex = 0.9,
         title = "Clusters")
  
  # 绘制底部色块
  # 注意：这里直接使用我们处理过的 ordered_cols
  colored_bars(colors = ordered_cols, 
               dend = dend, 
               rowLabels = "Cluster", 
               y_shift = -0.05 * max(hc$height),
               sort_by_labels_order = FALSE) # 双重保险：禁止自动重排
}
