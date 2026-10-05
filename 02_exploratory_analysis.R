run_exploration <- function(questions, output_dir, figure_dir) {
  overall <- questions |> dplyr::summarise(
    category = "Overall", n_questions = dplyr::n(), mean_score = mean(score), median_score = median(score),
    mean_view_count = mean(view_count), median_view_count = median(view_count),
    mean_answer_count = mean(answer_count), median_answer_count = median(answer_count)
  )
  by_category <- questions |> dplyr::group_by(category) |> dplyr::summarise(
    n_questions = dplyr::n(), mean_score = mean(score), median_score = median(score),
    mean_view_count = mean(view_count), median_view_count = median(view_count),
    mean_answer_count = mean(answer_count), median_answer_count = median(answer_count),
    mean_title_word_count = mean(title_word_count), median_title_word_count = median(title_word_count),
    mean_text_word_count = mean(text_word_count), median_text_word_count = median(text_word_count),
    mean_log_view_count = mean(log_view_count), median_log_view_count = median(log_view_count),
    mean_log_answer_count = mean(log_answer_count), median_log_answer_count = median(log_answer_count), .groups = "drop"
  )
  readr::write_csv(overall, file.path(output_dir, "overall_summary.csv"))
  readr::write_csv(by_category, file.path(output_dir, "category_summary.csv"))

  plot_specs <- list(
    list("score", "Score by Category", "Score", "01_score_by_category.png"),
    list("log_view_count", "Log(View Count + 1) by Category", "log(View Count + 1)", "02_log_views_by_category.png"),
    list("log_answer_count", "Log(Answer Count + 1) by Category", "log(Answer Count + 1)", "03_log_answers_by_category.png"),
    list("text_word_count", "Text Word Count by Category", "Text Word Count", "04_text_length_by_category.png")
  )
  for (spec in plot_specs) {
    plot <- ggplot2::ggplot(questions, ggplot2::aes(x = category, y = .data[[spec[[1]]]], fill = category)) +
      ggplot2::geom_boxplot(show.legend = FALSE, outlier.alpha = 0.12) + ggplot2::labs(title = spec[[2]], x = NULL, y = spec[[3]]) +
      ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 20, hjust = 1))
    ggplot2::ggsave(file.path(figure_dir, spec[[4]]), plot, width = 9, height = 5.5, dpi = 180)
  }

  tokens <- questions |> dplyr::select(row_id, category, full_text) |>
    tidytext::unnest_tokens(word, full_text) |> dplyr::anti_join(tidytext::stop_words, by = "word") |>
    dplyr::filter(stringr::str_detect(word, "^[a-z]+$"), nchar(word) >= 3)
  top <- tokens |> dplyr::count(category, word, sort = TRUE) |> tidytext::bind_tf_idf(word, category, n) |>
    dplyr::group_by(category) |> dplyr::slice_max(tf_idf, n = 10, with_ties = FALSE) |> dplyr::ungroup()
  readr::write_csv(top, file.path(output_dir, "top_tfidf_words.csv"))
  top_plot <- top |> dplyr::mutate(word = tidytext::reorder_within(word, tf_idf, category)) |>
    ggplot2::ggplot(ggplot2::aes(word, tf_idf, fill = category)) + ggplot2::geom_col(show.legend = FALSE) +
    tidytext::scale_x_reordered() + ggplot2::coord_flip() + ggplot2::facet_wrap(~ category, scales = "free") +
    ggplot2::labs(title = "Top 10 TF-IDF Words by Category", x = NULL, y = "TF-IDF") + ggplot2::theme_minimal(base_size = 10)
  ggplot2::ggsave(file.path(figure_dir, "05_top_tfidf_words.png"), top_plot, width = 11, height = 8, dpi = 180)
}
