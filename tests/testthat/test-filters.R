context("test-filters")

adsl <- random.cdisc.data::cadsl
attr(adsl$SEX, "label") <- NULL
adae <- random.cdisc.data::cadae
adae$AREL <- as.character(adae$AEREL)
adae$ATOXGR <- as.character(adae$AETOXGR)
adtte <- random.cdisc.data::cadtte
datasets <- list(
  adsl = adsl,
  adae = adae,
  adtte = adtte
)
filtered_datasets <- apply_filter(datasets, "SER_FEMALE_SE")

test_that("Filtering works as expected", {
  expect_equal(
    apply_filter(adsl, "SE"),
    dplyr::filter(adsl, SAFFL == "Y"),
    check.attributes = FALSE
  )
  expect_equal(
    apply_filter(adsl, "MALE_SE"),
    dplyr::filter(adsl, SEX == "M" & SAFFL == "Y"),
    check.attributes = FALSE
  )

  expect_equal(apply_filter(adae, "SE"), adae)
  expect_equal(
    apply_filter(adae, "REL"),
    dplyr::filter(adae, AREL == "Y"),
    check.attributes = FALSE
  )
  expect_equal(
    apply_filter(adae, "REL_SER"),
    dplyr::filter(adae, AREL == "Y", AESER == "Y"),
    check.attributes = FALSE
  )
  expect_equal(
    apply_filter(adae, "REL_SER_CTC35"),
    dplyr::filter(adae, AREL == "Y" & AESER == "Y" & ATOXGR %in% c("3", "4", "5")),
    check.attributes = FALSE
  )

  expect_equal(
    filtered_datasets$adsl,
    dplyr::filter(adsl, SEX == "F" & SAFFL == "Y"),
    check.attributes = FALSE
  )
  expect_equal(
    filtered_datasets$adae,
    adae %>%
      dplyr::filter(AESER == "Y") %>%
      dplyr::semi_join(filtered_datasets$adsl, by = c("STUDYID", "USUBJID")),
    check.attributes = FALSE
  )
  expect_equal(
    filtered_datasets$adtte,
    dplyr::semi_join(adtte, filtered_datasets$adsl, by = c("STUDYID", "USUBJID")),
    check.attributes = FALSE
  )
})

test_that("Using filters with multiple targets affects all listed datasets", {
  add_filter("ASEQ1", "Sequence Number 1", c("ADAE", "ADTTE"), ASEQ == 1)
  expect_equal(
    apply_filter(adae, "ASEQ1"),
    dplyr::filter(adae, ASEQ == 1),
    check.attributes = FALSE
  )
  expect_equal(
    apply_filter(adtte, "ASEQ1"),
    dplyr::filter(adtte, ASEQ == 1),
    check.attributes = FALSE
  )
  expect_equal(
    apply_filter(datasets, "ASEQ1"),
    list(
      adsl = datasets$adsl,
      adae = dplyr::filter(datasets$adae, ASEQ == 1),
      adtte = dplyr::filter(datasets$adtte, ASEQ == 1)
    ),
    check.attributes = FALSE
  )
})

test_that("Filtering preserves column labels", {
  expect_equal(
    lapply(adsl, attr, "label"),
    lapply(apply_filter(adsl, "MALE_SE"), attr, "label"),
    check.attributes = FALSE
  )

  expect_equal(
    lapply(datasets$adae, attr, "label"),
    lapply(apply_filter(datasets, "REL_SE")$adae, attr, "label"),
    check.attributes = FALSE
  )
})

test_that("Filter IDs are attached as an attribute", {
  expect_equal(attr(apply_filter(adsl, ""), "filters"), NULL)
  expect_equal(attr(apply_filter(adsl, "SE"), "filters"), "SE")
  expect_equal(
    attr(apply_filter(adsl, "MALE_SE"), "filters"),
    c("MALE", "SE")
  )

  expect_equal(attr(apply_filter(adae, "SE"), "filters"), NULL)
  expect_equal(attr(apply_filter(adae, "SER_SE"), "filters"), "SER")

  expect_equal(attr(filtered_datasets, "filters"), NULL)
  expect_equal(attr(filtered_datasets$adsl, "filters"), c("FEMALE", "SE"))
  expect_equal(attr(filtered_datasets$adae, "filters"), "SER")
})

test_that("Adding new filters works", {
  add_filter("CTC5", "Fatal AEs", "adae", AETOXGR == 5)
  expect_equal(
    get_filter("CTC5"),
    list(title = "Fatal AEs", target = "ADAE", condition = quote(AETOXGR == 5))
  )

  add_filter("UHDRS", "UHDRS", "adqs", condition = "PARAMCD == 'UHDRS'", character_only = TRUE)
  expect_equal(
    get_filter("UHDRS"),
    list(title = "UHDRS", target = "ADQS", condition = quote(PARAMCD == "UHDRS"))
  )
})

test_that("Adding new filters with multiple targets works", {
  add_filter("BASE", "Baseline", c("adae", "adtte"), AVISIT == "BASELINE")
  expect_equal(
    get_filter("BASE"),
    list(
      title = "Baseline",
      target = c("ADAE", "ADTTE"),
      condition = quote(AVISIT == "BASELINE")
    )
  )
})

test_that("Invalid filter IDs throw an error", {
  expect_error(add_filter("foo", "Title", "ds", foo == "bar"))
  expect_error(add_filter("Foo", "Title", "ds", foo == "bar"))
  expect_error(add_filter("FOo", "Title", "ds", foo == "bar"))
  expect_error(add_filter("_foo", "Title", "ds", foo == "bar"))
  expect_error(add_filter(".foo", "Title", "ds", foo == "bar"))
  expect_error(add_filter("FOO_12", "Title", "ds", foo == "bar"))
})

test_that("Overwriting existing filters fails when `overwrite = FALSE`", {
  expect_error(add_filter("REL", "Related AEs", "adae", AEREL == "Y"))
  expect_error(add_filter("IT", "ITT Population", "adsl", ITTFL == "Y"))
})

test_that("Overwriting existing filters suceeds when `overwrite = TRUE`", {
  expect_error(
    add_filter("REL", "Related AEs", "adae", AEREL == "Y", overwrite = TRUE),
    NA # This indicates that *no* error is thrown
  )
  expect_error(
    add_filter("IT", "ITT Population", "adsl", ITTFL == "Y", overwrite = TRUE),
    NA
  )
})

test_that("`get_filter` errors when ID does not exist", {
  expect_error(get_filter("FOO"))
  expect_error(get_filter("BAR"))
  expect_error(get_filter("FOOBAR"))
})

test_that("Filters can only be applied to data frames and lists", {
  expect_error(apply_filter(1:10, "IT"))
  expect_error(apply_filter(letters, "IT"))
  expect_error(apply_filter(NA, "IT"))
  expect_error(apply_filter(factor(letters), "IT"))
})

test_that("Only named lists can be filtered", {
  expect_error(apply_filter(unname(datasets), "SER_SE"))
})

test_that("A missing target datasets causes an error", {
  expect_error(apply_filter(datasets["adsl"], "SER_SE"))
  expect_error(apply_filter(datasets["adae"], "SER_SE"))
})

test_that("All filters are properly listed", {
  # Clear all filters
  rm(list = ls(.filters), envir = .filters)
  add_filter("SER", "Serious AEs", "ADAE", AESER == "Y")
  add_filter("IT", "ITT Population", "ADSL", ITTFL == "Y")
  add_filter("OS", "Overall Survival", "ADTTE", PARAMCD == "OS")

  filters <- data.frame(
    id = c("SER", "IT", "OS"),
    title = c("Serious AEs", "ITT Population", "Overall Survival"),
    target = c("ADAE", "ADSL", "ADTTE"),
    condition = c("AESER == 'Y'", "ITTFL == 'Y'", "PARAMCD == 'OS'"),
    stringsAsFactors = FALSE
  )

  expect_equivalent(list_all_filters(), filters)
})
