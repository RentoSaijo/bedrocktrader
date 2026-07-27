# Context Helpers ---------------------------------------------------------------

# Normalize variant input.
.normalize_variant_input <- function(variant) {
  if (is.null(variant)) {
    return(NULL)
  }
  if (
    length(variant) != 1L ||
    is.na(variant) ||
    !is.character(variant) ||
    !nzchar(variant)
  ) {
    stop('`variant` must be one nonempty character value.', call. = FALSE)
  }
  value <- tolower(trimws(variant))
  for (canonical in names(.bedrock_variant_aliases)) {
    if (value %in% c(canonical, .bedrock_variant_aliases[[canonical]])) {
      return(canonical)
    }
  }
  stop(
    'Unsupported villager variant `',
    variant,
    '`. Use `villager_variants()` to inspect supported values.',
    call. = FALSE
  )
}

# Normalize dimension input.
.normalize_dimension_input <- function(dimension) {
  if (is.null(dimension)) {
    return(NULL)
  }
  if (
    length(dimension) != 1L ||
    is.na(dimension) ||
    !is.character(dimension) ||
    !nzchar(dimension)
  ) {
    stop('`dimension` must be one nonempty character value.', call. = FALSE)
  }
  value      <- tolower(trimws(dimension))
  dimensions <- c('overworld', 'nether', 'end')
  if (!(value %in% dimensions)) {
    stop(
      '`dimension` must be overworld, nether, or end.',
      call. = FALSE
    )
  }
  value
}

# Check contextual value.
.context_applies <- function(restriction, value) {
  unrestricted <- is.na(restriction)
  if (is.null(value)) {
    return(unrestricted)
  }
  allowed <- strsplit(restriction, ', ', fixed = TRUE)
  unrestricted | vapply(
    allowed,
    function(values) value %in% values,
    logical(1)
  )
}

# Require context needed by trades.
.require_trade_context <- function(rows, variant, dimension) {
  missing_context <- character()
  if (is.null(variant) && any(!is.na(rows$.variants))) {
    missing_context <- c(missing_context, '`variant`')
  }
  if (is.null(dimension) && any(!is.na(rows$.dimensions))) {
    missing_context <- c(missing_context, '`dimension`')
  }
  if (length(missing_context)) {
    stop(
      paste(missing_context, collapse = ' and '),
      if (length(missing_context) == 1L) ' is' else ' are',
      ' required because this profession has context-dependent trades.',
      call. = FALSE
    )
  }
  invisible(rows)
}

# Probability Helpers -----------------------------------------------------------

# Calculate context-specific trade probabilities.
.trade_probabilities <- function(rows) {
  probabilities <- numeric(nrow(rows))
  for (group_id in unique(rows$group_id)) {
    group_rows <- which(rows$group_id == group_id)
    trade_ids <- unique(rows$trade_id[group_rows])
    trade_weights <- vapply(
      trade_ids,
      function(trade_id) {
        unique(rows$.trade_weight[
          group_rows[rows$trade_id[group_rows] == trade_id]
        ])
      },
      numeric(1)
    )
    num_trades <- sum(trade_weights)
    num_to_select <- rows$num_to_select[[group_rows[[1L]]]]
    if (num_to_select == -1L) {
      probabilities[group_rows] <- 1
    } else {
      selected_n <- min(num_to_select, num_trades)
      for (index in seq_along(trade_ids)) {
        trade_id     <- trade_ids[[index]]
        trade_weight <- trade_weights[[index]]
        not_selected <- if (num_trades - trade_weight < selected_n) {
          0
        } else {
          choose(num_trades - trade_weight, selected_n) /
            choose(num_trades, selected_n)
        }
        probabilities[
          group_rows[rows$trade_id[group_rows] == trade_id]
        ] <- 1 - not_selected
      }
    }
  }
  probabilities
}

# Calculate context-specific choice probabilities.
.choice_probabilities <- function(rows) {
  probabilities <- numeric(nrow(rows))
  for (trade_id in unique(rows$trade_id)) {
    trade_rows <- which(rows$trade_id == trade_id)
    choice_count <- length(unique(rows$.source_option[trade_rows]))
    probabilities[trade_rows] <- 1 / choice_count
  }
  probabilities
}
