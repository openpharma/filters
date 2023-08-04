context("test-load_filters")

filters_file <- system.file("filters_eg.yaml", package = "filters")

test_that("`load_filters` errors when input is not a yaml file", {
  expect_error(load_filters("not_a_yaml_file.txt"))
  expect_error(load_filters("not_a_yaml_file.csv"))
  expect_error(load_filters("not_a_yaml_file.json"))
  expect_error(load_filters("not_a_yaml_file.yml2"))
})

test_that("`load_filters` adds non-existing filters", {
  load_filters(filters_file)
  expect_equal(
    get_filter("CTC13"),
    list(
      title = "Grade 1-3 Adverse Events",
      target = "ADAE",
      condition = quote(ATOXGR %in% c("1", "2", "3"))
    )
  )

  expect_equal(
    get_filter("TP53WT"),
    list(
      title = "TP53 Wild Type",
      target = "ADSL",
      condition = quote(TP53 == "WILD TYPE")
    )
  )
})

test_that("`load_filters` does not overwrite existing filters by default", {
  expect_error(load_filters(filters_file))
})

test_that("`load_filters` overwrites existing filters when `overwrite = TRUE`", {
  expect_error(load_filters(filters_file, overwrite = TRUE), NA)
})
