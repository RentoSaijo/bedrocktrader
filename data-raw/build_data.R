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
.adopt_trade_names <- function(trades) {
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
  public_columns <- setdiff(
    runtime$.bedrock_trade_columns,
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

# Create a stable text key.
.row_key <- function(rows, columns) {
  values <- lapply(rows[, columns, drop = FALSE], function(value) {
    result <- as.character(value)
    result[is.na(result)] <- '<NA>'
    result
  })
  do.call(paste, c(values, sep = '\r'))
}

# Build option and offer identifiers.
.build_hierarchical_views <- function(offers) {
  option_columns <- c(
    '.source_option',
    'wants_1_item',
    'wants_1_price_multiplier',
    'wants_2_item',
    'wants_2_quantity_min',
    'wants_2_quantity_max',
    'wants_2_price_multiplier',
    'gives_1_item',
    'gives_1_quantity_min',
    'gives_1_quantity_max',
    'gives_1_color',
    'gives_1_effect',
    'gives_1_potion',
    'gives_1_map_destination',
    'gives_1_enchantments',
    'gives_1_treasure',
    'functions',
    'max_uses',
    'trader_exp',
    'reward_exp',
    '.variants',
    '.dimensions'
  )
  offers$.option_key <- paste(
    offers$trade_id,
    .row_key(offers, option_columns),
    sep = '\r'
  )
  trade_order <- match(offers$trade_id, unique(offers$trade_id))
  option_sort <- .row_key(offers, option_columns)
  row_order <- order(
    trade_order,
    offers$.source_option,
    option_sort,
    offers$wants_1_quantity_min,
    offers$wants_1_quantity_max,
    na.last = TRUE
  )
  offers <- offers[row_order, , drop = FALSE]
  offers$option_id <- NA_character_
  for (trade_id in unique(offers$trade_id)) {
    trade_rows <- offers$trade_id == trade_id
    option_keys <- unique(offers$.option_key[trade_rows])
    offers$option_id[trade_rows] <- paste0(
      trade_id,
      '_o',
      match(offers$.option_key[trade_rows], option_keys)
    )
  }
  offers$offer_id <- NA_character_
  for (option_id in unique(offers$option_id)) {
    option_rows <- which(offers$option_id == option_id)
    offers$offer_id[option_rows] <- paste0(
      option_id,
      '_f',
      seq_along(option_rows)
    )
  }
  option_keys <- unique(offers$.option_key)
  options <- lapply(option_keys, function(option_key) {
    option_rows <- which(offers$.option_key == option_key)
    result <- offers[option_rows[[1L]], , drop = FALSE]
    result$wants_1_quantity_min <- min(
      offers$wants_1_quantity_min[option_rows]
    )
    result$wants_1_quantity_max <- max(
      offers$wants_1_quantity_max[option_rows]
    )
    result$.function_probability <- sum(
      offers$.function_probability[option_rows]
    )
    result$offer_id <- NULL
    result
  })
  options <- do.call(rbind, options)
  offers$.option_key <- NULL
  options$.option_key <- NULL
  rownames(offers) <- NULL
  rownames(options) <- NULL
  list(options = options, offers = offers)
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

# Build enchantment metadata.
.validate_enchantment_registry(release)
enchantment_definitions <- rbind(
  .bedrock_enchantments,
  .bedrock_special_enchantments
)
traded_items <- vapply(
  enchantment_definitions$enchantment,
  function(enchantment) {
    item_types <- names(.bedrock_equipment_enchantments)[vapply(
      .bedrock_equipment_enchantments,
      function(definitions) enchantment %in% definitions$enchantment,
      logical(1)
    )]
    items <- sort(unique(
      .bedrock_enchanted_items$item[
        .bedrock_enchanted_items$item_type %in% item_types
      ]
    ))
    if (!length(items)) {
      return(NA_character_)
    }
    paste(items, collapse = ', ')
  },
  character(1)
)
.bedrock_enchantments_data <- data.frame(
  enchantment = paste0(
    'minecraft:',
    enchantment_definitions$enchantment
  ),
  display_name          = enchantment_definitions$enchantment_name,
  max_level             = enchantment_definitions$max_level,
  treasure              = enchantment_definitions$treasure,
  villager_attainable   = enchantment_definitions$enchantment %in%
    .bedrock_enchantments$enchantment,
  traded_items          = traded_items,
  stringsAsFactors      = FALSE
)
.bedrock_enchantments_data <- .bedrock_enchantments_data[
  order(.bedrock_enchantments_data$enchantment),
  ,
  drop = FALSE
]
rownames(.bedrock_enchantments_data) <- NULL

# Build trade view.
trade_rows <- lapply(.bedrock_trade_tables, function(table) {
  .flatten_trade_table(table, release, expanded = FALSE)
})
.bedrock_trade_trades <- .adopt_trade_names(
  do.call(rbind, trade_rows)
)
rownames(.bedrock_trade_trades) <- NULL

# Build option and offer views.
offer_rows <- lapply(.bedrock_trade_tables, function(table) {
  .flatten_trade_table(table, release, expanded = TRUE)
})
.bedrock_trade_offers <- .adopt_trade_names(
  do.call(rbind, offer_rows)
)
hierarchical_views <- .build_hierarchical_views(.bedrock_trade_offers)
.bedrock_trade_options <- hierarchical_views$options
.bedrock_trade_offers  <- hierarchical_views$offers

# Validate flattened trade counts.
if (nrow(.bedrock_trade_trades) != 281L) {
  stop('Pinned trade view must contain 281 rows.', call. = FALSE)
}
if (nrow(.bedrock_trade_options) != 2787L) {
  stop('Pinned option view must contain 2,787 rows.', call. = FALSE)
}
if (nrow(.bedrock_trade_offers) != 30592L) {
  stop('Pinned offer view must contain 30,592 rows.', call. = FALSE)
}
if (
  anyDuplicated(.bedrock_trade_options$option_id) ||
  anyDuplicated(.bedrock_trade_offers$offer_id) ||
  !setequal(
    .bedrock_trade_options$option_id,
    .bedrock_trade_offers$option_id
  )
) {
  stop('Hierarchical trade identifiers are inconsistent.', call. = FALSE)
}
quantity_pairs <- list(
  c('wants_1_quantity_min', 'wants_1_quantity_max'),
  c('wants_2_quantity_min', 'wants_2_quantity_max'),
  c('gives_1_quantity_min', 'gives_1_quantity_max')
)
for (pair in quantity_pairs) {
  minimum <- .bedrock_trade_offers[[pair[[1L]]]]
  maximum <- .bedrock_trade_offers[[pair[[2L]]]]
  populated <- !is.na(minimum) & !is.na(maximum)
  if (any(minimum[populated] != maximum[populated])) {
    stop(
      'Offer quantities must describe exact configurations.',
      call. = FALSE
    )
  }
}
option_probability <- setNames(
  .bedrock_trade_options$.function_probability,
  .bedrock_trade_options$option_id
)
offer_probability <- tapply(
  .bedrock_trade_offers$.function_probability,
  .bedrock_trade_offers$option_id,
  sum
)
offer_probability <- offer_probability[names(option_probability)]
if (
  anyNA(offer_probability) ||
  any(abs(option_probability - offer_probability) > 1e-10)
) {
  stop(
    'Option probabilities must equal their aggregated offers.',
    call. = FALSE
  )
}
probability_groups <- interaction(
  .bedrock_trade_offers$profession,
  .bedrock_trade_offers$trade_id,
  .bedrock_trade_offers$.source_option,
  drop = TRUE
)
probability_sums <- tapply(
  .bedrock_trade_offers$.function_probability,
  probability_groups,
  sum
)
if (any(abs(probability_sums - 1) > 1e-10)) {
  stop(
    'Offer probabilities must sum to one per base trade choice.',
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
  .bedrock_enchantments_data,
  .bedrock_model_metadata,
  .bedrock_professions_data,
  .bedrock_tiers_data,
  .bedrock_trade_trades,
  .bedrock_trade_options,
  .bedrock_trade_offers,
  .bedrock_variants_data,
  file     = 'R/sysdata.rda',
  compress = 'xz',
  version  = 2
)
