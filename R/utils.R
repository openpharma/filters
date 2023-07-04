squote <- function(x) {
  paste0("'", x, "'")
}

as_data_frame <- function(lst) {
  class(lst) <- c("tbl_df", "tbl", "data.frame")
  attr(lst, "row.names") <- seq_along(lst[[1L]])
  lst
}

deparse <- function(expr, ...) {
  gsub('"', "'", base::deparse(expr, ...))
}

map_chr <- function(x, fun, ...) {
  vapply(x, fun, character(1L), ...)
}

map_bool <- function(x, fun, ...) {
  vapply(x, fun, logical(1L), ...)
}

get_labels <- function(data) {
  lapply(data, attr, "label")
}

set_labels <- function(data, labels) {
  stopifnot(length(data) == length(labels))
  for (i in seq_along(data)) {
    attr(data[[i]], "label") <- labels[[i]]
  }
  data
}

combine_filter_conditions <- function(filters) {
  Reduce(
    function(lhs, rhs) bquote(.(lhs) & .(rhs)),
    lapply(filters, `[[`, "condition")
  )
}

semi_join <- function(x, y, by) {
  rows_to_keep <- interaction(x[, by]) %in% interaction(y[, by])
  set_labels(x[rows_to_keep, ], get_labels(x))
}
