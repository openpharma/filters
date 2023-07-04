.filters <- new.env(parent = emptyenv())

local({
  file_path <- system.file("filters.yaml", package = "filters")
  # load_filters(file_path)
  filter_definitions <- plyr::ldply(yaml::read_yaml(file_path), data.frame, stringsAsFactors=FALSE)
  filter_definitions$id = filter_definitions$.id
  filter_definitions$.id = NULL
  for (i in seq_len(nrow(filter_definitions))) {
    add_filter(
      id = filter_definitions$filter_identifier[i],
      title = filter_definitions$filter_title[i],
      target = filter_definitions$filter_target[i],
      condition = filter_definitions$filter_condition[i],
      character_only = TRUE
    )
  }

})
