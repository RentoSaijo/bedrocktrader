# Flattening Helpers ------------------------------------------------------------

# Serialize function details.
.function_details <- function(position, choice) {
  functions <- c(position$functions, choice$functions)
  if (!length(functions)) {
    return(list(
      functions           = NA_character_,
      function_parameters = NA_character_
    ))
  }
  function_names <- vapply(
    functions,
    function(value) value[['function']],
    character(1)
  )
  parameters <- lapply(functions, function(value) {
    value[setdiff(names(value), 'function')]
  })
  list(
    functions           = paste(function_names, collapse = ', '),
    function_parameters = as.character(jsonlite::toJSON(
      parameters,
      auto_unbox = TRUE,
      null       = 'null',
      digits     = NA
    ))
  )
}

# Serialize filter details.
.filter_details <- function(position, choice) {
  filters <- list()
  if (!is.null(position$filters)) {
    filters$position <- position$filters
  }
  if (!is.null(choice$filters)) {
    filters$choice <- choice$filters
  }
  if (!length(filters)) {
    return(NA_character_)
  }
  as.character(jsonlite::toJSON(
    filters,
    auto_unbox = TRUE,
    null       = 'null',
    digits     = NA
  ))
}

# Create empty item slot.
.empty_slot <- function(prefix) {
  values <- list(
    item_raw            = NA_character_,
    item                = NA_character_,
    aux_value           = NA_integer_,
    quantity_min        = NA_real_,
    quantity_max        = NA_real_,
    price_multiplier    = NA_real_,
    functions           = NA_character_,
    function_parameters = NA_character_,
    filters             = NA_character_
  )
  names(values) <- paste0(prefix, '_', names(values))
  values
}

# Create populated item slot.
.item_slot <- function(position, choice, prefix) {
  if (is.null(position) || is.null(choice)) {
    return(.empty_slot(prefix))
  }
  function_details <- .function_details(position, choice)
  values <- list(
    item_raw            = choice$item_id_raw,
    item                = choice$item_id,
    aux_value           = choice$aux_value,
    quantity_min        = choice$quantity_min,
    quantity_max        = choice$quantity_max,
    price_multiplier    = choice$price_multiplier,
    functions           = function_details$functions,
    function_parameters = function_details$function_parameters,
    filters             = .filter_details(position, choice)
  )
  names(values) <- paste0(prefix, '_', names(values))
  values
}

# Validate flat trade shape.
.validate_flat_shape <- function(candidate, release, path) {
  if (length(candidate$wants) > 2L) {
    .schema_error(
      release,
      paste0(path, '.wants'),
      'flat output supports at most two wanted items'
    )
  }
  if (length(candidate$gives) != 1L) {
    .schema_error(
      release,
      paste0(path, '.gives'),
      'flat output requires exactly one given item'
    )
  }
  invisible(candidate)
}

# Create option row.
.option_row <- function(
  table,
  level,
  group,
  candidate,
  option_position,
  wants_1,
  wants_2,
  gives_1
) {
  values <- c(
    list(
      profession         = table$profession,
      level              = level$level,
      level_name         = level$level_name,
      total_exp_required = level$total_exp_required,
      group_id           = group$group_id,
      candidate_id       = candidate$candidate_id,
      option_id          = paste0(
        candidate$candidate_id,
        '_o',
        option_position
      ),
      candidate_count    = group$candidate_count,
      num_to_select      = group$num_to_select,
      select_all         = group$select_all,
      max_uses           = candidate$max_uses,
      trader_exp         = candidate$trader_exp,
      reward_exp         = candidate$reward_exp
    ),
    .item_slot(
      position = candidate$wants[[1L]],
      choice   = wants_1,
      prefix   = 'wants_1'
    ),
    .item_slot(
      position = if (length(candidate$wants) == 2L) {
        candidate$wants[[2L]]
      } else {
        NULL
      },
      choice = wants_2,
      prefix = 'wants_2'
    ),
    .item_slot(
      position = candidate$gives[[1L]],
      choice   = gives_1,
      prefix   = 'gives_1'
    )
  )
  as.data.frame(
    values,
    optional         = TRUE,
    stringsAsFactors = FALSE
  )
}

# Flatten profession table.
.flatten_trade_table <- function(table, release) {
  rows  <- list()
  row_n <- 0L
  for (level in table$levels) {
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
        option_position <- 0L
        for (wants_1 in wants_1_choices) {
          for (wants_2 in wants_2_choices) {
            for (gives_1 in gives_1_choices) {
              row_n <- row_n + 1L
              option_position <- option_position + 1L
              rows[[row_n]] <- .option_row(
                table           = table,
                level           = level,
                group           = group,
                candidate       = candidate,
                option_position = option_position,
                wants_1         = wants_1,
                wants_2         = wants_2,
                gives_1         = gives_1
              )
            }
          }
        }
      }
    }
  }
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}
