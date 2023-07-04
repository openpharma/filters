#' Load Filter Definitions
#'
#' Load filter definitions from a yaml file
#'
#' @param yaml_file `character`. A path to a yaml file containing filter definitions
#' @param overwrite `logical`. Should existing filter definitions be overwritten?
#'        Defaults to `FALSE`.
#'
#' @return On success, `load_filters()` returns `TRUE` invisibly
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' filter_definitions <- system.file("filters.yaml", package = "filters")
#' if (interactive()) file.edit(filter_definitions)
#' load_filters(filter_definitions, overwrite = TRUE)
#'
load_filters <- function(yaml_file, overwrite = FALSE) {
  stopifnot(tolower(tools::file_ext(yaml_file)) %in% c("yml", "yaml"))
  filter_spec <- yaml::read_yaml(yaml_file)
  Map(function(filter, spec) {
    add_filter(
      id = filter,
      title = spec$title,
      target = spec$target,
      condition = spec$condition,
      character_only = TRUE,
      overwrite = overwrite
    )
  }, names(filter_spec), filter_spec)
  invisible(TRUE)
}
