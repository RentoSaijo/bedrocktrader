# Level Helpers ----------------------------------------------------------------

# Normalize villager level input.
.normalize_level_input <- function(level, allow_null = TRUE) {
  if (allow_null && is.null(level)) {
    return(seq_along(.bedrock_level_names))
  }
  if (length(level) != 1L || is.na(level)) {
    stop('`level` must be one villager level.', call. = FALSE)
  }
  if (is.numeric(level)) {
    if (
      !is.finite(level) ||
      level != floor(level) ||
      !(level %in% 1:5)
    ) {
      stop('`level` must be an integer from 1 through 5.', call. = FALSE)
    }
    return(as.integer(level))
  }
  if (!is.character(level) || !nzchar(level)) {
    stop(
      '`level` must be an integer from 1 through 5 or a level name.',
      call. = FALSE
    )
  }
  value <- tolower(trimws(level))
  matched <- match(value, .bedrock_level_names)
  if (is.na(matched)) {
    stop(
      '`level` must be novice, apprentice, journeyman, expert, or master.',
      call. = FALSE
    )
  }
  matched
}

# Context Helpers ---------------------------------------------------------------

# Combine contextual restrictions.
.combine_context <- function(left, right) {
  combine_axis <- function(x, y) {
    if (is.null(x)) {
      return(y)
    }
    if (is.null(y)) {
      return(x)
    }
    intersect(x, y)
  }
  list(
    variants   = combine_axis(left$variants, right$variants),
    dimensions = combine_axis(left$dimensions, right$dimensions)
  )
}

# Normalize one filter leaf.
.filter_leaf_context <- function(filter, release, path) {
  .validate_keys(
    filter,
    required = c('test', 'subject', 'value', 'operator'),
    allowed  = c('test', 'subject', 'value', 'operator'),
    release  = release,
    path     = path
  )
  if (
    !identical(filter$subject, 'self') ||
    !identical(filter$operator, '=')
  ) {
    .schema_error(
      release,
      path,
      'only self equality filters are supported'
    )
  }
  if (identical(filter$test, 'is_mark_variant')) {
    .validate_number(filter$value, release, paste0(path, '.value'))
    if (
      filter$value != floor(filter$value) ||
      !(filter$value %in% (seq_along(.bedrock_variants) - 1L))
    ) {
      .schema_error(
        release,
        paste0(path, '.value'),
        'unknown villager mark-variant value'
      )
    }
    return(list(
      variants   = .bedrock_variants[[as.integer(filter$value) + 1L]],
      dimensions = NULL
    ))
  }
  if (identical(filter$test, 'in_overworld')) {
    .validate_logical(filter$value, release, paste0(path, '.value'))
    if (!isTRUE(filter$value)) {
      .schema_error(
        release,
        paste0(path, '.value'),
        'non-Overworld filters cannot identify one dimension'
      )
    }
    return(list(
      variants   = NULL,
      dimensions = 'overworld'
    ))
  }
  .schema_error(
    release,
    paste0(path, '.test'),
    paste0('unsupported contextual test `', filter$test, '`')
  )
}

# Normalize contextual filter tree.
.filter_context <- function(filter, release, path) {
  if (is.null(filter)) {
    return(list(variants = NULL, dimensions = NULL))
  }
  if (!is.list(filter) || is.null(names(filter))) {
    .schema_error(release, path, 'expected a named filter object')
  }
  if ('test' %in% names(filter)) {
    return(.filter_leaf_context(filter, release, path))
  }
  if (identical(names(filter), 'all_of')) {
    .validate_array(filter$all_of, release, paste0(path, '.all_of'))
    context <- list(variants = NULL, dimensions = NULL)
    for (index in seq_along(filter$all_of)) {
      context <- .combine_context(
        context,
        .filter_context(
          filter$all_of[[index]],
          release,
          paste0(path, '.all_of[', index, ']')
        )
      )
    }
    return(context)
  }
  if (identical(names(filter), 'any_of')) {
    .validate_array(filter$any_of, release, paste0(path, '.any_of'))
    contexts <- lapply(seq_along(filter$any_of), function(index) {
      .filter_context(
        filter$any_of[[index]],
        release,
        paste0(path, '.any_of[', index, ']')
      )
    })
    has_variants <- vapply(
      contexts,
      function(context) !is.null(context$variants),
      logical(1)
    )
    has_dimensions <- vapply(
      contexts,
      function(context) !is.null(context$dimensions),
      logical(1)
    )
    if (all(has_variants) && !any(has_dimensions)) {
      return(list(
        variants   = unique(unlist(lapply(contexts, `[[`, 'variants'))),
        dimensions = NULL
      ))
    }
    if (all(has_dimensions) && !any(has_variants)) {
      return(list(
        variants   = NULL,
        dimensions = unique(unlist(lapply(contexts, `[[`, 'dimensions')))
      ))
    }
    .schema_error(
      release,
      path,
      'mixed-axis any-of filters cannot be flattened safely'
    )
  }
  .schema_error(
    release,
    path,
    'expected a supported test, all-of, or any-of filter'
  )
}

# Combine position and choice filters.
.choice_context <- function(position, choice, release, path) {
  .combine_context(
    .filter_context(
      position$filters,
      release,
      paste0(path, '.position_filters')
    ),
    .filter_context(
      choice$filters,
      release,
      paste0(path, '.choice_filters')
    )
  )
}

# Collapse contextual values.
.context_text <- function(values, release, path) {
  if (is.null(values)) {
    return(NA_character_)
  }
  if (!length(values)) {
    .schema_error(release, path, 'contextual filters have no common values')
  }
  paste(values, collapse = ', ')
}

# Item Helpers ------------------------------------------------------------------

# Create empty cost slot.
.empty_cost <- function(prefix) {
  values <- list(
    item             = NA_character_,
    aux_value        = NA_integer_,
    quantity_min     = NA_real_,
    quantity_max     = NA_real_,
    price_multiplier = NA_real_
  )
  names(values) <- paste0(prefix, '_', names(values))
  values
}

# Create populated cost slot.
.cost_slot <- function(choice, prefix) {
  if (is.null(choice)) {
    return(.empty_cost(prefix))
  }
  values <- list(
    item             = choice$item_id,
    aux_value        = choice$aux_value,
    quantity_min     = choice$quantity_min,
    quantity_max     = choice$quantity_max,
    price_multiplier = choice$price_multiplier
  )
  names(values) <- paste0(prefix, '_', names(values))
  values
}

# Combine position and choice functions.
.item_functions <- function(position, choice) {
  c(position$functions, choice$functions)
}

# Validate flat trade shape.
.validate_flat_shape <- function(candidate, release, path) {
  if (length(candidate$wants) > 2L) {
    .schema_error(
      release,
      paste0(path, '.wants'),
      'flat output supports at most two player costs'
    )
  }
  if (length(candidate$gives) != 1L) {
    .schema_error(
      release,
      paste0(path, '.gives'),
      'flat output requires exactly one result item'
    )
  }
  for (index in seq_along(candidate$wants)) {
    position <- candidate$wants[[index]]
    has_functions <- length(position$functions) > 0L ||
      any(vapply(
        position$choices,
        function(choice) length(choice$functions) > 0L,
        logical(1)
      ))
    if (has_functions) {
      .schema_error(
        release,
        paste0(path, '.wants[', index, '].functions'),
        'functions on player costs are not supported'
      )
    }
  }
  invisible(candidate)
}

# Enchantment Helpers -----------------------------------------------------------

# Validate pinned enchantment identifiers.
.validate_enchantment_registry <- function(release) {
  content  <- .fetch_pinned_file(.bedrock_enchantment_path)
  registry <- .parse_json(content, .bedrock_enchantment_path)
  .validate_keys(
    registry,
    required = c(
      'data_items',
      'module_type',
      'name',
      'vanilla_data_type'
    ),
    allowed = c(
      'data_items',
      'module_type',
      'name',
      'vanilla_data_type'
    ),
    release = release,
    path    = .bedrock_enchantment_path
  )
  .validate_array(
    registry$data_items,
    release,
    paste0(.bedrock_enchantment_path, '.data_items')
  )
  identifiers <- vapply(
    seq_along(registry$data_items),
    function(index) {
      entry <- registry$data_items[[index]]
      .validate_keys(
        entry,
        required = 'name',
        allowed  = c('name', 'value'),
        release  = release,
        path     = paste0(
          .bedrock_enchantment_path,
          '.data_items[',
          index,
          ']'
        )
      )
      identifier <- entry$value %||% entry$name
      if (
        length(identifier) != 1L ||
        !is.character(identifier) ||
        !startsWith(identifier, 'minecraft:')
      ) {
        .schema_error(
          release,
          paste0(
            .bedrock_enchantment_path,
            '.data_items[',
            index,
            ']'
          ),
          'expected one Minecraft enchantment identifier'
        )
      }
      sub('^minecraft:', '', identifier)
    },
    character(1)
  )
  expected <- c(
    .bedrock_enchantments$enchantment,
    .bedrock_special_enchantments
  )
  if (
    length(unique(identifiers)) != length(expected) ||
    !setequal(identifiers, expected)
  ) {
    .schema_error(
      release,
      .bedrock_enchantment_path,
      'enchantment registry differs from pinned model'
    )
  }
  invisible(TRUE)
}

# Calculate librarian emerald range.
.librarian_cost_range <- function(specification, level, treasure, release, path) {
  .validate_keys(
    specification,
    required = c(
      'function',
      'base_cost',
      'base_random_cost',
      'per_level_random_cost',
      'per_level_cost'
    ),
    allowed = c(
      'function',
      'base_cost',
      'base_random_cost',
      'per_level_random_cost',
      'per_level_cost'
    ),
    release = release,
    path    = path
  )
  parameter_names <- c(
    'base_cost',
    'base_random_cost',
    'per_level_random_cost',
    'per_level_cost'
  )
  for (parameter in parameter_names) {
    .validate_number(
      specification[[parameter]],
      release,
      paste0(path, '.', parameter)
    )
    if (
      specification[[parameter]] < 0 ||
      specification[[parameter]] != floor(specification[[parameter]])
    ) {
      .schema_error(
        release,
        paste0(path, '.', parameter),
        'expected a nonnegative integer'
      )
    }
  }
  minimum <- specification$base_cost +
    level * specification$per_level_cost
  maximum <- minimum +
    specification$base_random_cost +
    level * specification$per_level_random_cost -
    1
  if (treasure) {
    minimum <- minimum * 2
    maximum <- maximum * 2
  }
  c(
    minimum = min(minimum, 64),
    maximum = min(maximum, 64)
  )
}

# Generator Helpers -------------------------------------------------------------

# Create base option row.
.base_option_row <- function(
  table,
  level,
  group,
  candidate,
  source_option,
  wants_1,
  wants_2,
  gives_1,
  context
) {
  result_functions <- .item_functions(
    candidate$gives[[1L]],
    gives_1
  )
  values <- c(
    list(
      profession            = table$profession,
      level                 = level$level,
      level_name            = level$level_name,
      total_exp_required    = level$total_exp_required,
      group_id              = group$group_id,
      trade_id              = candidate$candidate_id,
      option_id             = NA_character_,
      trades_in_group       = group$candidate_count,
      trades_selected       = if (group$select_all) {
        group$candidate_count
      } else {
        group$num_to_select
      },
      all_trades_selected   = group$select_all,
      variants              = .context_text(
        context$variants,
        .pinned_release(),
        paste0(candidate$candidate_id, '.variants')
      ),
      dimensions            = .context_text(
        context$dimensions,
        .pinned_release(),
        paste0(candidate$candidate_id, '.dimensions')
      )
    ),
    .cost_slot(wants_1, 'cost_1'),
    .cost_slot(wants_2, 'cost_2'),
    list(
      result_item           = gives_1$item_id,
      result_aux_value      = gives_1$aux_value,
      result_quantity_min   = gives_1$quantity_min,
      result_quantity_max   = gives_1$quantity_max,
      result_color          = NA_character_,
      result_effect         = NA_character_,
      potion                = NA_character_,
      map_destination       = NA_character_,
      enchantment           = NA_character_,
      enchantment_name      = NA_character_,
      enchantment_level     = NA_integer_,
      enchantment_max_level = NA_integer_,
      treasure              = NA,
      generator             = if (length(result_functions)) {
        result_functions[[1L]][['function']]
      } else {
        NA_character_
      },
      enchanting_power_min  = NA_real_,
      enchanting_power_max  = NA_real_,
      outcome_status        = 'source_resolved',
      max_uses              = candidate$max_uses,
      villager_exp          = candidate$trader_exp,
      player_exp            = candidate$reward_exp,
      .source_option        = source_option,
      .selection_probability = if (group$select_all) {
        1
      } else {
        group$num_to_select / group$candidate_count
      },
      .choice_probability   = 1 /
        (
          length(candidate$wants[[1L]]$choices) *
          if (length(candidate$wants) == 2L) {
            length(candidate$wants[[2L]]$choices)
          } else {
            1L
          } *
          length(candidate$gives[[1L]]$choices)
        ),
      .generator_probability = 1,
      .probability_status   = 'exact',
      .probability_basis    = 'source_trade_table'
    )
  )
  as.data.frame(
    values,
    optional         = TRUE,
    stringsAsFactors = FALSE
  )
}

# Expand random auxiliary values.
.expand_random_aux <- function(row, specification, release, path) {
  .validate_keys(
    specification,
    required = c('function', 'values'),
    allowed  = c('function', 'values'),
    release  = release,
    path     = path
  )
  values <- specification$values
  .validate_keys(
    values,
    required = c('min', 'max'),
    allowed  = c('min', 'max'),
    release  = release,
    path     = paste0(path, '.values')
  )
  .validate_number(values$min, release, paste0(path, '.values.min'))
  .validate_number(values$max, release, paste0(path, '.values.max'))
  if (
    values$min != floor(values$min) ||
    values$max != floor(values$max) ||
    values$max < values$min
  ) {
    .schema_error(
      release,
      paste0(path, '.values'),
      'expected an ordered integer range'
    )
  }
  auxiliary_values <- seq.int(values$min, values$max)
  rows <- lapply(auxiliary_values, function(auxiliary_value) {
    output <- row
    output$result_aux_value <- as.integer(auxiliary_value)
    if (output$result_item %in% c('minecraft:bed', 'minecraft:banner')) {
      if (!(auxiliary_value %in% 0:15)) {
        .schema_error(
          release,
          paste0(path, '.values'),
          'bed and banner colors require auxiliary values from 0 through 15'
        )
      }
      output$result_color <- .bedrock_colors[[auxiliary_value + 1L]]
    }
    if (identical(output$result_item, 'minecraft:suspicious_stew')) {
      if (!(auxiliary_value %in% 0:5)) {
        .schema_error(
          release,
          paste0(path, '.values'),
          'suspicious stew effects require values from 0 through 5'
        )
      }
      output$result_effect <- .bedrock_stew_effects[[auxiliary_value + 1L]]
    }
    output$.generator_probability <- 1 / length(auxiliary_values)
    output
  })
  do.call(rbind, rows)
}

# Expand librarian enchantments.
.expand_librarian_enchantments <- function(
  row,
  specification,
  release,
  path
) {
  if (
    !identical(row$cost_1_item, 'minecraft:emerald') ||
    !identical(row$cost_2_item, 'minecraft:book') ||
    !identical(row$result_item, 'minecraft:book')
  ) {
    .schema_error(
      release,
      path,
      'librarian model requires emeralds, a book, and a book result'
    )
  }
  rows  <- list()
  row_n <- 0L
  enchantment_count <- nrow(.bedrock_enchantments)
  for (index in seq_len(enchantment_count)) {
    enchantment <- .bedrock_enchantments[index, , drop = FALSE]
    for (enchantment_level in seq_len(enchantment$max_level)) {
      row_n <- row_n + 1L
      output <- row
      cost <- .librarian_cost_range(
        specification,
        enchantment_level,
        enchantment$treasure,
        release,
        path
      )
      output$cost_1_quantity_min <- unname(cost[['minimum']])
      output$cost_1_quantity_max <- unname(cost[['maximum']])
      output$result_item <- 'minecraft:enchanted_book'
      output$enchantment <- enchantment$enchantment
      output$enchantment_name <- enchantment$enchantment_name
      output$enchantment_level <- as.integer(enchantment_level)
      output$enchantment_max_level <- enchantment$max_level
      output$treasure <- enchantment$treasure
      output$outcome_status <- 'documented_model'
      output$.generator_probability <-
        1 / enchantment_count / enchantment$max_level
      output$.probability_status <- 'documented_model'
      output$.probability_basis <- 'minecraft_wiki_librarian_model'
      rows[[row_n]] <- output
    }
  }
  do.call(rbind, rows)
}

# Resolve item generator.
.expand_generator <- function(row, functions, release, path) {
  if (!length(functions)) {
    return(row)
  }
  if (length(functions) != 1L) {
    .schema_error(
      release,
      path,
      'flat output supports one result function per item'
    )
  }
  specification <- functions[[1L]]
  generator <- specification[['function']]
  if (identical(generator, 'random_aux_value')) {
    return(.expand_random_aux(row, specification, release, path))
  }
  if (identical(generator, 'enchant_book_for_trading')) {
    return(.expand_librarian_enchantments(
      row,
      specification,
      release,
      path
    ))
  }
  if (identical(generator, 'set_potion')) {
    .validate_keys(
      specification,
      required = c('function', 'id'),
      allowed  = c('function', 'id'),
      release  = release,
      path     = path
    )
    row$potion <- specification$id
    return(row)
  }
  if (identical(generator, 'exploration_map')) {
    .validate_keys(
      specification,
      required = c('function', 'destination'),
      allowed  = c('function', 'destination'),
      release  = release,
      path     = path
    )
    row$map_destination <- specification$destination
    return(row)
  }
  if (identical(generator, 'enchant_with_levels')) {
    .validate_keys(
      specification,
      required = c('function', 'treasure', 'levels'),
      allowed  = c('function', 'treasure', 'levels'),
      release  = release,
      path     = path
    )
    .validate_logical(
      specification$treasure,
      release,
      paste0(path, '.treasure')
    )
    .validate_keys(
      specification$levels,
      required = c('min', 'max'),
      allowed  = c('min', 'max'),
      release  = release,
      path     = paste0(path, '.levels')
    )
    .validate_number(
      specification$levels$min,
      release,
      paste0(path, '.levels.min')
    )
    .validate_number(
      specification$levels$max,
      release,
      paste0(path, '.levels.max')
    )
    row$treasure <- specification$treasure
    row$enchanting_power_min <- specification$levels$min
    row$enchanting_power_max <- specification$levels$max
    row$outcome_status <- 'engine_generated'
    row$.probability_status <- 'partial'
    row$.probability_basis <- 'source_trade_table_engine_generated'
    return(row)
  }
  if (identical(generator, 'random_dye')) {
    .validate_keys(
      specification,
      required = 'function',
      allowed  = 'function',
      release  = release,
      path     = path
    )
    row$outcome_status <- 'engine_generated'
    row$.probability_status <- 'partial'
    row$.probability_basis <- 'source_trade_table_engine_generated'
    return(row)
  }
  .schema_error(
    release,
    path,
    paste0('unsupported result function `', generator, '`')
  )
}

# Flattening Helpers ------------------------------------------------------------

# Build one source option.
.source_option_rows <- function(
  table,
  level,
  group,
  candidate,
  source_option,
  wants_1,
  wants_2,
  gives_1,
  release,
  path
) {
  contexts <- list(
    .choice_context(
      candidate$wants[[1L]],
      wants_1,
      release,
      paste0(path, '.wants[1]')
    ),
    if (length(candidate$wants) == 2L) {
      .choice_context(
        candidate$wants[[2L]],
        wants_2,
        release,
        paste0(path, '.wants[2]')
      )
    } else {
      list(variants = NULL, dimensions = NULL)
    },
    .choice_context(
      candidate$gives[[1L]],
      gives_1,
      release,
      paste0(path, '.gives[1]')
    )
  )
  context <- list(variants = NULL, dimensions = NULL)
  for (value in contexts) {
    context <- .combine_context(context, value)
  }
  row <- .base_option_row(
    table         = table,
    level         = level,
    group         = group,
    candidate     = candidate,
    source_option = source_option,
    wants_1       = wants_1,
    wants_2       = wants_2,
    gives_1       = gives_1,
    context       = context
  )
  .expand_generator(
    row,
    .item_functions(candidate$gives[[1L]], gives_1),
    release,
    paste0(path, '.gives[1].functions')
  )
}

# Flatten profession table.
.flatten_trade_table <- function(table, release, selected_levels = NULL) {
  rows  <- list()
  row_n <- 0L
  levels <- table$levels
  if (!is.null(selected_levels)) {
    levels <- levels[vapply(
      levels,
      function(level) level$level %in% selected_levels,
      logical(1)
    )]
  }
  for (level in levels) {
    for (group in level$groups) {
      for (candidate in group$candidates) {
        path <- paste0(
          table$profession,
          '.levels[',
          level$level,
          '].',
          group$group_id,
          '.',
          candidate$candidate_id
        )
        .validate_flat_shape(candidate, release, path)
        wants_1_choices <- candidate$wants[[1L]]$choices
        wants_2_choices <- if (length(candidate$wants) == 2L) {
          candidate$wants[[2L]]$choices
        } else {
          list(NULL)
        }
        gives_1_choices <- candidate$gives[[1L]]$choices
        source_option <- 0L
        candidate_rows <- list()
        candidate_row_n <- 0L
        for (wants_1 in wants_1_choices) {
          for (wants_2 in wants_2_choices) {
            for (gives_1 in gives_1_choices) {
              source_option <- source_option + 1L
              expanded <- .source_option_rows(
                table         = table,
                level         = level,
                group         = group,
                candidate     = candidate,
                source_option = source_option,
                wants_1       = wants_1,
                wants_2       = wants_2,
                gives_1       = gives_1,
                release       = release,
                path          = path
              )
              for (index in seq_len(nrow(expanded))) {
                candidate_row_n <- candidate_row_n + 1L
                candidate_rows[[candidate_row_n]] <- expanded[
                  index,
                  ,
                  drop = FALSE
                ]
              }
            }
          }
        }
        candidate_result <- do.call(rbind, candidate_rows)
        candidate_result$option_id <- paste0(
          candidate$candidate_id,
          '_o',
          seq_len(nrow(candidate_result))
        )
        row_n <- row_n + 1L
        rows[[row_n]] <- candidate_result
      }
    }
  }
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}
