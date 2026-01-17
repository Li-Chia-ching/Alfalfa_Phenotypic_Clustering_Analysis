[![DOI](https://zenodo.org/badge/1135815128.svg)](https://doi.org/10.5281/zenodo.18280947)
## Overview / 概述

This script is designed for phenotypic clustering analysis of multiple alfalfa lines. It calculates genetic distances based on plant height and internode number data and generates hierarchical clustering dendrograms. The script features **multi-source data compatibility** and **automated clustering** functionality.

本脚本用于苜蓿多个株系的表型数据聚类分析，通过株高和节间数计算遗传距离，并生成系统聚类树状图。脚本具有**多重数据源兼容性**和**自动化聚类**功能。

## Script Features / 脚本特点

### 🛠️ Core Functions / 核心功能
- **Intelligent Data Loading / 智能数据加载**: Supports multiple data sources including environment variables and CSV files.
- **Automated Data Processing / 自动化数据处理**: Automatically identifies key columns and cleans invalid data.
- **Dynamic Clustering Analysis / 动态聚类分析**: Automatically determines the optimal number of clusters (K-value).
- **High-Quality Visualization / 高质量可视化**: Generates clustering dendrograms in both PDF and PNG formats.
- **Comprehensive Result Output / 完整结果输出**: Saves clustering results and statistical summaries.

### 🔧 Technical Features / 技术特性
- **Scope Fix / 作用域修复**: Resolves common variable scope issues in R environments.
- **Error Handling / 错误处理**: Comprehensive error detection and user prompts.
- **Timestamp Management / 时间戳管理**: Automatically creates timestamped result folders.
- **Color Optimization / 颜色优化**: Uses ColorBrewer color schemes to ensure visualization quality.

## Environment Configuration / 环境配置

### Required R Packages / 必需R包
The script automatically checks and installs the following required packages:

| Package Name | Purpose / 用途 | Version Requirement |
|--------------|----------------|---------------------|
| `dplyr` | Data wrangling and transformation | ≥1.0.0 |
| `readr` | Data reading | ≥2.0.0 |
| `cluster` | Clustering analysis | ≥2.1.0 |
| `dendextend` | Dendrogram enhancement | ≥1.17.0 |
| `RColorBrewer` | Color schemes | ≥1.1.3 |
| `stringr` | String manipulation | ≥1.4.0 |

### Installation Method / 安装方式
The script includes automatic package management and will install missing packages on first run:
```r
# Automatic installation code is integrated into the script
required_packages <- c("dplyr", "readr", "cluster", "dendextend", "RColorBrewer", "stringr")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)
```

## Data Preparation / 数据准备

### Data Format Requirements / 数据格式要求
The script supports the following data formats (in descending priority):

1. **R Environment Variables / R环境变量** (priority loading order):
   - `RawData_Phenotype` (recommended)
   - `pheno_data`
   - `data`

2. **CSV File / CSV文件**:
   - Filename: `RawData_Phenotype.xlsx - Sheet1.csv`

### Data Structure Requirements / 数据结构要求
Data should contain the following key information (column names are case-insensitive):
- **Group / 株系标识**: Line identifier (required)
- **Height / 株高**: Plant height measurement (numeric)
- **Internode / 节间数**: Internode count (numeric)

Example data format / 示例数据格式:
```csv
Group,Height,Internode
Line1,85.2,12
Line1,83.7,11
Line2,92.1,14
...
```

## User Guide / 使用指南

### Quick Start / 快速开始
1. Load data into the R environment (or prepare a CSV file) / 将数据加载到R环境（或准备好CSV文件）
2. Run the complete script / 运行完整脚本
3. Check the automatically generated `Alfalfa_Cluster_Final_[timestamp]` folder / 查看自动生成的`Alfalfa_Cluster_Final_[时间戳]`文件夹

### Detailed Steps / 详细步骤
```r
# 1. Prepare data (example) / 准备数据（示例）
RawData_Phenotype <- data.frame(
  Group = rep(paste0("Line", 1:10), each=5),
  Height = rnorm(50, 80, 10),
  Internode = rnorm(50, 12, 2)
)

# 2. Run the script / 运行脚本
source("Alfalfa_Clustering_Script.R")

# 3. Check results / 查看结果
list.files("Alfalfa_Cluster_Final_20240101_120000/")
```

## Output Files / 输出文件

The script generates the following files after execution:

| Filename | Description / 内容说明 |
|----------|------------------------|
| `01_Group_Averages.csv` | Statistical averages for each line / 各株系平均值统计 |
| `02_Cluster_Tree.pdf` | High-quality vector graphic (PDF format) / 高质量矢量图（PDF格式） |
| `02_Cluster_Tree.png` | High-resolution bitmap (PNG format) / 高分辨率位图（PNG格式） |
| `03_Cluster_Results.csv` | Complete clustering analysis results / 完整聚类分析结果 |

### Result File Contents / 结果文件内容
- **01_Group_Averages.csv**: Average plant height, average internode count, and sample size for each line
- **03_Cluster_Results.csv**: Complete data including line, assigned cluster, and average phenotypic values

## Algorithm Details / 算法细节

### Data Processing Flow / 数据处理流程
1. **Data Cleaning / 数据清洗** → 2. **Data Aggregation / 数据聚合** → 3. **Standardization / 标准化** → 4. **Distance Calculation / 距离计算** → 5. **Hierarchical Clustering / 层次聚类**

### Clustering Parameters / 聚类参数
- **Distance Metric / 距离度量**: Euclidean distance
- **Clustering Method / 聚类方法**: Ward.D2 method (minimum variance)
- **Standardization / 标准化**: Z-score standardization (mean=0, SD=1)
- **K-value Determination / K值确定**: Heuristic algorithm based on dendrogram height changes

### Visualization Parameters / 可视化参数
- **Branch Colors / 分支颜色**: Set3 palette (up to 12 clusters)
- **Label Size / 标签大小**: Adaptive adjustment
- **Legend / 图例**: Automatic cluster group labeling
- **Scale / 标尺**: Displays genetic distance scale

## Troubleshooting / 故障排除

### Common Issues / 常见问题
1. **"No valid data found" error / "未找到有效数据"错误**
   - Check if data is loaded into the environment / 检查数据是否加载到环境
   - Or confirm the CSV file exists in the working directory / 或确认CSV文件存在于工作目录

2. **"Less than 3 Groups, cannot cluster" warning / "Group数量少于3，无法聚类"警告**
   - At least 3 different lines are required for clustering analysis / 需要至少3个不同的株系才能进行聚类分析

3. **Column name identification failure / 列名识别失败**
   - The script will attempt to extract data by position (columns 1, 3, 4) / 脚本会尝试按位置（第1、3、4列）提取数据

4. **Insufficient colors / 颜色数量不足**
   - When the number of clusters exceeds 12, color interpolation is automatically used / 当聚类数超过12时，自动使用颜色插值

### Debugging Suggestions / 调试建议
```r
# Check data loading / 检查数据加载
exists("RawData_Phenotype")
ls()

# View data summary / 查看数据摘要
summary(clean_df)
table(summarized_df$Count)
```

## Important Notes / 注意事项

### Data Quality / 数据质量
1. **Sample Size Requirements / 样本量要求**: At least 3 individuals per line are recommended
2. **Missing Value Handling / 缺失值处理**: Rows containing NA values are automatically removed
3. **Outlier Impact / 异常值影响**: Extreme values may significantly affect clustering results

### Technical Limitations / 技术限制
1. **Clustering Interpretation / 聚类解释**: Clustering results reflect phenotypic similarity, not necessarily genetic relationships
2. **K-value Selection / K值选择**: Automatically determined K-values are for reference only; adjust based on biological significance
3. **Dimensionality Limitation / 维度限制**: Currently uses only two phenotypic traits; multidimensional expansion requires code modification

## Version Information / 版本信息

- **Current Version / 当前版本**: Final Perfect Version
- **Update Date / 更新日期**: 2024
- **Major Updates / 主要更新**: Fixed variable scope issues, enhanced data compatibility
- **Compatibility / 兼容性**: R ≥ 4.0.0, RStudio ≥ 1.4.0

## Extended Applications / 扩展应用

### Custom Modifications / 自定义修改
```r
# Modify clustering method / 修改聚类方法
hc <- hclust(dist_mat, method = "complete")  # Change to complete linkage

# Adjust color scheme / 调整颜色方案
cols <- brewer.pal(n = 8, name = "Set2")  # Use different palette

# Modify output dimensions / 修改输出尺寸
pdf(file.path(folder_name, "Custom_Tree.pdf"), width = 10, height = 6)
```

### Multi-trait Extension / 多性状扩展
To add more traits for analysis, modify the following sections:
```r
# Add new traits in the data cleaning section
# Include new variables in the matrix preparation section
mat <- as.matrix(summarized_df[, c("Avg_Height", "Avg_Internode", "New_Trait")])
```

## Citation Suggestions / 引用建议

If using this script for analysis, please acknowledge in your research:
- Used hierarchical clustering based on Euclidean distance
- Employed Ward.D2 clustering algorithm
- Utilized the R dendextend package for visualization

---

*Note: This script is a research tool. Interpretation of results requires biological context knowledge. Recommended to use under guidance of professional statisticians.*  
*注意：本脚本为科研工具，结果解释需结合生物学背景知识。建议在专业统计人员指导下使用。*
