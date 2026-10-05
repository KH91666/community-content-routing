load_and_prepare <- function(data_dir) {
  paths <- file.path(data_dir, c("english_language", "english_learners", "scifi", "world_building"), "questions.csv")
  missing_paths <- paths[!file.exists(paths)]
  if (length(missing_paths)) stop("Missing input files: ", paste(missing_paths, collapse = ", "))

  questions <- purrr::map_dfr(paths, ~ readr::read_csv(.x, show_col_types = FALSE) |> janitor::clean_names()) |>
    dplyr::mutate(
      category = factor(category),
      title_word_count = stringr::str_count(title, "\\S+"),
      text_word_count = stringr::str_count(text, "\\S+"),
      log_view_count = log1p(view_count),
      log_answer_count = log1p(answer_count),
      full_text = stringr::str_c(title, text, sep = " "),
      row_id = dplyr::row_number()
    )

  required <- c("id", "title", "score", "view_count", "answer_count", "category", "text")
  if (nrow(questions) != 8000) warning("Expected 8,000 rows; found ", nrow(questions))
  if (any(colSums(is.na(questions[required])) > 0)) warning("Missing values detected in required fields")
  questions
}

stratified_split <- function(questions) {
  set.seed(3002)
  train <- questions |> dplyr::group_by(category) |> dplyr::sample_frac(size = 0.8) |> dplyr::ungroup()
  test <- questions |> dplyr::anti_join(train |> dplyr::select(row_id), by = "row_id")
  list(train = train, test = test)
}
