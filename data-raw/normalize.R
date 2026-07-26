# Schema Helpers ----------------------------------------------------------------

# Report unsupported source structure.
.schema_error <- function(release, path, message) {
  stop(
    'Unsupported Mojang trade structure in release `',
    release$bedrock_version,
    '` at `',
    path,
    '`: ',
    message,
    '.',
    call. = FALSE
  )
}

# Validate object keys.
.validate_keys <- function(x, required, allowed, release, path) {
  if (!is.list(x) || is.null(names(x))) {
    .schema_error(release, path, 'expected a named object')
  }
  missing_keys <- setdiff(required, names(x))
  unknown_keys <- setdiff(names(x), allowed)
  if (length(missing_keys)) {
    .schema_error(
      release,
      path,
      paste0('missing `', missing_keys[[1L]], '`')
    )
  }
  if (length(unknown_keys)) {
    .schema_error(
      release,
      paste0(path, '.', unknown_keys[[1L]]),
      'field is not supported by parser model 1'
    )
  }
  invisible(x)
}

# Validate scalar number.
.validate_number <- function(x, release, path, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(x))
  }
  if (length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x)) {
    .schema_error(release, path, 'expected one finite number')
  }
  invisible(x)
}

# Validate scalar logical value.
.validate_logical <- function(x, release, path, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(x))
  }
  if (length(x) != 1L || !is.logical(x) || is.na(x)) {
    .schema_error(release, path, 'expected one logical value')
  }
  invisible(x)
}

# Validate array value.
.validate_array <- function(x, release, path) {
  if (!is.list(x) || !length(x) || !is.null(names(x))) {
    .schema_error(release, path, 'expected a nonempty array')
  }
  invisible(x)
}

# Normalize optional number.
.optional_number <- function(x, release, path) {
  if (is.null(x)) {
    return(NA_real_)
  }
  .validate_number(x, release, path)
  as.numeric(x)
}

# Normalize optional logical value.
.optional_logical <- function(x, release, path) {
  if (is.null(x)) {
    return(NA)
  }
  .validate_logical(x, release, path)
  x
}

# Item Helpers ------------------------------------------------------------------

# Normalize item identifier.
.normalize_item_id <- function(item_id_raw) {
  match <- regexec('^(.+):(-?[0-9]+)$', item_id_raw)
  parts <- regmatches(item_id_raw, match)[[1L]]
  if (length(parts) == 3L) {
    return(list(
      item_id  = parts[[2L]],
      aux_value = as.integer(parts[[3L]])
    ))
  }
  list(
    item_id  = item_id_raw,
    aux_value = NA_integer_
  )
}

# Normalize item quantity.
.normalize_quantity <- function(quantity, release, path) {
  if (is.null(quantity)) {
    return(list(
      quantity_min      = 1,
      quantity_max      = 1,
      quantity_explicit = FALSE
    ))
  }
  if (is.numeric(quantity)) {
    .validate_number(quantity, release, path)
    if (quantity < 0 || quantity != floor(quantity)) {
      .schema_error(release, path, 'quantity must be a nonnegative integer')
    }
    return(list(
      quantity_min      = as.numeric(quantity),
      quantity_max      = as.numeric(quantity),
      quantity_explicit = TRUE
    ))
  }
  .validate_keys(
    quantity,
    required = c('min', 'max'),
    allowed  = c('min', 'max'),
    release  = release,
    path     = path
  )
  .validate_number(quantity$min, release, paste0(path, '.min'))
  .validate_number(quantity$max, release, paste0(path, '.max'))
  if (
    quantity$min < 0 ||
    quantity$max < quantity$min ||
    quantity$min != floor(quantity$min) ||
    quantity$max != floor(quantity$max)
  ) {
    .schema_error(
      release,
      path,
      'quantity range must contain ordered nonnegative integers'
    )
  }
  list(
    quantity_min      = as.numeric(quantity$min),
    quantity_max      = as.numeric(quantity$max),
    quantity_explicit = TRUE
  )
}

# Normalize item functions.
.normalize_functions <- function(functions, release, path) {
  if (is.null(functions)) {
    return(list())
  }
  if (!is.list(functions) || !is.null(names(functions))) {
    .schema_error(release, path, 'expected a function array')
  }
  for (index in seq_along(functions)) {
    function_path <- paste0(path, '[', index, ']')
    value <- functions[[index]]
    if (
      !is.list(value) ||
      is.null(value[['function']]) ||
      length(value[['function']]) != 1L ||
      !is.character(value[['function']]) ||
      !nzchar(value[['function']])
    ) {
      .schema_error(
        release,
        function_path,
        'expected an object with a function name'
      )
    }
  }
  functions
}

# Normalize item choice.
.normalize_choice <- function(
  choice,
  choice_id,
  release,
  path
) {
  .validate_keys(
    choice,
    required = 'item',
    allowed  = c(
      'item',
      'quantity',
      'price_multiplier',
      'functions',
      'filters'
    ),
    release = release,
    path    = path
  )
  if (
    length(choice$item) != 1L ||
    !is.character(choice$item) ||
    !nzchar(choice$item)
  ) {
    .schema_error(release, paste0(path, '.item'), 'expected one item identifier')
  }
  quantity <- .normalize_quantity(
    choice$quantity,
    release,
    paste0(path, '.quantity')
  )
  item <- .normalize_item_id(choice$item)
  list(
    choice_id         = choice_id,
    item_id_raw       = choice$item,
    item_id           = item$item_id,
    aux_value         = item$aux_value,
    quantity_min      = quantity$quantity_min,
    quantity_max      = quantity$quantity_max,
    quantity_explicit = quantity$quantity_explicit,
    price_multiplier  = .optional_number(
      choice$price_multiplier,
      release,
      paste0(path, '.price_multiplier')
    ),
    functions         = .normalize_functions(
      choice$functions,
      release,
      paste0(path, '.functions')
    ),
    filters           = choice$filters %||% NULL
  )
}

# Normalize item position.
.normalize_item_position <- function(
  item,
  candidate_id,
  side,
  item_position,
  release,
  path
) {
  .validate_keys(
    item,
    required = character(),
    allowed  = c(
      'choice',
      'item',
      'quantity',
      'price_multiplier',
      'functions',
      'filters'
    ),
    release = release,
    path    = path
  )
  has_choice <- !is.null(item$choice)
  has_item   <- !is.null(item$item)
  if (identical(has_choice, has_item)) {
    .schema_error(
      release,
      path,
      'expected exactly one of `item` or `choice`'
    )
  }
  position_id <- paste0(
    candidate_id,
    '_',
    substr(side, 1L, 1L),
    item_position
  )
  if (has_choice) {
    .validate_array(item$choice, release, paste0(path, '.choice'))
    choices <- lapply(seq_along(item$choice), function(choice_position) {
      .normalize_choice(
        choice    = item$choice[[choice_position]],
        choice_id = paste0(position_id, '_ch', choice_position),
        release   = release,
        path      = paste0(path, '.choice[', choice_position, ']')
      )
    })
  } else {
    choices <- list(
      .normalize_choice(
        choice    = item,
        choice_id = paste0(position_id, '_ch1'),
        release   = release,
        path      = path
      )
    )
  }
  list(
    item_position = item_position,
    position_id   = position_id,
    side          = side,
    has_choice    = has_choice,
    functions     = if (has_choice) {
      .normalize_functions(
        item$functions,
        release,
        paste0(path, '.functions')
      )
    } else {
      list()
    },
    filters       = if (has_choice) item$filters %||% NULL else NULL,
    choices       = choices
  )
}

# Normalize trade side.
.normalize_trade_side <- function(items, candidate_id, side, release, path) {
  .validate_array(items, release, path)
  lapply(seq_along(items), function(item_position) {
    .normalize_item_position(
      item          = items[[item_position]],
      candidate_id  = candidate_id,
      side          = side,
      item_position = item_position,
      release       = release,
      path          = paste0(path, '[', item_position, ']')
    )
  })
}

# Trade Helpers -----------------------------------------------------------------

# Normalize trade candidate.
.normalize_candidate <- function(
  candidate,
  profession,
  level,
  group,
  candidate_position,
  release,
  path
) {
  .validate_keys(
    candidate,
    required = c('wants', 'gives'),
    allowed  = c(
      'wants',
      'gives',
      'max_uses',
      'trader_exp',
      'reward_exp'
    ),
    release = release,
    path    = path
  )
  candidate_id <- paste0(
    profession,
    '_l',
    level,
    '_g',
    group,
    '_c',
    candidate_position
  )
  list(
    candidate_position = candidate_position,
    candidate_id       = candidate_id,
    wants              = .normalize_trade_side(
      candidate$wants,
      candidate_id,
      'wants',
      release,
      paste0(path, '.wants')
    ),
    gives              = .normalize_trade_side(
      candidate$gives,
      candidate_id,
      'gives',
      release,
      paste0(path, '.gives')
    ),
    max_uses           = .optional_number(
      candidate$max_uses,
      release,
      paste0(path, '.max_uses')
    ),
    trader_exp         = .optional_number(
      candidate$trader_exp,
      release,
      paste0(path, '.trader_exp')
    ),
    reward_exp         = .optional_logical(
      candidate$reward_exp,
      release,
      paste0(path, '.reward_exp')
    )
  )
}

# Normalize trade group.
.normalize_group <- function(group, profession, level, group_position, release, path) {
  .validate_keys(
    group,
    required = 'trades',
    allowed  = c('num_to_select', 'trades'),
    release  = release,
    path     = path
  )
  .validate_array(group$trades, release, paste0(path, '.trades'))
  candidate_count <- length(group$trades)
  num_to_select_explicit <- !is.null(group$num_to_select)
  if (num_to_select_explicit) {
    .validate_number(
      group$num_to_select,
      release,
      paste0(path, '.num_to_select')
    )
  }
  num_to_select <- as.integer(group$num_to_select %||% -1L)
  if (
    (num_to_select_explicit && group$num_to_select != num_to_select) ||
    !(num_to_select == -1L ||
      (num_to_select >= 1L && num_to_select <= candidate_count))
  ) {
    .schema_error(
      release,
      paste0(path, '.num_to_select'),
      'expected -1 or an integer from 1 through candidate count'
    )
  }
  group_id <- paste0(profession, '_l', level, '_g', group_position)
  candidates <- lapply(seq_along(group$trades), function(candidate_position) {
    .normalize_candidate(
      candidate          = group$trades[[candidate_position]],
      profession         = profession,
      level              = level,
      group              = group_position,
      candidate_position = candidate_position,
      release            = release,
      path               = paste0(path, '.trades[', candidate_position, ']')
    )
  })
  list(
    group_position  = group_position,
    group_id        = group_id,
    num_to_select   = num_to_select,
    num_to_select_explicit = num_to_select_explicit,
    select_all      = num_to_select == -1L,
    candidate_count = candidate_count,
    candidates      = candidates
  )
}

# Normalize villager level.
.normalize_level <- function(tier, profession, level, release, path) {
  .validate_keys(
    tier,
    required = c('groups', 'total_exp_required'),
    allowed  = c('groups', 'total_exp_required'),
    release  = release,
    path     = path
  )
  .validate_number(
    tier$total_exp_required,
    release,
    paste0(path, '.total_exp_required')
  )
  .validate_array(tier$groups, release, paste0(path, '.groups'))
  groups <- lapply(seq_along(tier$groups), function(group_position) {
    .normalize_group(
      group          = tier$groups[[group_position]],
      profession     = profession,
      level          = level,
      group_position = group_position,
      release        = release,
      path            = paste0(path, '.groups[', group_position, ']')
    )
  })
  list(
    level              = level,
    level_name         = .bedrock_level_names[[level]],
    total_exp_required = as.numeric(tier$total_exp_required),
    groups             = groups
  )
}

# Normalize profession table.
.normalize_trade_table <- function(table, profession, release, source_path) {
  .validate_keys(
    table,
    required = 'tiers',
    allowed  = c('format_version', 'tiers'),
    release  = release,
    path     = source_path
  )
  .validate_array(table$tiers, release, paste0(source_path, '.tiers'))
  if (length(table$tiers) != length(.bedrock_level_names)) {
    .schema_error(
      release,
      paste0(source_path, '.tiers'),
      'expected exactly five villager levels'
    )
  }
  levels <- lapply(seq_along(table$tiers), function(level) {
    .normalize_level(
      tier       = table$tiers[[level]],
      profession = profession,
      level      = level,
      release    = release,
      path       = paste0(source_path, '.tiers[', level, ']')
    )
  })
  display_name <- .bedrock_professions$display_name[
    match(profession, .bedrock_professions$profession)
  ]
  list(
    profession          = profession,
    display_name        = display_name,
    source_format_version = table$format_version %||% NA_character_,
    levels              = levels
  )
}

# Variant Helpers ---------------------------------------------------------------

# Extract variant values.
.normalize_variants <- function(entity, release) {
  root <- entity[['minecraft:entity']]
  if (!is.list(root)) {
    .schema_error(
      release,
      .bedrock_variant_path,
      'missing `minecraft:entity` object'
    )
  }
  components       <- root$components
  component_groups <- root$component_groups
  if (!is.list(components) || !is.list(component_groups)) {
    .schema_error(
      release,
      .bedrock_variant_path,
      'missing villager components or component groups'
    )
  }
  values <- integer(length(.bedrock_variants))
  values[[1L]] <- components[['minecraft:mark_variant']]$value %||% NA_real_
  for (index in seq.int(2L, length(.bedrock_variants))) {
    variant <- .bedrock_variants[[index]]
    group   <- component_groups[[paste0(variant, '_villager')]]
    values[[index]] <- group[['minecraft:mark_variant']]$value %||% NA_real_
  }
  if (
    anyNA(values) ||
    any(values != floor(values)) ||
    anyDuplicated(values)
  ) {
    .schema_error(
      release,
      .bedrock_variant_path,
      'villager mark-variant values are incomplete or invalid'
    )
  }
  values
}
