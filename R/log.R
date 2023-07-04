log_number_of_matched_records <- function(data_original,
                                          data_filtered,
                                          filter_condition) {
  message(sprintf(
    "%d/%d records matched the filter condition `%s`.",
    nrow(data_filtered),
    nrow(data_original),
    deparse(filter_condition, width.cutoff = 500)
  ))
}

log_matching_filters <- function(filters, target) {
  message(sprintf(
    "%s %s matched target %s.",
    if (length(filters) == 1L) "Filter" else "Filters",
    paste(squote(filters), collapse = ", "),
    target
  ))
}
