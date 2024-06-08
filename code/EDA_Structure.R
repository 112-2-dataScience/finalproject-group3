library(imager)
# 定義函數計算圖像的結構特徵
compute_structure_features <- function(image_path) {
  
  img <- load.image(image_path)
  # 分層結構特徵（色彩分佈總和）
  layers <- sum(colMeans(colSums(as.array(img))))
  
  # 圖像轉換為灰度
  gray_img <- grayscale(img)
  # 圖像的水平投影
  horizontal_profile <- colMeans(as.matrix(gray_img))
  # 圖像的對稱性
  symmetry <- sum(abs(horizontal_profile - rev(horizontal_profile))) / length(horizontal_profile)
  
  # 灰階影像的協方差矩陣
  cov_matrix <- cov(as.matrix(gray_img))
  # 協方差矩陣的特徵值和特徵向量
  eigenvalues <- eigen(cov_matrix)$values
  eigenvectors <- eigen(cov_matrix)$vectors
  # 提取主特徵向量（對應最大特徵值）
  main_eigenvector <- eigenvectors[, which.max(eigenvalues)]
  # 主特徵向量與水平方向的夾角（對齊度）
  alignment <- abs(atan(main_eigenvector[2] / main_eigenvector[1]))
  
  return(c(layers, symmetry, alignment))
}

# 訓練集
training_paths <- list.files("final_jpeg_data/train/", recursive = TRUE, full.names = TRUE)
training_structure_features <- t(sapply(training_paths, compute_structure_features))

# 驗證集 (測試集)
validation_paths <- list.files("final_jpeg_data/test/", recursive = TRUE, full.names = TRUE)
validation_structure_features <- t(sapply(validation_paths, compute_structure_features))

# 結果轉換為數據框
training_df <- data.frame(training_structure_features)
names(training_df) <- c("layers", "symmetry", "alignment")
training_df$label <- gsub("final_jpeg_data/train/", "", dirname(training_paths))

validation_df <- data.frame(validation_structure_features)
names(validation_df) <- c("layers", "symmetry", "alignment")
validation_df$label <- gsub("final_jpeg_data/test/", "", dirname(validation_paths))

# 缺失值替換為平均值
numeric_cols <- sapply(training_df, is.numeric)
for (col in names(training_df)[numeric_cols]) {
  training_df[is.na(training_df[, col]), col] <- mean(training_df[, col], na.rm = TRUE)
}
for (col in names(validation_df)[numeric_cols]) {
  validation_df[is.na(validation_df[, col]), col] <- mean(validation_df[, col], na.rm = TRUE)
}

# 數值正規化[0,1](Normalization)/標準化(Standardization)
for (col in names(training_df)[numeric_cols]) {
  training_df[, col] <- scale(training_df[, col], center = FALSE, scale = max(abs(training_df[, col]))) # Normalization
  # training_df[, col] <- scale(training_df[, col], center = TRUE, scale = TRUE) # Standardization
}
for (col in names(validation_df)[numeric_cols]) {
  validation_df[, col] <- scale(validation_df[, col], center = FALSE, scale = max(abs(validation_df[, col]))) # Normalization
  # validation_df[, col] <- scale(validation_df[, col], center = TRUE, scale = TRUE) # Standardization
}

# 保存到CSV文件
write.csv(training_df, "train_structure.csv", row.names = FALSE)
write.csv(validation_df, "test_structure.csv", row.names = FALSE)

####################
library(ggplot2)
library(reshape2)

training_data <- read.csv("train_structure.csv")
numeric_data <- training_data[, c("layers", "symmetry", "alignment")]

# 使用reshape2套件的melt函數，指定id.vars參數
melted_data <- melt(numeric_data, id.vars = NULL)

# 繪製箱線圖
boxplot <- ggplot(melted_data, aes(x = variable, y = value, fill = variable)) +
  geom_boxplot(alpha = 0.5, outlier.shape = "*") +
  labs(title = "Boxplot of Structure Features",
       x = "Features",
       y = "Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(hjust = 1)) +
  scale_fill_manual(values = c("layers" = "#66a3ff", "symmetry" = "#ff1a66", "alignment" = "#4dff88")) +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position = "none")
print(boxplot)

#######################
library(ggplot2)
library(reshape2)

training_data <- read.csv("train_structure.csv")
features <- c("layers", "symmetry", "alignment")

# 根據特徵和類別劃分數據
melted_data <- melt(training_data, id.vars = "label")
# 篩選出包含指定特徵的數據
melted_data <- melted_data[melted_data$variable %in% features, ]

# 繪製箱線圖
boxplot <- ggplot(melted_data, aes(x = variable, y = value, fill = label)) +
  geom_boxplot(alpha = 0.5, outlier.shape =  "*") +
  labs(title = "Boxplot of Structure Features: 4 label",
       x = "Features",
       y = "Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(hjust = 1)) +
  scale_fill_manual(values = c("drawings" = "#7070db", 
                               "engraving" = "#ff704d", 
                               "iconography" = "#59b300",
                               "sculpture" = "#ff66a3")) +
  theme(plot.title = element_text(hjust = 0.5),
        legend.position = "bottom") +
  guides(fill = guide_legend(title = "Label"))
print(boxplot)

#####################

