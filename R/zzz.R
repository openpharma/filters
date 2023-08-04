.filters <- new.env(parent = emptyenv())

local({
  file_path <- system.file("filters.yaml", package = "filters")
  filter_definitions <- plyr::ldply(yaml::read_yaml(file_path), data.frame, stringsAsFactors = FALSE)
  filter_definitions$id <- filter_definitions$.id
  filter_definitions$.id <- NULL
  for (i in seq_len(nrow(filter_definitions))) {
    add_filter(
      id = filter_definitions$id[i],
      title = filter_definitions$title[i],
      target = filter_definitions$target[i],
      condition = filter_definitions$condition[i],
      character_only = TRUE
    )
  }
})
