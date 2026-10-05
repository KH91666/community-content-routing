suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(tidytext)
  library(nnet)
  library(glmnet)
  library(Matrix)
})

args <- commandArgs(trailingOnly = FALSE)
script_arg <- args[grepl("^--file=", args)]
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else "R/run_all.R"
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
setwd(root)

for (file in c("01_data_preparation.R", "02_exploratory_analysis.R", "03_text_features.R", "04_model_training.R", "05_evaluation.R")) {
  source(file.path(root, "R", file))
}

data_dir <- Sys.getenv("COMMUNITY_DATA_DIR", file.path(root, "data"))
output_dir <- file.path(root, "outputs")
figure_dir <- file.path(root, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

questions <- load_and_prepare(data_dir)
run_exploration(questions, output_dir, figure_dir)
split <- stratified_split(questions)
text_matrices <- build_text_matrices(split$train, split$test)
models <- train_models(split$train, split$test, text_matrices)
write_evaluation(models, output_dir, figure_dir)

cat("Rows:", nrow(questions), "\n")
cat("Train/test:", nrow(split$train), "/", nrow(split$test), "\n")
print(readr::read_csv(file.path(output_dir, "model_comparison.csv"), show_col_types = FALSE))
