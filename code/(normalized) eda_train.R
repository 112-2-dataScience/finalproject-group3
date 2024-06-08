library(imager)
library(ggplot2)

# 函數：計算凸多邊形的面積
polygon_area <- function(x, y) {
  if (length(x) < 3 || length(y) < 3) return(0)
  area <- 0
  for (i in 1:(length(x) - 1)) {
    area <- area + (x[i] * y[i + 1] - x[i + 1] * y[i])
  }
  area <- abs(area + (x[length(x)] * y[1] - x[1] * y[length(y)])) / 2
  return(area)
}

# 函數：計算方向
calculate_orientation <- function(region_pixels) {
  centered_pixels <- scale(region_pixels, center = TRUE, scale = FALSE)
  pca_result <- prcomp(centered_pixels)
  orientation <- atan2(pca_result$rotation[2, 1], pca_result$rotation[1, 1])
  return(orientation)
}

# 函數：計算環狀度
calculate_circularity <- function(region_pixels) {
  perimeter <- length(region_pixels)
  area <- nrow(region_pixels)
  circularity <- 4 * pi * area / (perimeter^2)
  return(circularity)
}

# 函數：從圖片中提取形狀特徵
extract_shape_features <- function(image_path) {
  img <- load.image(image_path)
  gray_img <- grayscale(img)
  edges <- cannyEdges(gray_img)
  components <- label(edges)
  
  # 初始化特徵變數
  total_area <- 0
  total_convex_hull_area <- 0
  centroid_x_sum <- 0
  centroid_y_sum <- 0
  orientation_sum <- 0
  circularity_sum <- 0
  num_components <- max(components)
  
  for (i in 1:num_components) {
    region_pixels <- which(components == i, arr.ind = TRUE)
    if (nrow(region_pixels) == 0) next
    
    area <- nrow(region_pixels)
    centroid_x <- mean(region_pixels[, 2])
    centroid_y <- mean(region_pixels[, 1])
    
    convex_hull <- chull(region_pixels[, 2], region_pixels[, 1])
    convex_hull_area <- polygon_area(region_pixels[convex_hull, 2], region_pixels[convex_hull, 1])
    
    orientation <- calculate_orientation(region_pixels)
    circularity <- calculate_circularity(region_pixels)
    
    total_area <- total_area + area
    total_convex_hull_area <- total_convex_hull_area + convex_hull_area
    centroid_x_sum <- centroid_x_sum + centroid_x
    centroid_y_sum <- centroid_y_sum + centroid_y
    orientation_sum <- orientation_sum + orientation
    circularity_sum <- circularity_sum + circularity
  }
  
  # 計算平均值
  if (num_components > 0) {
    centroid_x_avg <- centroid_x_sum / num_components
    centroid_y_avg <- centroid_y_sum / num_components
    orientation_avg <- orientation_sum / num_components
    circularity_avg <- circularity_sum / num_components
  } else {
    centroid_x_avg <- 0
    centroid_y_avg <- 0
    orientation_avg <- 0
    circularity_avg <- 0
  }
  
  shape_features <- data.frame(
    Area = total_area,
    Convex_Hull_Area = total_convex_hull_area,
    Centroid_X = centroid_x_avg,
    Centroid_Y = centroid_y_avg,
    Orientation = orientation_avg,
    Circularity = circularity_avg
  )
  
  return(shape_features)
}

folder_paths <- c("final_jpeg_data/train/drawings", "final_jpeg_data/train/engraving", "final_jpeg_data/train/iconography", "final_jpeg_data/train/sculpture")
shape_features <- data.frame()

for (folder_path in folder_paths) {
  label <- basename(folder_path)
  files <- list.files(folder_path, pattern = ".jpeg", full.names = TRUE)
  
  for (file in files) {
    shape_feature <- extract_shape_features(file)
    shape_features <- rbind(shape_features, cbind(shape_feature, Label = label))
  }
}

print(shape_features)

# 去掉最後一列（類別標籤）
feature_data <- shape_features[, -ncol(shape_features)]

# 檢查數據類型是否都是數值型
if (!all(sapply(feature_data, is.numeric))) {
  stop("所有特徵必須是數值型")
}

# 正規化數據
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}

normalized_features <- as.data.frame(lapply(feature_data, normalize))

# 檢查正規化後的數據範圍
print(apply(normalized_features, 2, range))

# 添加類別列
normalized_features$Label <- shape_features$Label

# 匯出正規化後的數據到CSV文件
write.csv(normalized_features, "(train) shape_features_normalized.csv", row.names = FALSE)

# 繪製正規化後的數據盒狀圖
ggplot(data = normalized_features, aes(x = Label, y = Area)) +
  geom_boxplot(fill = "blue") +
  labs(title = "Normalized Area Feature", x = "Label", y = "Area")

ggplot(data = normalized_features, aes(x = Label, y = Convex_Hull_Area)) +
  geom_boxplot(fill = "purple") +
  labs(title = "Normalized Convex Hull Area Feature", x = "Label", y = "Convex_Hull_Area")

ggplot(data = normalized_features, aes(x = Label, y = Centroid_X)) +
  geom_boxplot(fill = "green") +
  labs(title = "Normalized Centroid X Feature", x = "Label", y = "Centroid X")

ggplot(data = normalized_features, aes(x = Label, y = Centroid_Y)) +
  geom_boxplot(fill = "orange") +
  labs(title = "Normalized Centroid Y Feature", x = "Label", y = "Centroid Y")

ggplot(data = normalized_features, aes(x = Label, y = Orientation)) +
  geom_boxplot(fill = "red") +
  labs(title = "Normalized Orientation Feature", x = "Label", y = "Orientation")

ggplot(data = normalized_features, aes(x = Label, y = Circularity)) +
  geom_boxplot(fill = "yellow") +
  labs(title = "Normalized Circularity Feature", x = "Label", y = "Circularity")