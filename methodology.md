# Methodology

The four balanced question classes are combined and enriched with word counts and log-transformed view and answer counts. A stratified 80/20 split uses seed 3002, yielding 6,400 training and 1,600 test records.

The baseline multinomial regression uses only score, engagement counts, and text lengths. Text models tokenise training and test records separately, remove stop words, keep alphabetic tokens of at least three characters, and build a maximum 3,000-term vocabulary from training records with frequency at least ten. The test matrix can use only this learned vocabulary.

`align_sparse_matrix()` adds absent document rows and vocabulary columns as zeros, then enforces the exact row and column order. This prevents predictions from being compared with the wrong labels, a practical failure mode discovered during the historical project.

Grouped multinomial LASSO uses three-fold cross-validation, 30 lambda values, classification error, and `lambda.min`. Text and metadata are combined only after row alignment.

User-level information is deliberately excluded. The classifier uses question content and question-level attributes, limiting privacy, re-identification, profiling, and selection-bias risks. Because the data contain community labels rather than verified moderation errors, the output is decision support, not automated moderation.
