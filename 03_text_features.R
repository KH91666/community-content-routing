tokenise_documents <- function(data) {
  data |> dplyr::select(row_id, full_text) |> tidytext::unnest_tokens(word, full_text) |>
    dplyr::anti_join(tidytext::stop_words, by = "word") |>
    dplyr::filter(stringr::str_detect(word, "^[a-z]+$"), nchar(word) >= 3)
}

align_sparse_matrix <- function(mat, target_rows, target_cols) {
  target_rows <- as.character(target_rows)
  target_cols <- as.character(target_cols)
  missing_rows <- setdiff(target_rows, rownames(mat))
  if (length(missing_rows)) {
    zero_rows <- Matrix::Matrix(0, nrow = length(missing_rows), ncol = ncol(mat), sparse = TRUE,
                                dimnames = list(missing_rows, colnames(mat)))
    mat <- rbind(mat, zero_rows)
  }
  missing_cols <- setdiff(target_cols, colnames(mat))
  if (length(missing_cols)) {
    zero_cols <- Matrix::Matrix(0, nrow = nrow(mat), ncol = length(missing_cols), sparse = TRUE,
                                dimnames = list(rownames(mat), missing_cols))
    mat <- cbind(mat, zero_cols)
  }
  mat[target_rows, target_cols, drop = FALSE]
}

build_text_matrices <- function(train, test) {
  train_tokens <- tokenise_documents(train)
  test_tokens <- tokenise_documents(test)
  vocabulary <- train_tokens |> dplyr::count(word, sort = TRUE) |> dplyr::filter(n >= 10) |> dplyr::slice_head(n = 3000)
  train_counts <- train_tokens |> dplyr::semi_join(vocabulary, by = "word") |> dplyr::count(row_id, word)
  test_counts <- test_tokens |> dplyr::semi_join(vocabulary, by = "word") |> dplyr::count(row_id, word)
  train_raw <- tidytext::cast_sparse(train_counts, row_id, word, n)
  test_raw <- tidytext::cast_sparse(test_counts, row_id, word, n)
  train_ids <- train |> dplyr::arrange(row_id) |> dplyr::pull(row_id)
  test_ids <- test |> dplyr::arrange(row_id) |> dplyr::pull(row_id)
  list(
    train = align_sparse_matrix(train_raw, train_ids, vocabulary$word),
    test = align_sparse_matrix(test_raw, test_ids, vocabulary$word),
    vocabulary = vocabulary,
    y_train = train |> dplyr::arrange(row_id) |> dplyr::pull(category),
    y_test = test |> dplyr::arrange(row_id) |> dplyr::pull(category)
  )
}
