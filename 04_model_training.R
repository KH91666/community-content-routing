evaluate_predictions <- function(actual, predicted, model_name) {
  results <- tibble::tibble(category = actual, pred_category = factor(predicted, levels = levels(actual)))
  list(
    model = model_name,
    accuracy = mean(results$category == results$pred_category),
    confusion = as.data.frame.matrix(table(Actual = results$category, Predicted = results$pred_category)),
    category_accuracy = results |> dplyr::group_by(category) |>
      dplyr::summarise(accuracy = mean(pred_category == category), .groups = "drop") |>
      dplyr::mutate(model = model_name)
  )
}

train_models <- function(train, test, text_matrices) {
  baseline <- nnet::multinom(
    category ~ score + log_view_count + log_answer_count + title_word_count + text_word_count,
    data = train, trace = FALSE
  )
  baseline_eval <- evaluate_predictions(test$category, predict(baseline, newdata = test), "Metadata")

  set.seed(3002)
  text_cv <- glmnet::cv.glmnet(
    text_matrices$train, text_matrices$y_train, family = "multinomial", type.multinomial = "group",
    type.measure = "class", nfolds = 3, nlambda = 30
  )
  text_pred <- predict(text_cv, newx = text_matrices$test, s = "lambda.min", type = "class")[, 1]
  text_eval <- evaluate_predictions(text_matrices$y_test, text_pred, "Text")

  fields <- c("score", "log_view_count", "log_answer_count", "title_word_count", "text_word_count")
  train_meta <- Matrix::Matrix(as.matrix(train |> dplyr::arrange(row_id) |> dplyr::select(dplyr::all_of(fields))), sparse = TRUE)
  test_meta <- Matrix::Matrix(as.matrix(test |> dplyr::arrange(row_id) |> dplyr::select(dplyr::all_of(fields))), sparse = TRUE)
  set.seed(3002)
  combined_cv <- glmnet::cv.glmnet(
    cbind(train_meta, text_matrices$train), text_matrices$y_train,
    family = "multinomial", type.multinomial = "group", type.measure = "class", nfolds = 3, nlambda = 30
  )
  combined_pred <- predict(combined_cv, newx = cbind(test_meta, text_matrices$test), s = "lambda.min", type = "class")[, 1]
  combined_eval <- evaluate_predictions(text_matrices$y_test, combined_pred, "Text + metadata")

  list(
    evaluations = list(baseline_eval, text_eval, combined_eval),
    text_lambda_min = text_cv$lambda.min, text_lambda_1se = text_cv$lambda.1se,
    combined_lambda_min = combined_cv$lambda.min, combined_lambda_1se = combined_cv$lambda.1se
  )
}
