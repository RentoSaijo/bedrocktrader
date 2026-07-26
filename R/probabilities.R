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

# Require context needed by rows.
.require_probability_context <- function(rows, variant, dimension) {
  if (is.null(variant) && any(!is.na(rows$variants))) {
    stop(
      '`variant` is required because the requested offers depend on ',
      'villager variant.',
      call. = FALSE
    )
  }
  if (is.null(dimension) && any(!is.na(rows$dimensions))) {
    stop(
      '`dimension` is required because the requested offers depend on ',
      'dimension.',
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
    num_trades <- length(unique(rows$trade_id[group_rows]))
    if (isTRUE(rows$select_all[[group_rows[[1L]]]])) {
      probability <- 1
    } else {
      num_to_select <- rows$num_to_select[[group_rows[[1L]]]]
      probability   <- min(num_to_select, num_trades) / num_trades
    }
    probabilities[group_rows] <- probability
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

# Public Functions --------------------------------------------------------------

#' Calculate Villager Offer Probabilities
#'
#' Calculates the marginal probability that each possible trade outcome appears
#' among a Minecraft Bedrock `1.26.30.5` villager's offers.
#'
#' @param profession One profession or documented alias.
#' @param tier One tier given as a number from 1 through 5 or tier name.
#' @param scope `"tier"` for the selected tier or `"unlocked"` for that tier
#'   and every earlier tier.
#' @param variant Villager variant when required by contextual trades.
#' @param dimension Dimension when required: `"overworld"`, `"nether"`, or
#'   `"end"`.
#'
#' @return The applicable trade columns with trade, choice, function, and
#'   overall offer probabilities appended.
#' @export
offer_probabilities <- function(
  profession = 'armorer',
  tier = 'novice',
  scope = c('tier', 'unlocked'),
  variant = NULL,
  dimension = NULL
) {
  profession <- .normalize_profession_input(profession)
  tier       <- .normalize_tier_input(tier, allow_null = FALSE)
  scope      <- match.arg(scope)
  variant    <- .normalize_variant_input(variant)
  dimension  <- .normalize_dimension_input(dimension)
  selected_tiers <- if (identical(scope, 'tier')) tier else seq_len(tier)
  keep <- .bedrock_trade_outcomes$profession == profession &
    .bedrock_trade_outcomes$tier %in% selected_tiers
  rows <- .bedrock_trade_outcomes[keep, , drop = FALSE]
  .require_probability_context(rows, variant, dimension)
  keep <- .context_applies(rows$variants, variant) &
    .context_applies(rows$dimensions, dimension)
  rows <- rows[keep, , drop = FALSE]
  if (!nrow(rows)) {
    stop(
      'No offers apply to the requested villager context.',
      call. = FALSE
    )
  }
  rows$trade_probability    <- .trade_probabilities(rows)
  rows$choice_probability   <- .choice_probabilities(rows)
  rows$function_probability <- rows$.function_probability
  rows$offer_probability <- rows$trade_probability *
    rows$choice_probability *
    rows$function_probability
  rows$probability_status <- rows$.probability_status
  rows$probability_basis  <- rows$.probability_basis
  result <- rows[, .bedrock_probability_columns, drop = FALSE]
  rownames(result) <- NULL
  result
}
