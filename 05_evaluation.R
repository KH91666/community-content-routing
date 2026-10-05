write_evaluation <- function(model_results, output_dir, figure_dir) {
  evaluations <- model_results$evaluations
  comparison <- purrr::map_dfr(evaluations, ~ tibble::tibble(model = .x$model, test_accuracy = .x$accuracy))
  category_comparison <- purrr::map_dfr(evaluations, "category_accuracy")
  readr::write_csv(comparison, file.path(output_dir, "model_comparison.csv"))
  readr::write_csv(category_comparison, file.path(output_dir, "category_accuracy.csv"))
  for (evaluation in evaluations) {
    table <- tibble::rownames_to_column(evaluation$confusion, "actual")
    filename <- paste0("confusion_", stringr::str_replace_all(tolower(evaluation$model), "[^a-z]+", "_"), ".csv")
    readr::write_csv(table, file.path(output_dir, filename))
  }
  lambdas <- tibble::tibble(
    model = c("Text", "Text", "Text + metadata", "Text + metadata"),
    selection = c("lambda.min", "lambda.1se", "lambda.min", "lambda.1se"),
    value = c(model_results$text_lambda_min, model_results$text_lambda_1se,
              model_results$combined_lambda_min, model_results$combined_lambda_1se)
  )
  readr::write_csv(lambdas, file.path(output_dir, "selected_lambdas.csv"))

  plot <- ggplot2::ggplot(category_comparison, ggplot2::aes(category, accuracy, fill = model)) +
    ggplot2::geom_col(position = "dodge") + ggplot2::scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    ggplot2::labs(title = "Per-Category Accuracy by Model", x = NULL, y = "Accuracy", fill = "Model") +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 20, hjust = 1), legend.position = "top")
  ggplot2::ggsave(file.path(figure_dir, "06_model_category_accuracy.png"), plot, width = 10, height = 6, dpi = 180)
}
