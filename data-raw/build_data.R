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
  'data-raw/constants.R',
  'data-raw/retrieve.R',
  'data-raw/normalize.R',
  'data-raw/enchantment-model.R',
  'data-raw/flatten.R'
)
for (source_file in source_files) {
  sys.source(source_file, envir = globalenv())
}

# Build Helpers -----------------------------------------------------------------

# Collapse aliases.
.collapse_aliases <- function(aliases) {
  if (!length(aliases)) {
    return(NA_character_)
  }
  paste(aliases, collapse = ', ')
}

# Flatten normalized item positions.
.trade_positions <- function(table) {
  positions <- list()
  for (tier in table$levels) {
    for (group in tier$groups) {
      for (trade in group$candidates) {
        positions <- c(
          positions,
          trade$wants,
          trade$gives
        )
      }
    }
  }
  positions
}

# Summarize profession mechanisms.
.profession_features <- function(table) {
  positions <- .trade_positions(table)
  context_sensitive <- any(vapply(
    positions,
    function(position) {
      position_filtered <- !is.null(position$filters)
      choice_filtered <- any(vapply(
        position$choices,
        function(choice) !is.null(choice$filters),
        logical(1)
      ))
      position_filtered || choice_filtered
    },
    logical(1)
  ))
  contains_item_choices <- any(vapply(
    positions,
    function(position) position$has_choice,
    logical(1)
  ))
  contains_dynamic_functions <- any(vapply(
    positions,
    function(position) {
      position_dynamic <- length(position$functions) > 0L
      choice_dynamic <- any(vapply(
        position$choices,
        function(choice) length(choice$functions) > 0L,
        logical(1)
      ))
      position_dynamic || choice_dynamic
    },
    logical(1)
  ))
  c(
    context_sensitive          = context_sensitive,
    contains_item_choices      = contains_item_choices,
    contains_dynamic_functions = contains_dynamic_functions
  )
}

# Adopt public Minecraft terminology.
.adopt_trade_names <- function(trades) {
  mappings <- c(
    level                 = 'tier',
    level_name            = 'tier_name',
    trades_in_group       = 'num_trades',
    trades_selected       = 'num_to_select',
    all_trades_selected   = 'select_all',
    cost_1_item           = 'wants_1_item',
    cost_1_aux_value      = 'wants_1_aux_value',
    cost_1_quantity_min   = 'wants_1_quantity_min',
    cost_1_quantity_max   = 'wants_1_quantity_max',
    cost_1_price_multiplier = 'wants_1_price_multiplier',
    cost_2_item           = 'wants_2_item',
    cost_2_aux_value      = 'wants_2_aux_value',
    cost_2_quantity_min   = 'wants_2_quantity_min',
    cost_2_quantity_max   = 'wants_2_quantity_max',
    cost_2_price_multiplier = 'wants_2_price_multiplier',
    result_item           = 'gives_1_item',
    result_aux_value      = 'gives_1_aux_value',
    result_quantity_min   = 'gives_1_quantity_min',
    result_quantity_max   = 'gives_1_quantity_max',
    result_color          = 'gives_1_color',
    result_effect         = 'gives_1_effect',
    potion                = 'gives_1_potion',
    map_destination       = 'gives_1_map_destination',
    enchantments          = 'gives_1_enchantments',
    enchantment_count     = 'gives_1_enchantment_count',
    treasure              = 'gives_1_treasure',
    generator             = 'functions',
    enchanting_power_min  = 'levels_min',
    enchanting_power_max  = 'levels_max',
    villager_exp          = 'trader_exp',
    player_exp            = 'reward_exp',
    .generator_probability = '.function_probability'
  )
  matched <- match(names(mappings), names(trades))
  names(trades)[matched] <- unname(mappings)
  trades$num_to_select[trades$select_all] <- -1L
  trades$num_to_select <- as.integer(trades$num_to_select)
  runtime <- new.env(parent = baseenv())
  sys.source('R/constants.R', envir = runtime)
  columns <- c(
    runtime$.bedrock_trade_columns,
    '.source_option',
    '.function_probability',
    '.probability_status',
    '.probability_basis'
  )
  trades[, columns, drop = FALSE]
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

# Build villager tier metadata.
tier_requirements <- lapply(.bedrock_trade_tables, function(table) {
  vapply(
    table$levels,
    function(tier) tier$total_exp_required,
    numeric(1)
  )
})
if (!all(vapply(
  tier_requirements,
  identical,
  logical(1),
  tier_requirements[[1L]]
))) {
  stop(
    'Villager tier requirements differ across profession tables.',
    call. = FALSE
  )
}
.bedrock_tiers_data <- data.frame(
  tier               = seq_along(.bedrock_level_names),
  tier_name          = .bedrock_level_names,
  total_exp_required = tier_requirements[[1L]],
  stringsAsFactors   = FALSE
)

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
.bedrock_trade_outcomes <- .adopt_trade_names(
  do.call(rbind, trade_outcomes)
)
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
  .bedrock_tiers_data,
  .bedrock_trade_outcomes,
  .bedrock_variants_data,
  file     = 'R/sysdata.rda',
  compress = 'xz',
  version  = 2
)
