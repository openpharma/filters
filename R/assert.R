abort <- function(...) {
  stop(..., call. = FALSE)
}

assert_valid_id <- function(id) {
  assert_character_scalar(id)
  if (!grepl("^[A-Z0-9]([A-Z0-9])*$", id)) {
    abort(
      "`id` may only contain uppercase letters and numbers."
    )
  }
}

assert_filter_exists <- function(id) {
  if (exists(id, envir = .filters, inherits = FALSE)) {
    abort(
      "Filter ", squote(id), " already exists. Set `overwrite = TRUE` ",
      "to force overwriting the existing filter definition."
    )
  }
}

new_assert_scalar <- function(predicate, type) {
  function(x) {
    if (length(x) != 1L || !predicate(x) || is.na(x)) {
      abort("`", substitute(x), "` must be a ", type, " scalar.")
    }
  }
}
assert_character_scalar <- new_assert_scalar(is.character, "character")
assert_logical_scalar <- new_assert_scalar(is.logical, "logical")

assert_character_vector <- function(x) {
  if (length(x) == 0L || !is.character(x) || any(is.na(x))) {
    abort(
      "`", deparse(substitute(x)), "` must be a character vector ",
      "containing no `NA` values."
    )
  }
}

assert_data_frame <- function(x) {
  if (!is.data.frame(x)) {
    abort( "`", substitute(x), "` must be a data.frame.")
  }
}

assert_named_list_of_data_frames <- function(x) {
  if (!is.list(x) ||
      is.null(names(x)) ||
      any(names(x) == "") ||
      any(map_bool(x, Negate(is.data.frame)))) {
    abort("`", substitute(x), "` must be a named list of data frames.")
  }
}
