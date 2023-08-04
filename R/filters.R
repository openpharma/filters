#' Add a New Filter Definition
#'
#' Add a new filter definition or overwrite an existing one
#'
#' @param id `character` The id or name of this filter, e.g. `"SE"`.
#' @param title `character` The title of the filter
#' @param target `character` The target dataset of the filter
#' @param condition The filter condition
#' @param character_only `logical`. Is `condition` a string? Defaults to `FALSE`.
#' @param overwrite `logical` Should existing filters be overwritten? Defaults to `FALSE`.
#'
#' @return
#' The function returns a `list` of `title`, `target` and `condition`
#' invisibly
#'
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' add_filter(
#'   id = "CTC5",
#'   title = "Grade 5 Adverse Event",
#'   target = "ADAE",
#'   condition = AETOXGR == "5"
#' )
#'
#' add_filter(
#'   id = "CTC4",
#'   title = "Grade 4 Adverse Event",
#'   target = "ADAE",
#'   condition = "AETOXGR == '4'",
#'   character_only = TRUE
#' )
#'
#' add_filter(
#'   id = "IT",
#'   title = "ITT Population",
#'   target = "ADSL",
#'   condition = ITTFL == "Y",
#'   overwrite = TRUE
#' )
#'
#' add_filter(
#'   id = "5PER",
#'   title = "Adverse Events with a Difference of at Least 5% between Treatment Arms",
#'   target = "adae",
#'   condition = 1 == 1,
#'   overwrite = TRUE
#' )
#'
add_filter <- function(id,
                       title,
                       target,
                       condition,
                       character_only = FALSE,
                       overwrite = FALSE) {
  assert_valid_id(id)
  tryCatch(
    {
      assert_character_scalar(title)
      assert_character_vector(target)
      assert_logical_scalar(character_only)
    },
    error = function(e) {
      stop("Failed at filter ", squote(id), "\n", print(e))
    }
  )
  assert_logical_scalar(overwrite)
  if (!overwrite) assert_filter_exists(id)

  condition <- if (character_only) {
    # `parse()` returns an expression (vector) unlike `str2lang()` which returns a
    # (scalar) language object. The latter is preferable but `str2lang()` is only
    # available from R version 3.5 onwards. By using `[[` one can extract the
    # language object from the expression
    parse(text = condition, keep.source = FALSE)[[1L]]
  } else {
    substitute(condition)
  }

  .filters[[id]] <- list(
    title = title,
    target = toupper(target),
    condition = condition
  )
}

#' Get a Filter Definition
#'
#' @param id `character`. The filter ID
#'
#' @return A `list` with elements `title`, `target` and `condition`
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' get_filter("SE")
#' get_filter("SER")
#'
#' ## Filter `FOO` does not exist
#' try(get_filter("FOO"))
#'
get_filter <- function(id) {
  assert_valid_id(id)
  if (!id %in% ls(envir = .filters)) {
    stop("Filter ", squote(id), " does not exist.", call. = FALSE)
  }
  .filters[[id]]
}

#' Get Multiple Filter Definitions
#'
#' @param ids `character`. The filter IDs as a single string separated by underscores
#'
#' @return A named `list` of filter definitions
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' get_filters("REL_SER")
#' get_filters("OS_IT")
#'
get_filters <- function(ids) {
  assert_character_scalar(ids)
  ids <- strsplit(ids, "_")[[1L]]
  filters <- lapply(ids, get_filter)
  names(filters) <- ids
  filters
}

#' List All Filters
#'
#' List all available filters
#'
#' @return A `data.frame` with columns `id`, `title`, `target` and `condition`
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' list_all_filters()
#'
list_all_filters <- function() {
  filters_list <- as.list(.filters)
  filters <- list(
    id = names(filters_list),
    title = map_chr(filters_list, `[[`, "title"),
    target = map_chr(filters_list, `[[`, "target"),
    condition = map_chr(filters_list, function(x) deparse(x[["condition"]]))
  )
  as_data_frame(filters)[order(filters$target, filters$id), ]
}

#' Apply a Filter to a Dataset or List of Datasets
#'
#' @param data `data.frame` of `list` of `data.frame`s
#' @param id `character`. The ID of a filter defined with `add_filter()`
#' @param target `character`. The name of the dataset, e.g. ADSL or ADTTE
#' @param verbose `logical`. Should informative messages be printed? Defaults to `TRUE`.
#' @param ... Not used.
#'
#' @return A new `data.frame` or `list` of `data.frame`s filtered based upon the condition defined for `id`
#' @author Thomas Neitmann (`neitmant`)
#' @export
#'
#' @examples
#' adsl <- random.cdisc.data::cadsl
#' adae <- random.cdisc.data::cadae
#' datasets <- list(adsl = adsl, adae = adae)
#'
#' add_filter("REL", "Related AEs", "ADAE", AEREL == "Y", overwrite = TRUE)
#'
#' apply_filter(adsl, "SE")
#' apply_filter(adae, "SER_REL")
#' apply_filter(datasets, "SER_REL_SE")
#'
apply_filter <- function(data, ...) {
  UseMethod("apply_filter")
}

#' @rdname apply_filter
#' @export
apply_filter.default <- function(data, ...) {
  stop("No `apply_filter()` method defined for class `", class(data)[1L], "`.")
}

#' @rdname apply_filter
#' @export
apply_filter.data.frame <- function(data,
                                    id,
                                    target = deparse(substitute(data)),
                                    verbose = TRUE,
                                    ...) {
  assert_data_frame(data)
  if (!is.null(id)) assert_character_scalar(id)
  assert_character_scalar(target)
  assert_logical_scalar(verbose)

  if (id == "" || is.null(id)) {
    return(data)
  }

  target <- toupper(target)
  filters <- get_filters(id)
  filter_targets <- lapply(filters, `[[`, "target")
  matches_target <- map_bool(filter_targets, function(t) target %in% t)
  matching_filters <- filters[matches_target]

  if (!length(matching_filters)) {
    if (verbose) {
      message("No filter matched target ", target, ".")
    }
    return(data)
  }

  if (verbose) {
    log_matching_filters(names(matching_filters), target)
  }

  filter_condition <- combine_filter_conditions(matching_filters)
  call <- call("subset", x = quote(data), subset = filter_condition)
  filtered_data <- eval(call)
  attr(filtered_data, "filters") <- names(matching_filters)

  if (verbose) {
    log_number_of_matched_records(data, filtered_data, filter_condition)
  }

  set_labels(filtered_data, get_labels(data))
}

#' @rdname apply_filter
#' @export
apply_filter.list <- function(data, id, verbose = TRUE, ...) {
  assert_named_list_of_data_frames(data)

  dataset_names <- toupper(names(data))
  filters <- get_filters(id)
  datasets_to_filter <- unique(unlist(lapply(filters, `[[`, "target")))
  missing_datasets <- setdiff(datasets_to_filter, dataset_names)

  if (length(missing_datasets)) {
    stop(
      "The following filter targets are missing in `data`: ",
      paste(missing_datasets, collapse = ", "), ".",
      call. = FALSE
    )
  }

  filtered_datasets <- Map(function(dataset, name) {
    if (!name %in% datasets_to_filter) {
      dataset
    } else {
      apply_filter(
        data = dataset,
        id = id,
        verbose = verbose,
        target = name
      )
    }
  }, data, dataset_names)

  if ("ADSL" %in% datasets_to_filter) {
    remove_subjects_not_in_adsl(filtered_datasets)
  } else {
    filtered_datasets
  }
}

remove_subjects_not_in_adsl <- function(filtered_datasets) {
  is_adsl <- toupper(names(filtered_datasets)) == "ADSL"
  non_adsl_datasets <- names(filtered_datasets)[!is_adsl]
  for (ds in non_adsl_datasets) {
    filtered_datasets[[ds]] <- semi_join(
      filtered_datasets[[ds]],
      filtered_datasets[[which(is_adsl)]],
      by = c("STUDYID", "USUBJID")
    )
  }
  filtered_datasets
}
