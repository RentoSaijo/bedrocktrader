# Profession Helpers ------------------------------------------------------------

# Normalize profession input.
.normalize_profession_input <- function(profession) {
  if (
    length(profession) != 1L ||
    is.na(profession) ||
    !is.character(profession) ||
    !nzchar(profession)
  ) {
    stop('`profession` must be one nonempty character value.', call. = FALSE)
  }
  value <- tolower(trimws(profession))
  for (canonical in names(.bedrock_profession_aliases)) {
    if (value %in% c(canonical, .bedrock_profession_aliases[[canonical]])) {
      return(canonical)
    }
  }
  stop(
    'Unsupported villager profession `',
    profession,
    '`. Use `villager_professions()` to inspect supported values.',
    call. = FALSE
  )
}

# Load profession tables.
.load_profession_tables <- function(professions) {
  tables <- .bedrock_trade_tables[professions]
  list(
    professions = tables,
    release     = .pinned_release()
  )
}

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
  for (level in table$levels) {
    for (group in level$groups) {
      for (candidate in group$candidates) {
        positions <- c(
          positions,
          candidate$wants,
          candidate$gives
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
    context_sensitive         = context_sensitive,
    contains_item_choices     = contains_item_choices,
    contains_dynamic_functions = contains_dynamic_functions
  )
}

# Public Functions ---------------------------------------------------------------

#' List Supported Villager Professions
#'
#' Lists the 13 employable vanilla villager professions understood by
#' `bedrocktrader`. Each row summarizes features found in that profession's
#' Minecraft Bedrock `1.26.30.5` trade table.
#'
#' @return A base data frame with one row per profession:
#'
#' - `profession` (`character`) is the canonical input accepted by
#'   [villager_trades()] and [offer_probabilities()].
#' - `display_name` (`character`) is the readable profession name.
#' - `aliases` (`character`) lists additional accepted inputs, separated by
#'   commas. It is `NA` when no aliases exist.
#' - `context_sensitive` (`logical`) is `TRUE` when at least one offer uses a
#'   biome-variant or dimension filter. It does not imply that every offer from
#'   the profession is conditional.
#' - `contains_item_choices` (`logical`) is `TRUE` when Mojang supplies an item
#'   `choice` array. [villager_trades()] expands those alternatives.
#' - `contains_dynamic_functions` (`logical`) is `TRUE` when at least one result
#'   uses a generator such as enchanting, random dye, potion setting, or map
#'   creation.
#'
#' @details
#' The function retrieves and verifies all 13 pinned profession tables, then
#' inspects their source structure. The flags describe version `1.26.30.5`;
#' they are not permanent claims about later Minecraft releases.
#'
#' Canonical names and aliases are case-insensitive when passed to other
#' package functions. For example, `mason` and `stone_mason` both resolve to the
#' canonical `stone_mason` profession.
#' @export
#'
#' @examples
#' \dontrun{
#' professions <- villager_professions()
#' professions
#'
#' professions[
#'   professions$contains_dynamic_functions,
#'   c('profession', 'contains_dynamic_functions')
#' ]
#'
#' }
villager_professions <- function() {
  result <- .bedrock_professions_data
  rownames(result) <- NULL
  result
}

#' List Villager Variants
#'
#' Lists the seven vanilla villager biome variants and their stored
#' `minecraft:mark_variant` values in Minecraft Bedrock `1.26.30.5`.
#'
#' @return A base data frame with one row per variant:
#'
#' - `variant` (`character`) is the canonical package identifier.
#' - `mark_variant` (`integer`) is the value stored by Mojang's
#'   `minecraft:mark_variant` entity component. Vanilla `is_mark_variant`
#'   filters compare against this value.
#' - `aliases` (`character`) lists additional accepted inputs, separated by
#'   commas. It is `NA` when no aliases exist.
#'
#' @details
#' Values are read from the pinned vanilla `villager_v2.json` entity definition.
#' The canonical snowy-biome identifier is `snow`; `snowy` is an accepted alias
#' in [offer_probabilities()]. This function describes available codes and does
#' not inspect a saved-world villager.
#' @export
#'
#' @examples
#' \dontrun{
#' variants <- villager_variants()
#' variants
#'
#' variants[variants$variant == 'snow', ]
#'
#' }
villager_variants <- function() {
  result <- .bedrock_variants_data
  rownames(result) <- NULL
  result
}

#' Retrieve Villager Trades
#'
#' Retrieves one official vanilla profession table for Minecraft Bedrock
#' `1.26.30.5` and turns its nested definitions into concrete, readable rows.
#'
#' @param profession One canonical profession identifier or an alias listed by
#'   [villager_professions()]. The default is `"armorer"`.
#' @param level `NULL` for all five levels, or one level given as an integer
#'   from 1 through 5 or as `novice`, `apprentice`, `journeyman`, `expert`, or
#'   `master`.
#'
#' @return A base data frame with one row per concrete item-choice or modeled
#'   enchantment-level outcome and 42 atomic columns.
#'
#' @section How to read a row:
#' A profession contains five levels. A level contains groups, and each group
#' selects one or more source trades. A trade can then expand into several
#' options because it offers alternative items, random auxiliary values, or a
#' modeled enchanted book.
#'
#' `group_id` identifies the selection pool. `trade_id` identifies one source
#' trade inside that group and can repeat after expansion. `option_id` uniquely
#' identifies each returned row. Options sharing a `trade_id` are alternative
#' realizations of one trade; they are not independently selected offers.
#'
#' The table is a catalog of possible definitions rather than the inventory of
#' a particular villager in a saved world. Use [offer_probabilities()] to apply
#' context and calculate marginal appearance probabilities.
#'
#' @section Progression and selection:
#'
#' - `profession` (`character`) is the canonical profession identifier.
#' - `level` (`integer`) and `level_name` (`character`) identify the tier.
#' - `total_exp_required` (`double`) is the cumulative experience the villager
#'   needs to unlock that tier.
#' - `group_id`, `trade_id`, and `option_id` (`character`) identify the group,
#'   source trade, and expanded row.
#' - `trades_in_group` (`integer`) counts source trades before expansion.
#' - `trades_selected` (`integer`) is how many source trades the group adds to a
#'   villager.
#' - `all_trades_selected` (`logical`) records Mojang's select-all convention.
#'   Source `num_to_select = -1`, including an omitted property, is presented as
#'   the actual trade count with this flag set to `TRUE`.
#'
#' @section Applicability:
#'
#' - `variants` (`character`) lists allowed villager biome variants, separated
#'   by commas.
#' - `dimensions` (`character`) lists allowed dimensions.
#'
#' `NA` means that the source imposes no restriction on that axis. These columns
#' describe applicability; `villager_trades()` does not remove rows for a
#' particular context.
#'
#' @section Player costs:
#' `cost_1_` describes the first item paid by the player; `cost_2_` describes an
#' optional second item. Each prefix has:
#'
#' - `item` (`character`) for the Mojang item identifier.
#' - `aux_value` (`integer`) for a numeric auxiliary suffix, otherwise `NA`.
#' - `quantity_min` and `quantity_max` (`double`) for the possible amount.
#' - `price_multiplier` (`double`) for demand-driven price adjustment; `NA`
#'   when Mojang omits it.
#'
#' Every `cost_2_` field is typed `NA` for a one-input trade. Equal quantity
#' bounds indicate a fixed cost. Librarian emerald bounds include the
#' `enchant_book_for_trading` generator, but do not include later demand,
#' curing, or Hero of the Village adjustments.
#'
#' @section Result:
#'
#' - `result_item` (`character`) is the item received by the player.
#' - `result_aux_value` (`integer`) records a concrete legacy variation.
#' - `result_quantity_min` and `result_quantity_max` (`double`) give its amount.
#' - `result_color`, `result_effect`, `potion`, and `map_destination`
#'   (`character`) describe resolved color, suspicious-stew effect, tipped-arrow
#'   potion, or exploration-map destination. They are `NA` when inapplicable.
#' - `enchantment` and `enchantment_name` (`character`) identify a modeled
#'   librarian book.
#' - `enchantment_level` and `enchantment_max_level` (`integer`) give the
#'   offered level and that enchantment's maximum.
#' - `treasure` (`logical`) indicates a treasure enchantment. It is `NA` for
#'   results without an enchanting generator.
#'
#' Omitted item quantities normalize to one, following the trade-table format.
#' Other omitted Mojang properties remain typed `NA`; the package does not
#' silently substitute game defaults.
#'
#' @section Generators:
#'
#' - `generator` (`character`) names the source function, or is `NA`.
#' - `enchanting_power_min` and `enchanting_power_max` (`double`) preserve the
#'   level-power inputs to `enchant_with_levels`. They are not enchantment
#'   levels.
#' - `outcome_status` (`character`) is `source_resolved`,
#'   `documented_model`, or `engine_generated`.
#'
#' Explicit item choices, potions, map destinations, suspicious-stew effects,
#' and bed/banner colors are source-resolved. Librarian enchanted books use a
#' documented model: 39 equally likely enchantments, followed by an equally
#' likely valid level. Soul Speed, Swift Sneak, and Wind Burst are excluded.
#' Each enchanted-book source trade therefore expands to 116 rows.
#'
#' Normal librarian emerald ranges are 5--19 for level I, 8--32 for II, 11--45
#' for III, 14--58 for IV, and 17--64 for V. Treasure costs double before the
#' 64-emerald cap. Each row covers every price inside its displayed range;
#' prices are not expanded into separate rows.
#'
#' `enchant_with_levels` can produce multiple compatible enchantments through
#' the Bedrock engine, and `random_dye` can generate arbitrary leather colors.
#' Those rows remain `engine_generated` rather than claiming unsupported
#' concrete outcomes.
#'
#' @section Trade behavior:
#'
#' - `max_uses` (`double`) is the number of completed uses before the offer
#'   locks until restocking.
#' - `villager_exp` (`double`) is experience gained by the villager.
#' - `player_exp` (`logical`) records whether the player receives experience.
#'
#' These fields are `NA` when Mojang omits the corresponding property.
#'
#' @references
#' [Microsoft, "Creating a Trade Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Loot Tables Documentation - Enchanting Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Tutorial: Trading"](https://minecraft.wiki/w/Tutorial%3ATrading)
#' @export
#'
#' @examples
#' \dontrun{
#' armorer <- villager_trades(level = 'novice')
#' armorer[
#'   ,
#'   c(
#'     'level_name',
#'     'cost_1_item',
#'     'cost_1_quantity_min',
#'     'result_item'
#'   )
#' ]
#'
#' books <- villager_trades('librarian', level = 1)
#' books[
#'   !is.na(books$enchantment) & books$enchantment == 'mending',
#'   c(
#'     'enchantment_name',
#'     'cost_1_quantity_min',
#'     'cost_1_quantity_max'
#'   )
#' ]
#'
#' mason <- villager_trades('mason', level = 'journeyman')
#' mason[
#'   ,
#'   c('group_id', 'trade_id', 'option_id', 'result_item')
#' ]
#' }
villager_trades <- function(profession = 'armorer', level = NULL) {
  profession <- .normalize_profession_input(profession)
  levels     <- .normalize_level_input(level)
  object     <- .load_profession_tables(profession)
  result <- .flatten_trade_table(
    table           = object$professions[[profession]],
    release         = object$release,
    selected_levels = levels
  )
  result <- result[, .bedrock_trade_columns, drop = FALSE]
  rownames(result) <- NULL
  result
}
