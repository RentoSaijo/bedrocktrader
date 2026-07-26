# Input Helpers -----------------------------------------------------------------

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

# Normalize tier input.
.normalize_tier_input <- function(tier, allow_null = TRUE) {
  if (allow_null && is.null(tier)) {
    return(seq_along(.bedrock_tier_names))
  }
  if (length(tier) != 1L || is.na(tier)) {
    stop('`tier` must be one villager tier.', call. = FALSE)
  }
  if (is.numeric(tier)) {
    if (
      !is.finite(tier) ||
      tier != floor(tier) ||
      !(tier %in% seq_along(.bedrock_tier_names))
    ) {
      stop('`tier` must be an integer from 1 through 5.', call. = FALSE)
    }
    return(as.integer(tier))
  }
  if (!is.character(tier) || !nzchar(tier)) {
    stop(
      '`tier` must be an integer from 1 through 5 or a tier name.',
      call. = FALSE
    )
  }
  value   <- tolower(trimws(tier))
  matched <- match(value, .bedrock_tier_names)
  if (is.na(matched)) {
    stop(
      '`tier` must be novice, apprentice, journeyman, expert, or master.',
      call. = FALSE
    )
  }
  matched
}

# Public Functions --------------------------------------------------------------

#' List Supported Villager Professions
#'
#' Lists the 13 employable vanilla villager professions included in the
#' Minecraft Bedrock `1.26.30.5` data model. The feature flags offer a quick
#' way to find tables that need contextual inputs or contain expanded source
#' instructions.
#'
#' @return A base data frame with one row per profession:
#'
#' - `profession` (`character`) is the canonical value accepted by
#'   [villager_trades()] and [offer_probabilities()].
#' - `display_name` (`character`) is the readable profession name.
#' - `aliases` (`character`) contains additional accepted inputs separated by
#'   commas. It is `NA` when a profession has no aliases.
#' - `context_sensitive` (`logical`) is `TRUE` when at least one trade uses a
#'   villager-variant or dimension filter.
#' - `contains_item_choices` (`logical`) is `TRUE` when Mojang supplies at
#'   least one `choice` array.
#' - `contains_dynamic_functions` (`logical`) is `TRUE` when at least one item
#'   uses a trade-table function, including enchanting, random auxiliary
#'   values, potion setting, map creation, or random dye.
#'
#' @details
#' Inputs are case-insensitive. `mason` and `stonemason` resolve to
#' `stone_mason`; `leather_worker`, `tool_smith`, and `weapon_smith` likewise
#' resolve to their canonical package identifiers.
#'
#' These rows are bundled with the package. Calling the function performs no
#' download and does not inspect a saved world.
#' @export
#'
#' @examples
#' professions <- villager_professions()
#' professions
#'
#' professions[
#'   professions$contains_dynamic_functions,
#'   c('profession', 'contains_dynamic_functions')
#' ]
villager_professions <- function() {
  result <- .bedrock_professions_data
  rownames(result) <- NULL
  result
}

#' List Villager Variants
#'
#' Lists vanilla villager biome variants and their
#' `minecraft:mark_variant` values for Minecraft Bedrock `1.26.30.5`.
#'
#' @return A base data frame with seven rows:
#'
#' - `variant` (`character`) is the canonical package identifier.
#' - `mark_variant` (`integer`) is Mojang's
#'   `minecraft:mark_variant` component value. Vanilla
#'   `is_mark_variant` filters compare against this number.
#' - `aliases` (`character`) contains additional accepted inputs separated by
#'   commas. It is `NA` when no aliases exist.
#'
#' @details
#' The canonical cold-biome identifier is `snow`, matching the pinned entity
#' definition. `snowy` remains an accepted convenience alias in
#' [offer_probabilities()].
#'
#' The values come from the bundled `villager_v2.json` model; the function
#' neither downloads data nor examines villagers in a saved world.
#' @export
#'
#' @examples
#' variants <- villager_variants()
#' variants
#'
#' variants[variants$variant == 'snow', ]
villager_variants <- function() {
  result <- .bedrock_variants_data
  rownames(result) <- NULL
  result
}

#' List Villager Tiers
#'
#' Lists the five villager trading tiers and the cumulative experience a
#' villager needs to unlock each tier in Minecraft Bedrock `1.26.30.5`.
#'
#' @return A base data frame with five rows:
#'
#' - `tier` (`integer`) is the numeric tier used by [villager_trades()].
#' - `tier_name` (`character`) is the corresponding in-game rank.
#' - `total_exp_required` (`double`) is the cumulative trading experience the
#'   villager needs to unlock the tier. The novice tier is always available.
#'
#' @details
#' The bundled vanilla profession tables use the same tier names and
#' experience thresholds. Calling this function performs no download.
#' @export
#'
#' @examples
#' villager_tiers()
villager_tiers <- function() {
  result <- .bedrock_tiers_data
  rownames(result) <- NULL
  result
}

#' Retrieve Villager Trades
#'
#' Returns possible vanilla trade outcomes for one profession in Minecraft
#' Bedrock `1.26.30.5`. Item choices, integer auxiliary-value ranges,
#' Librarian books, and enchanted equipment are expanded into separate rows.
#'
#' @param profession One canonical profession or alias listed by
#'   [villager_professions()]. The default is `"armorer"`; `"all"` is not a
#'   profession value.
#' @param tier `NULL` for all five tiers, or one integer from 1 through 5 or
#'   one of `"novice"`, `"apprentice"`, `"journeyman"`, `"expert"`, and
#'   `"master"`.
#'
#' @return A plain base data frame with one row per possible option and 40
#'   atomic columns.
#'
#' @section Reading the hierarchy:
#' Minecraft trade tables follow `tier -> group -> trade`. `bedrocktrader`
#' adds `option` for a concrete expansion of one source trade.
#'
#' `group_id` identifies a pool from which trades are selected. `trade_id`
#' identifies one source trade and therefore repeats when that trade has
#' several item choices or generated outcomes. `option_id` uniquely identifies
#' each returned row. Repeated `trade_id` values are alternatives from the same
#' trade rather than separate candidates in the group.
#'
#' The result describes every possible definition for a profession, not one
#' villager's realized inventory. Use [offer_probabilities()] to apply context
#' and calculate appearance probabilities.
#'
#' @section Progression and selection columns:
#'
#' - `profession` (`character`) is the canonical profession.
#' - `tier` (`integer`) and `tier_name` (`character`) identify the trade tier.
#' - `total_exp_required` (`double`) is the cumulative experience the trader
#'   needs to unlock the tier.
#' - `group_id`, `trade_id`, and `option_id` (`character`) identify the source
#'   group, source trade, and expanded option.
#' - `num_trades` (`integer`) counts source trades in the group before
#'   expansion.
#' - `num_to_select` (`double`) preserves Mojang's selection instruction.
#'   `-1` is the select-all convention.
#' - `select_all` (`logical`) makes the `num_to_select = -1` convention
#'   explicit.
#'
#' @section Applicability columns:
#'
#' - `variants` (`character`) lists allowed villager variants separated by
#'   commas.
#' - `dimensions` (`character`) lists allowed dimensions.
#'
#' `NA` means that Mojang imposes no restriction on that axis.
#' `villager_trades()` preserves all possibilities rather than assuming Plains
#' or the Overworld.
#'
#' @section Wants columns:
#' `wants_1_*` describes the first item requested from the player.
#' `wants_2_*` describes an optional second item. Both slots use:
#'
#' - `item` (`character`) for the namespaced Minecraft item identifier.
#' - `aux_value` (`integer`) for a legacy numeric item suffix, otherwise `NA`.
#' - `quantity_min` and `quantity_max` (`double`) for the inclusive quantity
#'   range. Equal bounds indicate a fixed amount.
#' - `price_multiplier` (`double`) for demand-driven price adjustment; it is
#'   `NA` when Mojang omits the property.
#'
#' All five `wants_2_*` fields are typed `NA` for a one-input trade. Librarian
#' emerald bounds include `enchant_book_for_trading`, but exclude later demand,
#' curing, and Hero of the Village adjustments.
#'
#' @section Gives columns:
#'
#' - `gives_1_item` (`character`) is the namespaced item given to the player.
#' - `gives_1_aux_value` (`integer`) is a resolved legacy item suffix.
#' - `gives_1_quantity_min` and `gives_1_quantity_max` (`double`) give the
#'   inclusive amount range.
#' - `gives_1_color`, `gives_1_effect`, `gives_1_potion`, and
#'   `gives_1_map_destination` (`character`) identify resolved bed or banner
#'   color, suspicious-stew effect, potion, or exploration-map destination.
#' - `gives_1_enchantments` (`character`) records a complete enchantment set as
#'   sorted `minecraft:id=level` pairs separated by commas. For example,
#'   `minecraft:sharpness=2,minecraft:unbreaking=1` describes one sword carrying
#'   both enchantments.
#' - `gives_1_enchantment_count` (`integer`) counts enchantments in that set.
#' - `gives_1_treasure` (`logical`) indicates whether the set contains a
#'   treasure enchantment.
#'
#' The enchantment fields are `NA` for ordinary items. Omitted quantities
#' normalize to one according to the trade-table format; other absent source
#' properties remain typed `NA`.
#'
#' @section Function columns:
#'
#' - `functions` (`character`) names the Mojang item function, or is `NA`.
#' - `levels_min` and `levels_max` (`double`) preserve the inclusive `levels`
#'   range supplied to `enchant_with_levels`; they are source enchanting-power
#'   inputs, not enchantment levels on the finished item.
#' - `outcome_status` (`character`) is `source_resolved`,
#'   `documented_model`, or `engine_generated`.
#'
#' Direct items, explicit choices, integer `random_aux_value` outcomes,
#' potions, and map destinations are `source_resolved`. Librarian books and
#' enchanted equipment are `documented_model`. `random_dye` remains
#' `engine_generated`, so its leather color is unresolved.
#'
#' Each Librarian book trade expands to 116 enchantment-level options. Normal
#' emerald ranges are 5--19 for level I, 8--32 for II, 11--45 for III, 14--58
#' for IV, and 17--64 for V. Treasure prices double before the 64-emerald cap.
#'
#' Equipment rows represent complete enchantment sets, including multi-enchant
#' items sold by Armorers, Fishermen, Fletchers, Toolsmiths, and Weaponsmiths.
#' Their source emerald amount remains fixed across generated sets.
#'
#' @section Trade behavior columns:
#'
#' - `max_uses` (`double`) is the number of completed trades before the offer
#'   locks until restocking.
#' - `trader_exp` (`double`) is experience gained by the villager.
#' - `reward_exp` (`logical`) says whether the player receives experience.
#'
#' These fields remain `NA` when Mojang omits the corresponding property; the
#' package does not insert documented game defaults.
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
#' novice <- villager_trades(tier = 'novice')
#' novice[
#'   ,
#'   c(
#'     'wants_1_item',
#'     'wants_1_quantity_min',
#'     'gives_1_item'
#'   )
#' ]
#'
#' armor <- villager_trades('armorer', tier = 'expert')
#' head(
#'   armor[
#'     !is.na(armor$gives_1_enchantments),
#'     c(
#'       'gives_1_item',
#'       'gives_1_enchantments',
#'       'wants_1_quantity_min'
#'     )
#'   ]
#' )
#'
#' books <- villager_trades('librarian', tier = 'novice')
#' books[
#'   grepl('minecraft:mending=', books$gives_1_enchantments, fixed = TRUE),
#'   c(
#'     'gives_1_enchantments',
#'     'wants_1_quantity_min',
#'     'wants_1_quantity_max'
#'   )
#' ]
villager_trades <- function(profession = 'armorer', tier = NULL) {
  profession <- .normalize_profession_input(profession)
  tiers      <- .normalize_tier_input(tier)
  keep <- .bedrock_trade_outcomes$profession == profession &
    .bedrock_trade_outcomes$tier %in% tiers
  result <- .bedrock_trade_outcomes[
    keep,
    .bedrock_trade_columns,
    drop = FALSE
  ]
  rownames(result) <- NULL
  result
}
