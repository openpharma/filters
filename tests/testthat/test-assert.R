context("test-assert")

test_that("`assert_character_scalar` works", {
  # Valid inputs which shoudl *not* throw an error
  expect_error(assert_character_scalar("a"), NA)
  expect_error(assert_character_scalar(""), NA)

  # Invalid inputs which should cause an error
  err_msg <- "must be a character scalar"
  expect_error(assert_character_scalar(c("a", "b")), err_msg)
  expect_error(assert_character_scalar(c("foo", NA, "bar")), err_msg)
  expect_error(assert_character_scalar(NA), err_msg)
  expect_error(assert_character_scalar(NA_character_), err_msg)
  expect_error(assert_character_scalar(NULL), err_msg)
  expect_error(assert_character_scalar(list()), err_msg)
  expect_error(assert_character_scalar(list(letters)), err_msg)
})

test_that("`assert_logical_scalar` works", {
  # Valid inputs which shoudl *not* throw an error
  expect_error(assert_logical_scalar(TRUE), NA)
  expect_error(assert_logical_scalar(FALSE), NA)

  # Invalid inputs which should cause an error
  err_msg <- "must be a logical scalar"
  expect_error(assert_logical_scalar("TRUE"), err_msg)
  expect_error(assert_logical_scalar(c(TRUE, TRUE)), err_msg)
  expect_error(assert_logical_scalar(NA), err_msg)
  expect_error(assert_logical_scalar(1), err_msg)
})

test_that("`assert_character_vector` works", {
  # Valid inputs which shoudl *not* throw an error
  expect_error(assert_character_vector("a"), NA)
  expect_error(assert_character_vector(""), NA)
  expect_error(assert_character_vector(c("a", "b")), NA)

  # Invalid inputs which should cause an error
  err_msg <- "must be a character vector"
  expect_error(assert_character_vector(c("foo", NA, "bar")), err_msg)
  expect_error(assert_character_vector(NA), err_msg)
  expect_error(assert_character_vector(NA_character_), err_msg)
  expect_error(assert_character_vector(NULL), err_msg)
  expect_error(assert_character_vector(list()), err_msg)
  expect_error(assert_character_vector(list(letters)), err_msg)
})
