context("test-utils")

adsl <- dplyr::filter(random.cdisc.data::cadsl, SEX == "M")
adae <- random.cdisc.data::cadae

test_that("`semi_join` keeps only records in `x` that have matching records in `y`", {
  expect_error(semi_join(adae, adsl, by = c("STUDYID", "USUBJID")), NA)
  expect_equal(
    semi_join(adae, adsl, by = c("STUDYID", "USUBJID")),
    dplyr::semi_join(adae, adsl, by = c("STUDYID", "USUBJID"))
  )
})

test_that("`semi_join` preserves column labels", {
  expect_equal(
    get_labels(semi_join(adae, adsl, by = c("STUDYID", "USUBJID"))),
    get_labels(dplyr::semi_join(adae, adsl, by = c("STUDYID", "USUBJID")))
  )
})
