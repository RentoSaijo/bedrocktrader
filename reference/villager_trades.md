# Retrieve Villager Trades

Retrieves one official vanilla profession table for Minecraft Bedrock
`1.26.30.5` and turns its nested definitions into concrete, readable
rows.

## Usage

``` r
villager_trades(profession = "armorer", level = NULL)
```

## Arguments

- profession:

  One canonical profession identifier or an alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`.

- level:

  `NULL` for all five levels, or one level given as an integer from 1
  through 5 or as `novice`, `apprentice`, `journeyman`, `expert`, or
  `master`.

## Value

A base data frame with one row per concrete item-choice or modeled
enchantment-level outcome and 42 atomic columns.

## How to read a row

A profession contains five levels. A level contains groups, and each
group selects one or more source trades. A trade can then expand into
several options because it offers alternative items, random auxiliary
values, or a modeled enchanted book.

`group_id` identifies the selection pool. `trade_id` identifies one
source trade inside that group and can repeat after expansion.
`option_id` uniquely identifies each returned row. Options sharing a
`trade_id` are alternative realizations of one trade; they are not
independently selected offers.

The table is a catalog of possible definitions rather than the inventory
of a particular villager in a saved world. Use
[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md)
to apply context and calculate marginal appearance probabilities.

## Progression and selection

- `profession` (`character`) is the canonical profession identifier.

- `level` (`integer`) and `level_name` (`character`) identify the tier.

- `total_exp_required` (`double`) is the cumulative experience the
  villager needs to unlock that tier.

- `group_id`, `trade_id`, and `option_id` (`character`) identify the
  group, source trade, and expanded row.

- `trades_in_group` (`integer`) counts source trades before expansion.

- `trades_selected` (`integer`) is how many source trades the group adds
  to a villager.

- `all_trades_selected` (`logical`) records Mojang's select-all
  convention. Source `num_to_select = -1`, including an omitted
  property, is presented as the actual trade count with this flag set to
  `TRUE`.

## Applicability

- `variants` (`character`) lists allowed villager biome variants,
  separated by commas.

- `dimensions` (`character`) lists allowed dimensions.

`NA` means that the source imposes no restriction on that axis. These
columns describe applicability; `villager_trades()` does not remove rows
for a particular context.

## Player costs

`cost_1_` describes the first item paid by the player; `cost_2_`
describes an optional second item. Each prefix has:

- `item` (`character`) for the Mojang item identifier.

- `aux_value` (`integer`) for a numeric auxiliary suffix, otherwise
  `NA`.

- `quantity_min` and `quantity_max` (`double`) for the possible amount.

- `price_multiplier` (`double`) for demand-driven price adjustment; `NA`
  when Mojang omits it.

Every `cost_2_` field is typed `NA` for a one-input trade. Equal
quantity bounds indicate a fixed cost. Librarian emerald bounds include
the `enchant_book_for_trading` generator, but do not include later
demand, curing, or Hero of the Village adjustments.

## Result

- `result_item` (`character`) is the item received by the player.

- `result_aux_value` (`integer`) records a concrete legacy variation.

- `result_quantity_min` and `result_quantity_max` (`double`) give its
  amount.

- `result_color`, `result_effect`, `potion`, and `map_destination`
  (`character`) describe resolved color, suspicious-stew effect,
  tipped-arrow potion, or exploration-map destination. They are `NA`
  when inapplicable.

- `enchantment` and `enchantment_name` (`character`) identify a modeled
  librarian book.

- `enchantment_level` and `enchantment_max_level` (`integer`) give the
  offered level and that enchantment's maximum.

- `treasure` (`logical`) indicates a treasure enchantment. It is `NA`
  for results without an enchanting generator.

Omitted item quantities normalize to one, following the trade-table
format. Other omitted Mojang properties remain typed `NA`; the package
does not silently substitute game defaults.

## Generators

- `generator` (`character`) names the source function, or is `NA`.

- `enchanting_power_min` and `enchanting_power_max` (`double`) preserve
  the level-power inputs to `enchant_with_levels`. They are not
  enchantment levels.

- `outcome_status` (`character`) is `source_resolved`,
  `documented_model`, or `engine_generated`.

Explicit item choices, potions, map destinations, suspicious-stew
effects, and bed/banner colors are source-resolved. Librarian enchanted
books use a documented model: 39 equally likely enchantments, followed
by an equally likely valid level. Soul Speed, Swift Sneak, and Wind
Burst are excluded. Each enchanted-book source trade therefore expands
to 116 rows.

Normal librarian emerald ranges are 5–19 for level I, 8–32 for II, 11–45
for III, 14–58 for IV, and 17–64 for V. Treasure costs double before the
64-emerald cap. Each row covers every price inside its displayed range;
prices are not expanded into separate rows.

`enchant_with_levels` can produce multiple compatible enchantments
through the Bedrock engine, and `random_dye` can generate arbitrary
leather colors. Those rows remain `engine_generated` rather than
claiming unsupported concrete outcomes.

## Trade behavior

- `max_uses` (`double`) is the number of completed uses before the offer
  locks until restocking.

- `villager_exp` (`double`) is experience gained by the villager.

- `player_exp` (`logical`) records whether the player receives
  experience.

These fields are `NA` when Mojang omits the corresponding property.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Tutorial:
Trading"](https://minecraft.wiki/w/Tutorial%3ATrading)

## Examples

``` r
if (FALSE) { # \dontrun{
armorer <- villager_trades(level = 'novice')
armorer[
  ,
  c(
    'level_name',
    'cost_1_item',
    'cost_1_quantity_min',
    'result_item'
  )
]

books <- villager_trades('librarian', level = 1)
books[
  !is.na(books$enchantment) & books$enchantment == 'mending',
  c(
    'enchantment_name',
    'cost_1_quantity_min',
    'cost_1_quantity_max'
  )
]

mason <- villager_trades('mason', level = 'journeyman')
mason[
  ,
  c('group_id', 'trade_id', 'option_id', 'result_item')
]
} # }
```
