context("auk_unique")

test_that("auk_unique removes duplicates", {
  ebd <- system.file("extdata/zerofill-ex_ebd.txt", package = "auk") %>%
    read_ebd(unique = FALSE)
  ebd_unique <- auk_unique(ebd)

  ebd_g <- ebd[!is.na(ebd$group_identifier), ]
  ebd_unique_g <- ebd_unique[!is.na(ebd_unique$group_identifier), ]

  unique_cols <- c("scientific_name", "group_identifier")

  expect_lt(nrow(ebd_unique), nrow(ebd))
  expect_equal(ncol(ebd_unique), ncol(ebd) + 1)
  expect_true(!"checklist_id" %in% names(ebd))
  expect_true("checklist_id" %in% names(ebd_unique))
  expect_gt(anyDuplicated(ebd_g[, unique_cols]), 0)
  expect_equal(anyDuplicated(ebd_unique_g[, unique_cols]), 0)
})

# test_that("auk_unique removes duplicates on sampling", {
#   ebd <- system.file("extdata/zerofill-ex_sampling.txt", package = "auk") %>%
#     read_sampling(unique = FALSE)
#   ebd_unique <- auk_unique(ebd, checklists_only = TRUE)
#
#   ebd_g <- ebd[!is.na(ebd$group_identifier), ]
#   ebd_unique_g <- ebd_unique[!is.na(ebd_unique$group_identifier), ]
#
#   unique_cols <- "group_identifier"
#
#   expect_lt(nrow(ebd_unique), nrow(ebd))
#   expect_equal(ncol(ebd_unique), ncol(ebd) + 1)
#   expect_true(!"checklist_id" %in% names(ebd))
#   expect_true("checklist_id" %in% names(ebd_unique))
#   expect_gt(anyDuplicated(ebd_g[, unique_cols]), 0)
#   expect_equal(anyDuplicated(ebd_unique_g[, unique_cols]), 0)
# })

