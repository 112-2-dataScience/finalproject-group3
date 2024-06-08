library(jpeg)
library(grDevices)

# Define a function to calculate HSV from RGB
rgb_to_hsv <- function(r, g, b) {
  V <- pmax(r, g, b)
  delta <- V - pmin(r, g, b)
  S <- ifelse(V != 0, delta/V, 0)
  H <- ifelse(S == 0, 0,
              ifelse(V == r, 60 * (g - b) / delta,
                     ifelse(V == g, 120 + 60 * (b - r) / delta,
                            240 + 60 * (r - g) / delta)))
  H <- H %% 360
  H[H < 0] <- H[H < 0] + 360
  return(list(H = H, S = S, V = V))
}

# 設定資料夾路徑
folder_paths <- c("training_set/drawings_jpeg", "training_set/engraving_jpeg",
                  "training_set/iconography_jpeg", "training_set/sculpture_jpeg")

# 創建一個空的資料框來存儲RGB平均值和HSV平均值
rgb_hsv_means <- data.frame()

# 遍歷每個資料夾
for (folder in folder_paths) {
  # 取得資料夾中所有JPEG圖像的檔案路徑
  image_files <- list.files(path = folder, pattern = ".jpeg", full.names = TRUE)
  
  # 創建空的向量來存儲所有圖像的RGB值和HSV值
  all_red <- c()
  all_green <- c()
  all_blue <- c()
  all_hue <- c()
  all_saturation <- c()
  all_value <- c()
  
  # 遍歷每個圖像
  for (image_file in image_files) {
    # 讀取圖像
    img <- readJPEG(image_file)
    
    # 提取RGB通道的數值
    red_channel <- img[,,1]
    green_channel <- img[,,2]
    blue_channel <- img[,,3]
    
    # 將RGB值添加到向量中
    all_red <- c(all_red, red_channel)
    all_green <- c(all_green, green_channel)
    all_blue <- c(all_blue, blue_channel)
    
    # 轉換成HSV
    hsv_values <- rgb_to_hsv(red_channel, green_channel, blue_channel)
    
    # 提取HSV通道的數值
    hue_channel <- hsv_values$H
    saturation_channel <- hsv_values$S
    value_channel <- hsv_values$V
    
    # 將HSV值添加到向量中
    all_hue <- c(all_hue, hue_channel)
    all_saturation <- c(all_saturation, saturation_channel)
    all_value <- c(all_value, value_channel)
  }
  
  # 計算平均值
  avg_red <- mean(all_red)
  avg_green <- mean(all_green)
  avg_blue <- mean(all_blue)
  avg_hue <- mean(all_hue)
  avg_saturation <- mean(all_saturation)
  avg_value <- mean(all_value)
  
  # 計算變異數
  var_red <- var(all_red)
  var_green <- var(all_green)
  var_blue <- var(all_blue)
  var_hue <- var(all_hue)
  var_saturation <- var(all_saturation)
  var_value <- var(all_value)
  
  # 將平均值和變異數添加到資料框中
  rgb_hsv_means <- rbind(rgb_hsv_means, c(avg_red, avg_green, avg_blue, avg_hue,
                                          avg_saturation, avg_value, var_red,
                                          var_green, var_blue, var_hue,
                                          var_saturation, var_value))}

# 添加行名稱
rownames(rgb_hsv_means) <- folder_paths
colnames(rgb_hsv_means) <- c("Average Red", "Average Green", "Average Blue",
                             "Average Hue", "Average Saturation", "Average Value",
                             "Variance Red", "Variance Green", "Variance Blue",
                             "Variance Hue", "Variance Saturation", "Variance Value")

# 輸出結果
print(rgb_hsv_means)


# Plotting histograms
par(mfrow=c(2, 3), mar=c(4, 4, 2, 1))  # Set layout and margins

# Histograms for RGB
barplot(t(rgb_hsv_means[, 1:3]), beside = TRUE, col = c("#CE0000", "#9ACD32", "#4682B4"),
        main = "RGB", ylab = "Average Value", names.arg = c("draw", "engr", "icon", "scul"), las = 1)

# Histogram for Hue
barplot(rgb_hsv_means[,"Average Hue"], col = "#FFAF60", main = "Hue",
        ylab = "Average Value", names.arg = c("draw", "engr", "icon", "scul"), las = 1)

# Histograms for Saturation and Value
barplot(t(rgb_hsv_means[, 5:6]), beside = TRUE, col = c("#00FFFF", "#EE82EE"),
        main = "Sat and Val", ylab = "Average Value", names.arg = c("draw", "engr", "icon", "scul"), las = 1)
                                                                          
barplot(t(rgb_hsv_means[, 7:9]), beside = TRUE, col = c("#CE0000", "#9ACD32", "#4682B4"),
        main = "Variance of RGB", ylab = "Average Variance", names.arg = c("draw", "engr", "icon", "scul"), las = 1)

barplot(rgb_hsv_means[,"Variance Hue"], col = "#FFAF60", main = "Variance of Hue",
        ylab = "Average Variance", names.arg = c("draw", "engr", "icon", "scul"), las = 1)

barplot(t(rgb_hsv_means[, 11:12]), beside = TRUE, col = c("#00FFFF", "#EE82EE"),
        main = "Variance of Sat and Val", ylab = "Average Variance", names.arg = c("draw", "engr", "icon", "scul"), las = 1)
