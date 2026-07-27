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

# Normalize trade view input.
.normalize_view_input <- function(view) {
  match.arg(view, c('trade', 'option', 'offer'))
}

# Public Functions --------------------------------------------------------------

#' List supported villager professions
#'
#' Lists the 13 employable vanilla villager professions included in the
#' Minecraft: Bedrock Edition `1.26.30.5` data model. The feature flags identify
#' tables that need contextual inputs or contain generated source instructions.
#'
#' @returns A base data frame with one row per profession:
#'
#' - `profession` (`character`) is the canonical value accepted by
#'   [villager_trades()].
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
#' `context_sensitive = TRUE` means [villager_trades()] needs `variant`,
#' `dimension`, or both before it can determine applicable groups and their
#' probabilities.
#'
#' These rows are bundled with the package. Calling the function performs no
#' download and does not inspect a saved world.
#' @export
#'
#' @examples
#' # Inspect villager professions.
#' professions <- villager_professions()
#' professions
#'
#' # Inspect professions with generated source instructions.
#' professions[
#'   professions$contains_dynamic_functions,
#'   c('profession', 'contains_dynamic_functions')
#' ]
villager_professions <- function() {
  result <- .bedrock_professions_data
  rownames(result) <- NULL
  result
}

#' List villager variants
#'
#' Lists vanilla villager biome variants and their
#' `minecraft:mark_variant` values for Minecraft: Bedrock Edition `1.26.30.5`.
#'
#' @returns A base data frame with seven rows:
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
#' [villager_trades()].
#'
#' The values come from the bundled `villager_v2.json` model; the function
#' neither downloads data nor examines villagers in a saved world.
#' @export
#'
#' @examples
#' # Inspect villager variants.
#' variants <- villager_variants()
#' variants
#'
#' # Inspect snowy villager metadata.
#' variants[variants$variant == 'snow', ]
villager_variants <- function() {
  result <- .bedrock_variants_data
  rownames(result) <- NULL
  result
}

#' List villager tiers
#'
#' Lists the five villager trading tiers and the cumulative experience a
#' villager needs to unlock each tier in Minecraft: Bedrock Edition
#' `1.26.30.5`.
#'
#' @returns A base data frame with five rows:
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
#' # Inspect villager tiers.
#' villager_tiers()
villager_tiers <- function() {
  result <- .bedrock_tiers_data
  rownames(result) <- NULL
  result
}

#' List enchantments
#'
#' Lists the 42 enchantments registered in Minecraft: Bedrock Edition
#' `1.26.30.5` and identifies those available through the bundled villager
#' model.
#'
#' @returns A base data frame with one row per enchantment:
#'
#' - `enchantment` (`character`) is the namespaced identifier.
#' - `display_name` (`character`) is the readable enchantment name.
#' - `max_level` (`integer`) is the highest valid level.
#' - `treasure` (`logical`) identifies treasure enchantments.
#' - `villager_attainable` (`logical`) indicates availability through the
#'   pinned librarian trade model.
#' - `traded_items` (`character`) lists directly traded enchanted equipment,
#'   separated by commas. It is `NA` when none applies.
#'
#' @details
#' The registry contains the 39 enchantments available from librarians plus
#' Soul Speed, Swift Sneak, and Wind Burst. The latter three remain visible for
#' validation and return `FALSE` in `villager_attainable`.
#'
#' `traded_items` concerns equipment generated directly by armorer, fisherman,
#' fletcher, toolsmith, or weaponsmith trades. It does not list items that can
#' receive a librarian book later through an anvil.
#'
#' Values are bundled and verified against Mojang's pinned enchantment registry
#' during package development. Calling the function performs no download.
#'
#' @references
#' [Microsoft, "`/enchant` Command"](https://learn.microsoft.com/en-us/minecraft/creator/commands/commands/enchant?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Introduction to Enchantments"](https://learn.microsoft.com/en-us/minecraft/creator/documents/introtoenchantments?view=minecraft-bedrock-stable)
#' @export
#'
#' @examples
#' # Inspect enchantment metadata.
#' registry <- enchantments()
#' head(registry)
#'
#' # Inspect enchantments unavailable through villagers.
#' registry[!registry$villager_attainable, ]
enchantments <- function() {
  result <- .bedrock_enchantments_data
  rownames(result) <- NULL
  result
}

#' Retrieve villager trades
#'
#' Returns the possible vanilla trades for one profession in
#' Minecraft: Bedrock Edition `1.26.30.5`, together with the probability
#' represented at the requested trade, option, or offer resolution.
#'
#' @param profession One canonical profession or alias listed by
#'   [villager_professions()]. The default is `"armorer"`; `"all"` is not a
#'   profession value.
#' @param view Resolution of the returned rows. `"trade"` summarizes generated
#'   specifications and prices, `"option"` resolves item specifications while
#'   retaining price bounds, and `"offer"` resolves exact specifications and
#'   prices.
#' @param variant One villager biome variant when the profession has
#'   variant-dependent trades. Use [villager_variants()] for canonical values
#'   and aliases.
#' @param dimension One of `"overworld"`, `"nether"`, or `"end"` when the
#'   profession has dimension-dependent trades.
#'
#' @returns A plain base data frame containing only atomic columns. Trade results
#'   contain 29 columns. Option results add `option_id` after `trade_id`, for
#'   30 columns. Offer results add `offer_id` after `option_id`, for 31 columns.
#'
#' @section Hierarchical views:
#' Minecraft trade tables follow `tier -> group -> trade`; the package extends
#' that structure as `trade_id -> option_id -> offer_id`. Explicit Mojang item
#' choices remain separate rows so every `wants` and `gives` field stays
#' atomic.
#'
#' `view = "trade"` returns 281 base item-choice combinations from 182 authored
#' source entries across the pinned tables. Generated details remain summarized,
#' so a librarian book row covers every modeled enchantment, level, and price.
#' A `trade_id` can repeat when Mojang supplies explicit item choices.
#'
#' `view = "option"` returns 2,787 concrete item specifications. For example,
#' one enchanted-equipment option names its complete enchantment set while its
#' emerald columns span every price that can produce that set. The probability
#' is marginal over those prices.
#'
#' `view = "offer"` returns 30,592 exact configurations. Each populated
#' quantity minimum equals its maximum, and `offer_probability` covers the
#' displayed items, specification, and price jointly. Offers are grouped by
#' option and sorted by price.
#'
#' Fixed potion and exploration-map instructions resolve in every view because
#' they do not create alternatives. `random_dye` remains one partial row
#' because its color distribution is not established by the pinned sources.
#'
#' @section Identity and selection columns:
#'
#' - `profession` (`character`) is the canonical profession.
#' - `tier` (`integer`) is the numeric trading tier. Join it to
#'   [villager_tiers()] for its name and experience requirement.
#' - `group_id` (`character`) identifies a pool of possible source trades.
#' - `num_trades` (`integer`) counts source entries that apply to the requested
#'   context in that group. Item and function expansions do not increase it;
#'   repeated identical entries still count because they affect selection
#'   probability.
#' - `num_to_select` (`integer`) is Mojang's number of trades selected from the
#'   group. `-1` means every applicable trade is selected.
#' - `trade_id` (`character`) identifies one source trade. Explicit item-choice
#'   rows share this identifier.
#' - `option_id` (`character`) identifies one concrete item specification. It
#'   appears in option and offer views and repeats across an option's prices.
#' - `offer_id` (`character`) uniquely identifies an exact configuration. It
#'   appears only in the offer view.
#'
#' The identifiers are stable within the pinned package release and do not
#' appear in Mojang's source files.
#'
#' @section Wants columns:
#' `wants_1_*` describes the first item the villager wants from the player;
#' `wants_2_*` describes an optional second item. Each slot contains:
#'
#' - `item` (`character`) is Mojang's namespaced identifier. Legacy data
#'   suffixes remain attached, as in `minecraft:coal:0`.
#' - `quantity_min` and `quantity_max` (`double`) are inclusive bounds. Equal
#'   values describe a fixed quantity.
#' - `price_multiplier` (`double`) controls supply-and-demand price increases.
#'
#' Every `wants_2_*` field is typed `NA` for a one-item payment. An omitted
#' quantity becomes one, while an omitted price multiplier on an existing item
#' becomes Mojang's documented default of `0.05`.
#'
#' Trade rows span every modeled price when a function changes the emerald
#' cost. Option rows provide the bounds for one item specification; those bounds
#' do not promise that every interior integer is attainable. Offer rows have
#' equal minima and maxima and therefore identify exact modeled prices. All
#' returned values precede demand, curing, and Hero of the Village adjustments.
#'
#' @section Gives columns:
#'
#' - `gives_1_item` (`character`) is the namespaced item given to the player.
#' - `gives_1_quantity_min` and `gives_1_quantity_max` (`double`) give the
#'   inclusive amount range.
#' - `gives_1_color`, `gives_1_effect`, `gives_1_potion`, and
#'   `gives_1_map_destination` (`character`) give a resolved color, suspicious
#'   stew effect, potion identifier, or exploration-map destination. Each is
#'   `NA` when the specification does not apply or remains collapsed.
#' - `gives_1_enchantments` (`character`) records a complete enchantment set as
#'   sorted `minecraft:id=level` pairs separated by commas. For example,
#'   `minecraft:sharpness=2,minecraft:unbreaking=1` describes one sword carrying
#'   both enchantments. It is `NA` on trade-view generated rows and ordinary
#'   items.
#' - `gives_1_treasure` (`logical`) indicates whether the set contains a
#'   treasure enchantment. It is `NA` when no single treasure status applies.
#'
#' @section Generation and behavior columns:
#'
#' - `functions` (`character`) names the Mojang item function or is `NA`.
#'   Mojang defines `functions` as an array; the supported vanilla rows contain
#'   at most one result function.
#' - `max_uses` (`double`) is the number of completed trades before the offer
#'   locks until restocking.
#' - `trader_exp` (`double`) is experience gained by the villager.
#' - `reward_exp` (`logical`) says whether the player receives experience.
#'
#' When Mojang omits these properties, the package returns the documented
#' runtime defaults: 12 uses, one trader experience point, and player
#' experience enabled.
#'
#' @section Offer probability:
#' `offer_probability` (`double`) is the marginal chance that the displayed row
#' appears among the villager's offers. A group selecting `k` of `n` applicable
#' source entries gives an ordinary source trade probability `k / n`;
#' select-all groups give every source trade probability one. Identical source
#' entries are treated as repeated ways to obtain the same trade. Explicit
#' choices and generated outcomes then contribute their conditional
#' probabilities.
#'
#' Rows do not generally sum to one. A tier can contain several groups and can
#' therefore add several offers. A trade row is marginal over its generated
#' item specifications and prices. An option row is marginal over prices for
#' one specification. An offer row gives the joint probability of one
#' specification and exact price. Summing offers recovers their option
#' probability; summing options recovers the corresponding trade-view row.
#'
#' `probability_status` (`character`) describes the calculation:
#'
#' - `"exact"` covers source-table selection, explicit choices, legacy
#'   data-value outcomes, fixed potions, and maps.
#' - `"documented_model"` covers librarian books and complete enchanted
#'   equipment sets.
#' - `"partial"` marks `random_dye`, whose exact leather-color distribution is
#'   not established by the pinned sources.
#'
#' @section Enchantment models:
#' Each librarian book trade draws uniformly from 39 eligible enchantments,
#' then draws uniformly from the selected enchantment's valid levels. This
#' gives 116 enchantment-level combinations. Soul Speed, Swift Sneak, and Wind
#' Burst are excluded. For enchantment level `L`, the pinned parameters produce
#' the normal emerald price
#' `2 + 3L + U`, where `U` is a discrete uniform integer from zero through
#' `4 + 10L`. Treasure prices double before the 64-emerald cap. Offer rows
#' enumerate the resulting price support, and probabilities from every
#' underlying price capped at 64 are combined. Consequently, treasure support
#' is even below the cap and need not contain every integer inside its trade or
#' option minimum--maximum range.
#'
#' Armorers, fishermen, fletchers, toolsmiths, and weaponsmiths use the pinned
#' `enchant_with_levels` model. The source enchanting level is uniform from 5
#' through 19. Mojang's base emerald cost is increased by that selected level,
#' and the enchantment set is generated conditionally on the same value. The
#' updater analytically integrates item enchantability, the two enchantability
#' rolls, the triangular multiplier, weights, conflicts, and
#' additional-enchantment branches. Identical complete sets at the same price
#' are combined without simulation or resampling. The same set at another
#' price shares its `option_id` and receives a distinct `offer_id`.
#'
#' `"documented_model"` means exact probability under the documented model,
#' rather than a guarantee about Bedrock engine constants that Mojang has not
#' published.
#'
#' @section Pinned table details:
#' The librarian master candle group contains three identical red-candle source
#' entries and one yellow-candle entry. They are presented as two rows:
#' red has probability `0.75`, yellow has probability `0.25`, and
#' `num_trades` remains four to preserve the source selection pool.
#'
#' Bed colors use the white-to-black auxiliary-value order. Banner colors use
#' Bedrock's black-to-white metadata order, so `minecraft:banner:0` is black
#' and `minecraft:banner:15` is white.
#'
#' Mojang omits `num_to_select` from the pinned fisherman master group. That
#' group contains the pufferfish trade and one variant-specific boat trade;
#' both are selected. The returned value is therefore `-1`, the trade-table
#' select-all convention. No other omission is accepted by the data updater.
#'
#' The farmer suspicious-stew trade follows the six auxiliary values authored
#' in the pinned table. Option and offer output assign each effect probability
#' `1/6`, including Night Vision. This describes the source table rather than the
#' known Bedrock runtime defect affecting that effect.
#'
#' @section Villager context:
#' Filters are applied before group sizes and probabilities are calculated.
#' Fisherman requires `variant`; cartographer requires both `variant` and
#' `dimension`. Other professions need neither. The function stops when
#' required context is missing rather than assuming Plains or the Overworld.
#'
#' @references
#' [Microsoft, "Creating a Trade Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Trade Group Reference"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/tradetablereference/examples/tradetablecomponents/tradegroup?view=minecraft-bedrock-stable)
#'
#' [Microsoft, "Loot Tables Documentation - Enchanting Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Enchanting table mechanics," revision 3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)
#'
#' [Minecraft Wiki, "Banner metadata"](https://minecraft.wiki/w/Banner#Metadata)
#' @export
#'
#' @examples
#' # Inspect armorer trades.
#' armor <- villager_trades()
#' head(
#'   armor[
#'     ,
#'     c(
#'       'tier',
#'       'wants_1_item',
#'       'gives_1_item',
#'       'offer_probability'
#'     )
#'   ]
#' )
#'
#' # Inspect concrete enchanted armorer options.
#' armor_options <- villager_trades(view = 'option')
#' head(
#'   armor_options[
#'     !is.na(armor_options$gives_1_enchantments),
#'     c(
#'       'wants_1_quantity_min',
#'       'wants_1_quantity_max',
#'       'gives_1_item',
#'       'gives_1_enchantments',
#'       'offer_probability'
#'     )
#'   ]
#' )
#'
#' # Inspect exact Mending book offers.
#' book_offers <- villager_trades('librarian', view = 'offer')
#' head(
#'   book_offers[
#'     grepl(
#'       'minecraft:mending=',
#'       book_offers$gives_1_enchantments,
#'       fixed = TRUE
#'     ),
#'     c(
#'       'gives_1_enchantments',
#'       'wants_1_quantity_min',
#'       'offer_probability'
#'     )
#'   ]
#' )
#'
#' # Inspect context-specific cartographer maps.
#' maps <- villager_trades(
#'   profession = 'cartographer',
#'   variant    = 'snowy',
#'   dimension  = 'overworld'
#' )
#' maps[
#'   !is.na(maps$gives_1_map_destination),
#'   c('tier', 'gives_1_map_destination', 'offer_probability')
#' ]
villager_trades <- function(
  profession = 'armorer',
  view = c('trade', 'option', 'offer'),
  variant = NULL,
  dimension = NULL
) {
  profession <- .normalize_profession_input(profession)
  view       <- .normalize_view_input(view)
  variant    <- .normalize_variant_input(variant)
  dimension  <- .normalize_dimension_input(dimension)
  trades <- switch(
    view,
    trade  = .bedrock_trade_trades,
    option = .bedrock_trade_options,
    offer  = .bedrock_trade_offers
  )
  rows <- trades[trades$profession == profession, , drop = FALSE]
  .require_trade_context(rows, variant, dimension)
  keep <- .context_applies(rows$.variants, variant) &
    .context_applies(rows$.dimensions, dimension)
  rows <- rows[keep, , drop = FALSE]
  if (!nrow(rows)) {
    stop(
      'No trades apply to the requested villager context.',
      call. = FALSE
    )
  }
  for (group_id in unique(rows$group_id)) {
    group_rows <- rows$group_id == group_id
    trade_ids <- unique(rows$trade_id[group_rows])
    rows$num_trades[group_rows] <- sum(vapply(
      trade_ids,
      function(trade_id) {
        unique(rows$.trade_weight[
          group_rows & rows$trade_id == trade_id
        ])
      },
      numeric(1)
    ))
  }
  rows$offer_probability <- .trade_probabilities(rows) *
    .choice_probabilities(rows) *
    rows$.function_probability
  rows$probability_status <- rows$.probability_status
  columns <- switch(
    view,
    trade  = .bedrock_trade_columns,
    option = .bedrock_option_columns,
    offer  = .bedrock_offer_columns
  )
  result <- rows[, columns, drop = FALSE]
  rownames(result) <- NULL
  result
}
