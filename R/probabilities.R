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
  value <- tolower(trimws(dimension))
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

# Calculate context-specific selection probabilities.
.selection_probabilities <- function(rows) {
  probabilities <- numeric(nrow(rows))
  group_ids <- unique(rows$group_id)
  for (group_id in group_ids) {
    group_rows <- which(rows$group_id == group_id)
    trade_count <- length(unique(rows$trade_id[group_rows]))
    if (trade_count < 1L) {
      next
    }
    if (isTRUE(rows$all_trades_selected[[group_rows[[1L]]]])) {
      probability <- 1
    } else {
      selected <- rows$trades_selected[[group_rows[[1L]]]]
      probability <- min(selected, trade_count) / trade_count
    }
    probabilities[group_rows] <- probability
  }
  probabilities
}

# Calculate context-specific choice probabilities.
.choice_probabilities <- function(rows) {
  probabilities <- numeric(nrow(rows))
  trade_ids <- unique(rows$trade_id)
  for (trade_id in trade_ids) {
    trade_rows <- which(rows$trade_id == trade_id)
    choice_count <- length(unique(rows$.source_option[trade_rows]))
    probabilities[trade_rows] <- 1 / choice_count
  }
  probabilities
}

# Public Functions --------------------------------------------------------------

#' Calculate Villager Offer Probabilities
#'
#' Calculates the marginal probability that each possible offer appears when a
#' villager's trades are generated.
#'
#' @param profession One canonical profession identifier or documented alias.
#' @param level One numeric or named villager level.
#' @param scope `"tier"` to analyze only `level`, or `"unlocked"` to include
#'   `level` and every earlier level.
#' @param variant Villager biome variant when the requested offers depend on
#'   one. Use [villager_variants()] to inspect valid values.
#' @param dimension Dimension when the requested offers depend on one:
#'   `"overworld"`, `"nether"`, or `"end"`.
#'
#' @return A base data frame with one row per possible trade outcome and
#'   separate selection, item-choice, generator, and combined probabilities.
#' @export
#'
#' @examples
#' \dontrun{
#' novice <- offer_probabilities()
#' novice[
#'   ,
#'   c('result_item', 'probability', 'probability_status')
#' ]
#'
#' books <- offer_probabilities('librarian')
#' books[
#'   books$enchantment == 'mending',
#'   c('enchantment', 'enchantment_level', 'probability')
#' ]
#' }
offer_probabilities <- function(
  profession = 'armorer',
  level = 'novice',
  scope = c('tier', 'unlocked'),
  variant = NULL,
  dimension = NULL
) {
  profession <- .normalize_profession_input(profession)
  level      <- .normalize_level_input(level, allow_null = FALSE)
  scope      <- match.arg(scope)
  variant    <- .normalize_variant_input(variant)
  dimension  <- .normalize_dimension_input(dimension)
  selected_levels <- if (identical(scope, 'tier')) level else seq_len(level)
  object <- .load_profession_tables(profession)
  rows <- .flatten_trade_table(
    table           = object$professions[[profession]],
    release         = object$release,
    selected_levels = selected_levels
  )
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
  rows$selection_probability <- .selection_probabilities(rows)
  rows$choice_probability    <- .choice_probabilities(rows)
  rows$generator_probability <- rows$.generator_probability
  rows$probability <- rows$selection_probability *
    rows$choice_probability *
    rows$generator_probability
  rows$probability_status <- rows$.probability_status
  rows$probability_basis  <- rows$.probability_basis
  result <- rows[, .bedrock_probability_columns, drop = FALSE]
  rownames(result) <- NULL
  result
}
