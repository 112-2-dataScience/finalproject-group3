library(randomForest)
library(readbitmap)
library(e1071)
library(jpeg)
library(ROCR)

compute_diff <- function(img) {
  diff_r <- abs(diff(img[,,1]))
  diff_g <- abs(diff(img[,,2]))
  diff_b <- abs(diff(img[,,3]))
  c(mean(diff_r), mean(diff_g), mean(diff_b))
}

folder_paths <- c("training_set/drawings_jpeg", "training_set/engraving_jpeg",
                  "training_set/iconography_jpeg", "training_set/sculpture_jpeg")

train_data <- matrix(nrow = 1000, ncol = 10)
i <- 1

for (label in folder_paths) {
  image_files <- list.files(path = label, pattern = ".jpeg", full.names = TRUE)
  for (image_file in image_files) {
    img <- readJPEG(image_file)
    
    train_data[i, 1:3] <- compute_diff(img) 
    train_data[i, 4:6] <- c(mean(img[,,1]), mean(img[,,2]), mean(img[,,3]))
    train_data[i, 7:9] <- c(var(c(img[,,1])), var(c(img[,,2])), var(c(img[,,3])))
    train_data[i, 10] <- label
    i = i + 1
  }
}

folder_paths <- c("validation_set/drawings_jpeg", "validation_set/engraving_jpeg",
                  "validation_set/iconography_jpeg", "validation_set/sculpture_jpeg")

test_data <- matrix(nrow = 200, ncol = 10) 
i <- 1

for (label in folder_paths) {
  image_files <- list.files(path = label, pattern = ".jpeg", full.names = TRUE)
  for (image_file in image_files) {
    img <- readJPEG(image_file)
    
    test_data[i, 1:3] <- compute_diff(img) 
    test_data[i, 4:6] <- c(mean(img[,,1]), mean(img[,,2]), mean(img[,,3])) 
    test_data[i, 7:9] <- c(var(c(img[,,1])), var(c(img[,,2])), var(c(img[,,3])))
    test_data[i, 10] <- label
    i = i + 1
  }
}

train_data <- data.frame(train_data)
train_x <- train_data[, 1:9] 
train_x$X1 <- as.numeric(train_x$X1)
train_x$X2 <- as.numeric(train_x$X2)
train_x$X3 <- as.numeric(train_x$X3)
train_x$X4 <- as.numeric(train_x$X4)
train_x$X5 <- as.numeric(train_x$X5)
train_x$X6 <- as.numeric(train_x$X6)
train_x$X7 <- as.numeric(train_x$X7)
train_x$X8 <- as.numeric(train_x$X8)
train_x$X9 <- as.numeric(train_x$X9)
train_y <- as.factor(train_data$X10)

test_data <- data.frame(test_data)
test_x <- test_data[, 1:9] 
test_x$X1 <- as.numeric(test_x$X1)
test_x$X2 <- as.numeric(test_x$X2)
test_x$X3 <- as.numeric(test_x$X3)
test_x$X4 <- as.numeric(test_x$X4)
test_x$X5 <- as.numeric(test_x$X5)
test_x$X6 <- as.numeric(test_x$X6)
test_x$X7 <- as.numeric(test_x$X7)
test_x$X8 <- as.numeric(test_x$X8)
test_x$X9 <- as.numeric(test_x$X9)
test_y <- as.factor(test_data$X10)

svm_model <- svm(train_y ~ ., data = train_x, kernel = "radial")

y_pred <- predict(svm_model, test_x)

y_pred <- sub("training_set/", "", y_pred)
test_y <- sub("validation_set/", "", test_y)

y_pred <- sub("_jpeg", "", y_pred)
test_y <- sub("_jpeg", "", test_y)

accuracy <- mean(y_pred == test_y)
print(paste("Accuracy:", accuracy))

conf_matrix <- table(test_y, y_pred)
print("Confusion Matrix:")
print(conf_matrix)

library(gplots)

# 定义颜色映射
colorPalette <- colorRampPalette(c("white", "#4682B4"))(100)

# 绘制渐变色热图
heatmap.2(conf_matrix, 
          trace = "none",          
          col = colorPalette,      
          dendrogram = "none",     # 不显示谱系图
          main = "Confusion Matrix",  # 标题
          xlab = "Predicted",      
          ylab = "Actual",         
          margins = c(5, 10),      # 调整边距
          cellnote = conf_matrix,  # 在单元格中显示数字
          notecol = "black",       # 数字颜色
          density.info = "none",   # 不显示密度图例
          key = TRUE,              # 显示颜色条
          keysize = 1.5,
          cexRow = 0.8,            # 调整行标签大小
          cexCol = 0.8,
          cex.axis = 0.9,
          key.title = NA)          # 隐藏颜色条标题


y_pred <- predict(svm_model, train_x)

y_pred <- sub("training_set/", "", y_pred)
train_y <- sub("training_set/", "", train_y)

y_pred <- sub("_jpeg", "", y_pred)
train_y <- sub("_jpeg", "", train_y)

accuracy <- mean(y_pred == train_y)
print(paste("Accuracy:", accuracy))

conf_matrix <- table(train_y, y_pred)
print("Confusion Matrix:")
print(conf_matrix)

library(gplots)

# 定义颜色映射
colorPalette <- colorRampPalette(c("white", "#4682B4"))(100)

conf_matrix <- conf_matrix[, rev(colnames(conf_matrix))]
conf_matrix <- conf_matrix[rev(rownames(conf_matrix)), ]


heatmap.2(conf_matrix, 
          trace = "none",          
          col = colorPalette,      
          dendrogram = "none",     
          main = "Confusion Matrix",  
          xlab = "Predicted",      
          ylab = "Actual",         
          margins = c(5, 10),      
          cellnote = conf_matrix,  
          notecol = "black",       
          density.info = "none",  
          key = TRUE,             
          keysize = 1.5,
          cexRow = 0.8,            
          cexCol = 0.8,
          cex.axis = 0.9,
          key.title = NA)          
