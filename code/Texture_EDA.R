# 載入jpeg和ggplot2套件
library(jpeg)
library(ggplot2)
library(reshape2)

# 定義函數來計算灰度共生矩陣（GLCM）
calculate_glcm <- function(gray_img, d = 1, angle = 0) {
  nr <- nrow(gray_img)
  nc <- ncol(gray_img)
  glcm <- matrix(0, nrow = 256, ncol = 256)
  
  for (i in 1:(nr - d)) {
    for (j in 1:(nc - d)) {
      row <- gray_img[i, j]
      if (angle == 0) {
        col <- gray_img[i, j + d]
      } else if (angle == 90) {
        col <- gray_img[i + d, j]
      } else if (angle == 45) {
        col <- gray_img[i + d, j + d]
      } else if (angle == 135) {
        col <- gray_img[i + d, j - d]
      }
      if (!is.na(row) && !is.na(col) && row >= 0 && row < 256 && col >= 0 && col < 256) {
        glcm[row + 1, col + 1] <- glcm[row + 1, col + 1] + 1
      }
    }
  }
  return(glcm)
}

# 定義函數來計算對比度
calculate_contrast <- function(glcm) {
  contrast <- 0
  for (i in 1:nrow(glcm)) {
    for (j in 1:ncol(glcm)) {
      contrast <- contrast + ((i - j) ^ 2) * glcm[i, j]
    }
  }
  return(contrast)
}

# 定義函數來計算相異性
calculate_dissimilarity <- function(glcm) {
  dissimilarity <- 0
  for (i in 1:nrow(glcm)) {
    for (j in 1:ncol(glcm)) {
      dissimilarity <- dissimilarity + abs(i - j) * glcm[i, j]
    }
  }
  return(dissimilarity)
}

# 定義函數來計算同質性/逆差距
calculate_homogeneity <- function(glcm) {
  homogeneity <- 0
  for (i in 1:nrow(glcm)) {
    for (j in 1:ncol(glcm)) {
      homogeneity <- homogeneity + glcm[i, j] / (1 + abs(i - j))
    }
  }
  return(homogeneity)
}

# 定義函數來計算能量
calculate_energy <- function(glcm) {
  energy <- sum(glcm^2)
  return(energy)
}

# 定義函數來讀取並處理圖片
process_images <- function(folder, category) {
  image_files <- list.files(folder, pattern = ".jpeg", full.names = TRUE)
  cat(sprintf("Processing %d images in category %s...\n", length(image_files), category))
  
  contrast_values <- c()
  dissimilarity_values <- c()
  homogeneity_values <- c()
  energy_values <- c()
  
  for (file in image_files) {
    img <- readJPEG(file)
    gray_img <- 0.299 * img[,,1] + 0.587 * img[,,2] + 0.114 * img[,,3]
    gray_img <- round(gray_img * 255)
    
    glcm <- calculate_glcm(gray_img)
    contrast_values <- c(contrast_values, calculate_contrast(glcm))
    dissimilarity_values <- c(dissimilarity_values, calculate_dissimilarity(glcm))
    homogeneity_values <- c(homogeneity_values, calculate_homogeneity(glcm))
    energy_values <- c(energy_values, calculate_energy(glcm))
  }
  
  return(list(
    contrast = contrast_values, 
    dissimilarity = dissimilarity_values, 
    homogeneity = homogeneity_values, 
    energy = energy_values
  ))
}

# 定義正規化函數
normalize <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}

# 定義函數來處理資料，提取特徵並輸出CSV
process_data <- function(folder_paths, categories, output_file) {
  all_features <- list()
  
  for (i in seq_along(categories)) {
    result <- process_images(folder_paths[i], categories[i])
    all_features[[categories[i]]] <- result
  }
  
  # 合併所有特徵值到一個數據框中，並重新排列列的順序
  feature_df <- data.frame(
    Contrast = unlist(lapply(all_features, function(x) x$contrast)),
    Dissimilarity = unlist(lapply(all_features, function(x) x$dissimilarity)),
    Homogeneity = unlist(lapply(all_features, function(x) x$homogeneity)),
    Energy = unlist(lapply(all_features, function(x) x$energy)),
    Label = rep(categories, each = length(all_features[[1]]$contrast)) 
  )
  
  # 將特徵值進行正規化
  feature_df$Contrast <- normalize(feature_df$Contrast)
  feature_df$Dissimilarity <- normalize(feature_df$Dissimilarity)
  feature_df$Homogeneity <- normalize(feature_df$Homogeneity)
  feature_df$Energy <- normalize(feature_df$Energy)
  
  # 將數據保存為 CSV 文件
  write.csv(feature_df, file = output_file, row.names = FALSE)
}

train_folder_paths <- c("final_jpeg_data/train/drawings", "final_jpeg_data/train/engraving", "final_jpeg_data/train/iconography", "final_jpeg_data/train/sculpture")
train_categories <- c("drawings", "engraving", "iconography", "sculpture")
test_folder_paths <- c("final_jpeg_data/test/drawings", "final_jpeg_data/test/engraving", "final_jpeg_data/test/iconography", "final_jpeg_data/test/sculpture")
test_categories <- c("drawings", "engraving", "iconography", "sculpture")

train_output_file <- "train_data.csv"
test_output_file <- "test_data.csv"

process_data(train_folder_paths, train_categories, train_output_file)
process_data(test_folder_paths, test_categories, test_output_file)

train_feature_df <- read.csv(train_output_file)
test_feature_df <- read.csv(test_output_file)

melted_train_features <- melt(train_feature_df, id.vars = "Label")
melted_test_features <- melt(test_feature_df, id.vars = "Label")

# 繪製正規化後的數據盒狀圖
boxplot_train_energy <- ggplot(melted_train_features, aes
                               (x = variable, y = value, fill = Label)) +
  geom_boxplot(alpha = 0.5, outlier.shape = "*") +
  labs(title = "Boxplot of Texture Features: 4 label",
       x = "Features",
       y = "Value") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(hjust = 1),
    axis.title.x = element_text(face = "bold"), 
    axis.title.y = element_text(face = "bold"),
    plot.title = element_text(hjust = 0.5, face = "bold"), 
    legend.title = element_text(face = "bold"),
    legend.position = "bottom"
  ) +
  scale_fill_manual(values = c("drawings" = "#7070db",
                               "engraving" = "#ff704d",
                               "iconography" = "#59b300",
                               "sculpture" = "#ff66a3")) +
  guides(fill = guide_legend(title = "Label"))

print(boxplot_train_energy)
