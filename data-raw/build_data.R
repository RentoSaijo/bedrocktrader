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

# Restore item suffixes.
.restore_item_suffix <- function(item, aux_value) {
  result <- item
  suffixed <- !is.na(item) & !is.na(aux_value)
  result[suffixed] <- paste0(item[suffixed], ':', aux_value[suffixed])
  result
}

# Adopt public Minecraft terminology.
.adopt_trade_names <- function(trades, expanded) {
  trades$tier                     <- trades$level
  trades$num_trades               <- trades$trades_in_group
  trades$num_to_select            <- trades$trades_selected
  trades$num_to_select[trades$all_trades_selected] <- -1L
  trades$num_to_select            <- as.integer(trades$num_to_select)
  trades$wants_1_item             <- .restore_item_suffix(
    trades$cost_1_item,
    trades$cost_1_aux_value
  )
  trades$wants_1_quantity_min     <- trades$cost_1_quantity_min
  trades$wants_1_quantity_max     <- trades$cost_1_quantity_max
  trades$wants_1_price_multiplier <- trades$cost_1_price_multiplier
  trades$wants_2_item             <- .restore_item_suffix(
    trades$cost_2_item,
    trades$cost_2_aux_value
  )
  trades$wants_2_quantity_min     <- trades$cost_2_quantity_min
  trades$wants_2_quantity_max     <- trades$cost_2_quantity_max
  trades$wants_2_price_multiplier <- trades$cost_2_price_multiplier
  trades$gives_1_item             <- .restore_item_suffix(
    trades$result_item,
    trades$result_aux_value
  )
  trades$gives_1_quantity_min     <- trades$result_quantity_min
  trades$gives_1_quantity_max     <- trades$result_quantity_max
  trades$gives_1_color            <- trades$result_color
  trades$gives_1_effect           <- trades$result_effect
  trades$gives_1_potion           <- trades$potion
  trades$gives_1_map_destination  <- trades$map_destination
  trades$gives_1_enchantments     <- trades$enchantments
  trades$gives_1_treasure         <- trades$treasure
  trades$functions                <- trades$generator
  trades$trader_exp               <- trades$villager_exp
  trades$reward_exp               <- trades$player_exp
  trades$.variants                <- trades$variants
  trades$.dimensions              <- trades$dimensions
  trades$.function_probability    <- trades$.generator_probability
  runtime <- new.env(parent = baseenv())
  sys.source('R/constants.R', envir = runtime)
  public_columns <- if (expanded) {
    runtime$.bedrock_expanded_trade_columns
  } else {
    runtime$.bedrock_compact_trade_columns
  }
  public_columns <- setdiff(
    public_columns,
    c('offer_probability', 'probability_status')
  )
  private_columns <- c(
    '.variants',
    '.dimensions',
    '.source_option',
    '.trade_weight',
    '.function_probability',
    '.probability_status'
  )
  trades[, c(public_columns, private_columns), drop = FALSE]
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

# Build compact trade options.
trade_options <- lapply(.bedrock_trade_tables, function(table) {
  .flatten_trade_table(table, release, expanded = FALSE)
})
.bedrock_trade_options <- .adopt_trade_names(
  do.call(rbind, trade_options),
  expanded = FALSE
)
rownames(.bedrock_trade_options) <- NULL

# Build expanded trade outcomes.
trade_outcomes <- lapply(.bedrock_trade_tables, function(table) {
  .flatten_trade_table(table, release, expanded = TRUE)
})
.bedrock_trade_outcomes <- .adopt_trade_names(
  do.call(rbind, trade_outcomes),
  expanded = TRUE
)
rownames(.bedrock_trade_outcomes) <- NULL

# Validate flattened trade counts.
if (nrow(.bedrock_trade_options) != 281L) {
  stop('Pinned compact trade data must contain 281 rows.', call. = FALSE)
}
if (nrow(.bedrock_trade_outcomes) != 2787L) {
  stop('Pinned expanded trade data must contain 2,787 rows.', call. = FALSE)
}
probability_groups <- interaction(
  .bedrock_trade_outcomes$profession,
  .bedrock_trade_outcomes$trade_id,
  .bedrock_trade_outcomes$.source_option,
  drop = TRUE
)
probability_sums <- tapply(
  .bedrock_trade_outcomes$.function_probability,
  probability_groups,
  sum
)
if (any(abs(probability_sums - 1) > 1e-10)) {
  stop(
    'Expanded function probabilities must sum to one per base option.',
    call. = FALSE
  )
}

# Record internal model metadata.
.bedrock_model_metadata <- list(
  bedrock_version = .bedrock_version,
  release_date    = .bedrock_release_date,
  release_tag     = .bedrock_release_tag,
  parser_model    = 2L,
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
  .bedrock_trade_options,
  .bedrock_trade_outcomes,
  .bedrock_variants_data,
  file     = 'R/sysdata.rda',
  compress = 'xz',
  version  = 2
)
