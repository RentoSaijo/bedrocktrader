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
#' Minecraft Bedrock `1.26.30.5` villager's trades are generated.
#'
#' @param profession One canonical profession identifier or alias listed by
#'   [villager_professions()]. The default is `"armorer"`.
#' @param level One level given as an integer from 1 through 5 or as `novice`,
#'   `apprentice`, `journeyman`, `expert`, or `master`.
#' @param scope `"tier"` to analyze only `level`, or `"unlocked"` to include
#'   that level and every earlier level. Earlier offers remain available after
#'   a villager advances.
#' @param variant Villager biome variant when the requested offers depend on
#'   one. Use [villager_variants()] to inspect canonical values and aliases.
#' @param dimension Dimension when the requested offers depend on one:
#'   `"overworld"`, `"nether"`, or `"end"`.
#'
#' @return A base data frame with one row per applicable outcome and 26 atomic
#'   columns:
#'
#' - `profession`, `level`, `level_name`, `group_id`, `trade_id`, and
#'   `option_id` identify the same row described by [villager_trades()].
#' - `variants` and `dimensions` (`character`) preserve the row's contextual
#'   restrictions. `NA` means unrestricted.
#' - `result_item` (`character`), `result_aux_value` (`integer`),
#'   `result_color`, `result_effect`, `potion`, `map_destination`,
#'   `enchantment`, and `enchantment_name` (`character`) identify the outcome.
#'   Fields that do not apply are typed `NA`.
#' - `enchantment_level` (`integer`) is the offered book level, otherwise `NA`.
#' - `cost_1_quantity_min` and `cost_1_quantity_max` (`double`) identify the
#'   first cost range, including modeled Librarian emerald prices.
#' - `outcome_status` (`character`) is copied from [villager_trades()].
#' - `selection_probability` (`double`) is the chance that the source trade is
#'   selected from its group.
#' - `choice_probability` (`double`) is the conditional chance of the explicit
#'   item-choice combination after applying context.
#' - `generator_probability` (`double`) is the conditional chance of the
#'   generated row. It is one when the engine outcome remains unresolved.
#' - `probability` (`double`) is the product of those three components.
#' - `probability_status` (`character`) is `exact`, `documented_model`, or
#'   `partial`.
#' - `probability_basis` (`character`) identifies whether the calculation comes
#'   from the source table, the documented Librarian model, or a source table
#'   with an unresolved engine outcome.
#'
#' @details
#' The returned probability is marginal: it is the chance that one row appears
#' among a villager's generated offers. Rows generally do not sum to one because
#' a level can contain several groups and a group can select several trades.
#' Options sharing a `trade_id` divide that trade's probability rather than
#' behaving as separate candidates.
#'
#' A group that selects `k` of `n` applicable trades gives each trade marginal
#' probability `k / n`. Select-all groups give each trade probability one.
#' Explicit item alternatives and integer `random_aux_value` outcomes are
#' treated as uniform among the choices that apply to the requested context.
#'
#' Librarian books use a documented model. One of 39 eligible enchantments is
#' selected uniformly, followed by one valid level selected uniformly. For an
#' enchantment with maximum level `m`, its generator probability is
#' `1 / 39 / m`. Soul Speed, Swift Sneak, and Wind Burst are excluded. The
#' probability is marginal over every emerald price in the displayed range;
#' price rolls are not separate rows.
#'
#' `enchant_with_levels` and `random_dye` require game-engine logic that the
#' pinned static data cannot reproduce completely. Their row probabilities are
#' exact only through selection and explicit choices, so their
#' `probability_status` is `partial`.
#'
#' Context is required only when the requested levels contain filtered offers.
#' For example, Cartographer map availability can depend on both villager
#' variant and dimension. The function stops instead of silently assuming
#' Plains or the Overworld.
#'
#' @references
#' [Microsoft, "Creating a Trade Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Loot Tables Documentation - Enchanting Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Tutorial: Trading"](https://minecraft.wiki/w/Tutorial%3ATrading)
#'
#' [Bedrock Wiki, "Trade Tables"](https://wiki.bedrock.dev/loot/trade-tables.html)
#' @export
#'
#' @examples
#' \dontrun{
#' novice <- offer_probabilities()
#' novice[
#'   ,
#'   c(
#'     'result_item',
#'     'selection_probability',
#'     'probability'
#'   )
#' ]
#'
#' books <- offer_probabilities('librarian')
#' books[
#'   !is.na(books$enchantment) & books$enchantment == 'mending',
#'   c(
#'     'enchantment_name',
#'     'enchantment_level',
#'     'probability',
#'     'probability_status'
#'   )
#' ]
#'
#' maps <- offer_probabilities(
#'   profession = 'cartographer',
#'   level      = 'apprentice',
#'   variant    = 'snowy',
#'   dimension  = 'overworld'
#' )
#' maps[
#'   ,
#'   c('map_destination', 'variants', 'probability')
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
