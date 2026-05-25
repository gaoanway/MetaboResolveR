test_that("local real-case chunks annotate without errors when present", {
  candidate_roots <- c(
    getwd(),
    normalizePath(file.path(getwd(), ".."), winslash = "/", mustWork = FALSE),
    normalizePath(file.path(getwd(), "..", ".."), winslash = "/", mustWork = FALSE)
  )
  chunk_dirs <- file.path(candidate_roots, "data-raw", "real_case", "chunks")
  existing_dirs <- chunk_dirs[dir.exists(chunk_dirs)]
  testthat::skip_if(length(existing_dirs) == 0, "Local real-case chunks are not present.")
  chunk_dir <- existing_dirs[[1]]

  chunk_files <- sort(list.files(chunk_dir, pattern = "^chunk_[0-9]{2}[.]csv$", full.names = TRUE))
  testthat::skip_if(length(chunk_files) == 0, "Local real-case chunks are not present.")

  expect_equal(length(chunk_files), 10)

  for (chunk_file in chunk_files) {
    input <- utils::read.csv(
      chunk_file,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = c("", "NA", "N/A", "NaN", "NULL")
    )
    annotated <- annotate_plasma_metabolites(input)
    expect_equal(nrow(annotated), nrow(input))
    expect_true(all(!is.na(annotated$final_annotation_class)))
  }
})
