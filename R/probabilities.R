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
#' Calculates the marginal probability that each possible outcome appears
#' among a Minecraft Bedrock `1.26.30.5` villager's generated offers. The
#' returned components distinguish trade selection, explicit item choices, and
#' item-function outcomes.
#'
#' @param profession One canonical profession or alias listed by
#'   [villager_professions()]. The default is `"armorer"`.
#' @param tier One integer from 1 through 5 or one of `"novice"`,
#'   `"apprentice"`, `"journeyman"`, `"expert"`, and `"master"`.
#' @param scope `"tier"` to analyze only `tier`, or `"unlocked"` to include
#'   that tier and every earlier tier.
#' @param variant Villager biome variant when the requested trades depend on
#'   one. Use [villager_variants()] for canonical values and aliases.
#' @param dimension Dimension when the requested trades depend on one:
#'   `"overworld"`, `"nether"`, or `"end"`.
#'
#' @return A plain base data frame containing all 40 columns documented by
#'   [villager_trades()] followed by:
#'
#' - `trade_probability` (`double`) is the marginal chance that Mojang selects
#'   the source trade from its group.
#' - `choice_probability` (`double`) is the conditional chance of the
#'   applicable source `choice` combination.
#' - `function_probability` (`double`) is the conditional chance of the
#'   resolved or modeled item-function outcome.
#' - `offer_probability` (`double`) is the product of the preceding three
#'   components.
#' - `probability_status` (`character`) is `"exact"`,
#'   `"documented_model"`, or `"partial"`.
#' - `probability_basis` (`character`) identifies the source-table or modeling
#'   basis used for the function component.
#'
#' @section Interpreting an offer probability:
#' A group selecting `k` of `n` applicable source trades gives each trade
#' marginal probability `k / n`. A select-all group gives every trade
#' probability one. Explicit item choices divide a source trade's probability;
#' expanded options sharing a `trade_id` do not become additional trade
#' candidates.
#'
#' The overall value is marginal: it answers whether that row appears among a
#' villager's offers. Rows do not generally sum to one because a tier contains
#' several groups and can add several offers. With `scope = "unlocked"`, the
#' result includes every tier available to a villager at the requested rank.
#'
#' @section Librarian model:
#' `enchant_book_for_trading` chooses one of 39 eligible enchantments uniformly
#' and then chooses one of that enchantment's valid levels uniformly. An
#' enchantment with maximum level `m` therefore has function probability
#' `1 / 39 / m` at each level. Soul Speed, Swift Sneak, and Wind Burst are
#' excluded from this pinned pool.
#'
#' Emerald prices remain inclusive ranges rather than separate price-specific
#' rows. Price therefore does not contribute another probability component.
#'
#' @section Enchanted-equipment model:
#' Armorers, Fishermen, Fletchers, Toolsmiths, and Weaponsmiths use
#' `enchant_with_levels`. For each source trade, the model:
#'
#' 1. selects an integer source level `L` uniformly from 5 through 19;
#' 2. calculates modified power
#'    `round((L + 1 + R1 + R2) * M)`, where each `R` is uniform from zero
#'    through `floor(enchantability / 4)` and `M` follows the documented
#'    triangular distribution from 0.85 through 1.15;
#' 3. finds the highest eligible level of each compatible non-treasure
#'    enchantment;
#' 4. selects by enchantment weight, removes conflicts, and repeats with
#'    continuation chance `(power + 1) / 50`, halving power between additional
#'    selections.
#'
#' The updater integrates the triangular distribution analytically and
#' enumerates every weighted selection branch. It does not use simulation,
#' cross-validation, or resampling. Identical complete enchantment sets are
#' combined, and their probabilities sum to one within each equipment
#' generator.
#'
#' These rows receive `probability_status = "documented_model"`. Their
#' probabilities are exact under the cited model, while the label acknowledges
#' that Mojang does not publish every Bedrock engine constant in the pinned
#' sample repository.
#'
#' @section Exact, modeled, and partial rows:
#'
#' - `"exact"` covers outcomes fully determined by Mojang's trade tables,
#'   including direct items, choices, integer auxiliary values, maps, and
#'   potions.
#' - `"documented_model"` covers Librarian books and complete enchanted
#'   equipment sets.
#' - `"partial"` currently covers `random_dye`. Its row represents the
#'   unresolved dyed-leather outcome, so `function_probability = 1` refers to
#'   that category rather than a particular color.
#'
#' @section Context:
#' Filters alter which choices and source trades apply before probabilities
#' are calculated. The function requests `variant`, `dimension`, or both only
#' when the selected tiers depend on that context. It stops instead of silently
#' assuming Plains or the Overworld.
#'
#' @references
#' [Microsoft, "Creating a Trade Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Loot Tables Documentation - Enchanting Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Enchanting table mechanics," revision 3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)
#' @export
#'
#' @examples
#' novice <- offer_probabilities()
#' novice[
#'   ,
#'   c(
#'     'gives_1_item',
#'     'trade_probability',
#'     'offer_probability'
#'   )
#' ]
#'
#' bows <- offer_probabilities('fletcher', tier = 'expert')
#' head(
#'   bows[
#'     order(bows$offer_probability, decreasing = TRUE),
#'     c(
#'       'gives_1_enchantments',
#'       'function_probability',
#'       'offer_probability'
#'     )
#'   ]
#' )
#'
#' books <- offer_probabilities('librarian')
#' books[
#'   grepl('minecraft:mending=', books$gives_1_enchantments, fixed = TRUE),
#'   c(
#'     'gives_1_enchantments',
#'     'wants_1_quantity_min',
#'     'wants_1_quantity_max',
#'     'offer_probability'
#'   )
#' ]
#'
#' maps <- offer_probabilities(
#'   profession = 'cartographer',
#'   tier       = 'apprentice',
#'   variant    = 'snowy',
#'   dimension  = 'overworld'
#' )
#' maps[
#'   ,
#'   c(
#'     'gives_1_map_destination',
#'     'variants',
#'     'offer_probability'
#'   )
#' ]
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
