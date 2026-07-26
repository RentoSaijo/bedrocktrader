# Calculate Villager Offer Probabilities

Calculates the marginal probability that each possible offer appears
when a Minecraft Bedrock `1.26.30.5` villager's trades are generated.

## Usage

``` r
offer_probabilities(
  profession = "armorer",
  level = "novice",
  scope = c("tier", "unlocked"),
  variant = NULL,
  dimension = NULL
)
```

## Arguments

- profession:

  One canonical profession identifier or alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`.

- level:

  One level given as an integer from 1 through 5 or as `novice`,
  `apprentice`, `journeyman`, `expert`, or `master`.

- scope:

  `"tier"` to analyze only `level`, or `"unlocked"` to include that
  level and every earlier level. Earlier offers remain available after a
  villager advances.

- variant:

  Villager biome variant when the requested offers depend on one. Use
  [`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
  to inspect canonical values and aliases.

- dimension:

  Dimension when the requested offers depend on one: `"overworld"`,
  `"nether"`, or `"end"`.

## Value

A base data frame with one row per applicable outcome and 26 atomic
columns:

- `profession`, `level`, `level_name`, `group_id`, `trade_id`, and
  `option_id` identify the same row described by
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

- `variants` and `dimensions` (`character`) preserve the row's
  contextual restrictions. `NA` means unrestricted.

- `result_item` (`character`), `result_aux_value` (`integer`),
  `result_color`, `result_effect`, `potion`, `map_destination`,
  `enchantment`, and `enchantment_name` (`character`) identify the
  outcome. Fields that do not apply are typed `NA`.

- `enchantment_level` (`integer`) is the offered book level, otherwise
  `NA`.

- `cost_1_quantity_min` and `cost_1_quantity_max` (`double`) identify
  the first cost range, including modeled Librarian emerald prices.

- `outcome_status` (`character`) is copied from
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

- `selection_probability` (`double`) is the chance that the source trade
  is selected from its group.

- `choice_probability` (`double`) is the conditional chance of the
  explicit item-choice combination after applying context.

- `generator_probability` (`double`) is the conditional chance of the
  generated row. It is one when the engine outcome remains unresolved.

- `probability` (`double`) is the product of those three components.

- `probability_status` (`character`) is `exact`, `documented_model`, or
  `partial`.

- `probability_basis` (`character`) identifies whether the calculation
  comes from the source table, the documented Librarian model, or a
  source table with an unresolved engine outcome.

## Details

The returned probability is marginal: it is the chance that one row
appears among a villager's generated offers. Rows generally do not sum
to one because a level can contain several groups and a group can select
several trades. Options sharing a `trade_id` divide that trade's
probability rather than behaving as separate candidates.

A group that selects `k` of `n` applicable trades gives each trade
marginal probability `k / n`. Select-all groups give each trade
probability one. Explicit item alternatives and integer
`random_aux_value` outcomes are treated as uniform among the choices
that apply to the requested context.

Librarian books use a documented model. One of 39 eligible enchantments
is selected uniformly, followed by one valid level selected uniformly.
For an enchantment with maximum level `m`, its generator probability is
`1 / 39 / m`. Soul Speed, Swift Sneak, and Wind Burst are excluded. The
probability is marginal over every emerald price in the displayed range;
price rolls are not separate rows.

`enchant_with_levels` and `random_dye` require game-engine logic that
the pinned static data cannot reproduce completely. Their row
probabilities are exact only through selection and explicit choices, so
their `probability_status` is `partial`.

Context is required only when the requested levels contain filtered
offers. For example, Cartographer map availability can depend on both
villager variant and dimension. The function stops instead of silently
assuming Plains or the Overworld.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Tutorial:
Trading"](https://minecraft.wiki/w/Tutorial%3ATrading)

[Bedrock Wiki, "Trade
Tables"](https://wiki.bedrock.dev/loot/trade-tables.html)

## Examples

``` r
if (FALSE) { # \dontrun{
novice <- offer_probabilities()
novice[
  ,
  c(
    'result_item',
    'selection_probability',
    'probability'
  )
]

books <- offer_probabilities('librarian')
books[
  !is.na(books$enchantment) & books$enchantment == 'mending',
  c(
    'enchantment_name',
    'enchantment_level',
    'probability',
    'probability_status'
  )
]

maps <- offer_probabilities(
  profession = 'cartographer',
  level      = 'apprentice',
  variant    = 'snowy',
  dimension  = 'overworld'
)
maps[
  ,
  c('map_destination', 'variants', 'probability')
]
} # }
```
