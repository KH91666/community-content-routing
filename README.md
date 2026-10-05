# Local data placement

The underlying questions were obtained through Stack Exchange Data Explorer and distributed for a course project. The exact raw CSVs are not redistributed here.

Place four files locally:

```text
data/
├── english_language/questions.csv
├── english_learners/questions.csv
├── scifi/questions.csv
└── world_building/questions.csv
```

Each file contains 2,000 questions with `Id`, `Category`, `Title`, `Score`, `ViewCount`, `AnswerCount`, and `Text`, for 8,000 observations total. The supplied records contain question text longer than 600 characters. The pipeline also accepts a different root through `COMMUNITY_DATA_DIR`.
