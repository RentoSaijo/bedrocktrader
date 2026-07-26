# Setup ------------------------------------------------------------------------

# Check maintainer dependencies.
packages <- c('curl', 'digest', 'jsonlite')
available <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop(
    'Install the data-build packages: ',
    paste(packages[!available], collapse = ', '),
    '.',
    call. = FALSE
  )
}

# Load package data builders.
source_files <- c(
  'R/constants.R',
  'R/retrieve.R',
  'R/normalize.R',
  'R/enchantment-model.R',
  'R/flatten.R',
  'R/data.R'
)
for (source_file in source_files) {
  sys.source(source_file, envir = globalenv())
}

# Source Data ------------------------------------------------------------------

# Retrieve and normalize profession tables.
release <- .pinned_release()
professions <- .bedrock_professions$profession
.bedrock_trade_tables <- vector('list', length(professions))
names(.bedrock_trade_tables) <- professions
for (index in seq_along(professions)) {
  profession <- professions[[index]]
  source_file <- .bedrock_professions$source_file[
    match(profession, .bedrock_professions$profession)
  ]
  source_path <- paste0(.bedrock_trade_directory, '/', source_file)
  content     <- .fetch_pinned_file(source_path)
  table       <- .parse_json(content, source_path)
  .bedrock_trade_tables[[index]] <- .normalize_trade_table(
    table       = table,
    profession  = profession,
    release     = release,
    source_path = source_path
  )
}

# Retrieve and normalize villager variants.
variant_content <- .fetch_pinned_file(.bedrock_variant_path)
variant_entity  <- .parse_json(variant_content, .bedrock_variant_path)
.bedrock_variants_data <- data.frame(
  variant      = .bedrock_variants,
  mark_variant = .normalize_variants(variant_entity, release),
  aliases      = vapply(
    .bedrock_variant_aliases[.bedrock_variants],
    .collapse_aliases,
    character(1)
  ),
  stringsAsFactors = FALSE
)

# Summarize profession features.
features <- lapply(.bedrock_trade_tables, .profession_features)
.bedrock_professions_data <- data.frame(
  profession                  = professions,
  display_name                = .bedrock_professions$display_name,
  aliases                     = vapply(
    .bedrock_profession_aliases[professions],
    .collapse_aliases,
    character(1)
  ),
  context_sensitive           = vapply(
    features,
    function(feature) feature[['context_sensitive']],
    logical(1)
  ),
  contains_item_choices       = vapply(
    features,
    function(feature) feature[['contains_item_choices']],
    logical(1)
  ),
  contains_dynamic_functions  = vapply(
    features,
    function(feature) feature[['contains_dynamic_functions']],
    logical(1)
  ),
  stringsAsFactors = FALSE
)

# Build flattened trade outcomes.
trade_outcomes <- lapply(.bedrock_trade_tables, function(table) {
  .flatten_trade_table(table, release)
})
.bedrock_trade_outcomes <- do.call(rbind, trade_outcomes)
rownames(.bedrock_trade_outcomes) <- NULL

# Record internal model metadata.
.bedrock_model_metadata <- list(
  bedrock_version = .bedrock_version,
  release_date    = .bedrock_release_date,
  release_tag     = .bedrock_release_tag,
  parser_model    = 1L,
  enchantment_model = list(
    source   = 'Minecraft Wiki: Enchanting table mechanics',
    revision = 3681507L
  ),
  source_shas     = .bedrock_blob_shas
)

# Package Data -----------------------------------------------------------------

# Save private package data.
save(
  .bedrock_model_metadata,
  .bedrock_professions_data,
  .bedrock_trade_outcomes,
  .bedrock_trade_tables,
  .bedrock_variants_data,
  file     = 'R/sysdata.rda',
  compress = 'xz',
  version  = 2
)
