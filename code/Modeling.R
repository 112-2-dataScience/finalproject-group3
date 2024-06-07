# 加载所需的包
library(caret)
library(gbm)
library(pROC)

train_shape_stan <- read.csv("train_shape_standardized.csv")
train_structure <- read.csv("train_structure.csv")
train_texture <- read.csv('train_texture.csv')
train_rgb <- read.csv('train_mean_var_diff.csv')

train_shape_stan <- train_shape_stan[,1:(ncol(train_shape_stan)-1)]
train_structure <- train_structure[,1:(ncol(train_structure)-1)]
train_texture <- train_texture[,1:(ncol(train_texture)-2)]

train_data <- cbind(train_structure,train_texture,train_rgb)

test_shape_stan <- read.csv("test_shape_standardized.csv")
test_structure <- read.csv("test_structure.csv")
test_texture <- read.csv('test_texture.csv')
test_rgb <- read.csv('test_mean_var_diff.csv')

test_shape_stan <- test_shape_stan[,1:(ncol(test_shape_stan)-1)]
test_structure <- test_structure[,1:(ncol(test_structure)-1)]
test_texture <- test_texture[,1:(ncol(test_texture)-2)]

test_data <- cbind(test_structure,test_texture,test_rgb)

# 加入标签
train_data$label <- as.factor(train_data$label)
test_data$label <- as.factor(test_data$label)


# 定义控制参数
control <- trainControl(method = "repeatedcv", number = 10, repeats = 3)

# 设置最佳参数的网格
tuneGrid <- expand.grid(
  n.trees = 150,
  interaction.depth = 4,
  shrinkage = 0.1,
  n.minobsinnode = 10
)

# 训练GBM模型
set.seed(7)
gbmModel <- train(label ~ ., data = train_data, method = "gbm", metric = "Accuracy", tuneGrid = tuneGrid, trControl = control, verbose = FALSE)

# 输出模型信息
print(gbmModel)

svm_model <- svm(label ~ ., data = train_data, kernel = "radial", cost = 4, gamma = 0.2, probability = TRUE)
print(svm_model)

rfModel <- randomForest(x = train_data[,1:ncol(train_data)-1], y = train_data$label,
                        ntree = 500,        # 树的数量
                        mtry = 11,          # 每次分割尝试的变量数
                        importance = TRUE)  # 计算变量重要性

# 使用测试集进行预测
predictions_rfm <- predict(rfModel, newdata = test_data[, 1:(ncol(test_data) - 1)])

# 计算混淆矩阵
confMatrix_rfm <- confusionMatrix(predictions_rfm, test_data$label)

# 输出混淆矩阵
print(confMatrix_rfm)


# 使用测试集进行预测
predictions_gbm <- predict(gbmModel, newdata = test_data[, 1:(ncol(test_data) - 1)])

# 计算混淆矩阵
confMatrix_gbm <- confusionMatrix(predictions_gbm, test_data$label)

# 输出混淆矩阵
print(confMatrix_gbm)


# 使用测试集进行预测
predictions_svm <- predict(svm_model, newdata = test_data[, 1:(ncol(test_data) - 1)])

# 计算混淆矩阵
confMatrix_svm <- confusionMatrix(predictions_svm, test_data$label)

# 输出混淆矩阵
print(confMatrix_svm)

predictions_gbm <- predict(gbmModel, newdata = test_data[, 1:(ncol(test_data) - 1)], type = "prob")
predictions_svm <- predict(svm_model, newdata = test_data[, 1:(ncol(test_data) - 1)], probability = TRUE)
predictions_rf <- predict(rfModel, newdata = test_data[, 1:(ncol(test_data) - 1)], type = "prob")

# 将标签转换为二元指标矩阵
y_true <- model.matrix(~ test_data$label - 1)

# 确保概率值在 (0, 1) 之间
epsilon <- 1e-15
prob_gbm <- pmax(pmin(predictions_gbm, 1 - epsilon), epsilon)
prob_svm <- attr(predictions_svm, "probabilities")
prob_svm <- pmax(pmin(prob_svm, 1 - epsilon), epsilon)
prob_rf <- pmax(pmin(predictions_rf, 1 - epsilon), epsilon)

# 计算对数似然值
log_likelihood_gbm <- sum(y_true * log(prob_gbm))
log_likelihood_svm <- sum(y_true * log(prob_svm))
log_likelihood_rf <- sum(y_true * log(prob_rf))

cat(" Log Likelihood for SVM: ", log_likelihood_svm, "\n",
    "Log Likelihood for GBM: ", log_likelihood_gbm, "\n",
    "Log Likelihood for Random Forest: ", log_likelihood_rf, "\n")

