# Calculate Villager Offer Probabilities

Calculates the marginal probability that each possible outcome appears
among a Minecraft Bedrock `1.26.30.5` villager's generated offers. The
returned components distinguish trade selection, explicit item choices,
and item-function outcomes.

## Usage

``` r
offer_probabilities(
  profession = "armorer",
  tier = "novice",
  scope = c("tier", "unlocked"),
  variant = NULL,
  dimension = NULL
)
```

## Arguments

- profession:

  One canonical profession or alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`.

- tier:

  One integer from 1 through 5 or one of `"novice"`, `"apprentice"`,
  `"journeyman"`, `"expert"`, and `"master"`.

- scope:

  `"tier"` to analyze only `tier`, or `"unlocked"` to include that tier
  and every earlier tier.

- variant:

  Villager biome variant when the requested trades depend on one. Use
  [`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
  for canonical values and aliases.

- dimension:

  Dimension when the requested trades depend on one: `"overworld"`,
  `"nether"`, or `"end"`.

## Value

A plain base data frame containing all 40 columns documented by
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
followed by:

- `trade_probability` (`double`) is the marginal chance that Mojang
  selects the source trade from its group.

- `choice_probability` (`double`) is the conditional chance of the
  applicable source `choice` combination.

- `function_probability` (`double`) is the conditional chance of the
  resolved or modeled item-function outcome.

- `offer_probability` (`double`) is the product of the preceding three
  components.

- `probability_status` (`character`) is `"exact"`, `"documented_model"`,
  or `"partial"`.

- `probability_basis` (`character`) identifies the source-table or
  modeling basis used for the function component.

## Interpreting an offer probability

A group selecting `k` of `n` applicable source trades gives each trade
marginal probability `k / n`. A select-all group gives every trade
probability one. Explicit item choices divide a source trade's
probability; expanded options sharing a `trade_id` do not become
additional trade candidates.

The overall value is marginal: it answers whether that row appears among
a villager's offers. Rows do not generally sum to one because a tier
contains several groups and can add several offers. With
`scope = "unlocked"`, the result includes every tier available to a
villager at the requested rank.

## Librarian model

`enchant_book_for_trading` chooses one of 39 eligible enchantments
uniformly and then chooses one of that enchantment's valid levels
uniformly. An enchantment with maximum level `m` therefore has function
probability `1 / 39 / m` at each level. Soul Speed, Swift Sneak, and
Wind Burst are excluded from this pinned pool.

Emerald prices remain inclusive ranges rather than separate
price-specific rows. Price therefore does not contribute another
probability component.

## Enchanted-equipment model

Armorers, Fishermen, Fletchers, Toolsmiths, and Weaponsmiths use
`enchant_with_levels`. For each source trade, the model:

1.  selects an integer source level `L` uniformly from 5 through 19;

2.  calculates modified power `round((L + 1 + R1 + R2) * M)`, where each
    `R` is uniform from zero through `floor(enchantability / 4)` and `M`
    follows the documented triangular distribution from 0.85 through
    1.15;

3.  finds the highest eligible level of each compatible non-treasure
    enchantment;

4.  selects by enchantment weight, removes conflicts, and repeats with
    continuation chance `(power + 1) / 50`, halving power between
    additional selections.

The updater integrates the triangular distribution analytically and
enumerates every weighted selection branch. It does not use simulation,
cross-validation, or resampling. Identical complete enchantment sets are
combined, and their probabilities sum to one within each equipment
generator.

These rows receive `probability_status = "documented_model"`. Their
probabilities are exact under the cited model, while the label
acknowledges that Mojang does not publish every Bedrock engine constant
in the pinned sample repository.

## Exact, modeled, and partial rows

- `"exact"` covers outcomes fully determined by Mojang's trade tables,
  including direct items, choices, integer auxiliary values, maps, and
  potions.

- `"documented_model"` covers Librarian books and complete enchanted
  equipment sets.

- `"partial"` currently covers `random_dye`. Its row represents the
  unresolved dyed-leather outcome, so `function_probability = 1` refers
  to that category rather than a particular color.

## Context

Filters alter which choices and source trades apply before probabilities
are calculated. The function requests `variant`, `dimension`, or both
only when the selected tiers depend on that context. It stops instead of
silently assuming Plains or the Overworld.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Enchanting table mechanics," revision
3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)

## Examples

``` r
novice <- offer_probabilities()
novice[
  ,
  c(
    'gives_1_item',
    'trade_probability',
    'offer_probability'
  )
]
#>                gives_1_item trade_probability offer_probability
#> 1         minecraft:emerald              1.00              1.00
#> 2   minecraft:iron_leggings              0.25              0.25
#> 3      minecraft:iron_boots              0.25              0.25
#> 4     minecraft:iron_helmet              0.25              0.25
#> 5 minecraft:iron_chestplate              0.25              0.25

bows <- offer_probabilities('fletcher', tier = 'expert')
head(
  bows[
    order(bows$offer_probability, decreasing = TRUE),
    c(
      'gives_1_enchantments',
      'function_probability',
      'offer_probability'
    )
  ]
)
#>                        gives_1_enchantments function_probability
#> 1                                      <NA>           1.00000000
#> 46                        minecraft:power=2           0.25334209
#> 44                        minecraft:power=1           0.18362116
#> 60                   minecraft:unbreaking=1           0.12349125
#> 61                   minecraft:unbreaking=2           0.09499037
#> 51 minecraft:power=2,minecraft:unbreaking=2           0.09058050
#>    offer_probability
#> 1         1.00000000
#> 46        0.25334209
#> 44        0.18362116
#> 60        0.12349125
#> 61        0.09499037
#> 51        0.09058050

books <- offer_probabilities('librarian')
books[
  grepl('minecraft:mending=', books$gives_1_enchantments, fixed = TRUE),
  c(
    'gives_1_enchantments',
    'wants_1_quantity_min',
    'wants_1_quantity_max',
    'offer_probability'
  )
]
#>    gives_1_enchantments wants_1_quantity_min wants_1_quantity_max
#> 71  minecraft:mending=1                   10                   38
#>    offer_probability
#> 71        0.01282051

maps <- offer_probabilities(
  profession = 'cartographer',
  tier       = 'apprentice',
  variant    = 'snowy',
  dimension  = 'overworld'
)
maps[
  ,
  c(
    'gives_1_map_destination',
    'variants',
    'offer_probability'
  )
]
#>   gives_1_map_destination                     variants offer_probability
#> 1                    <NA>                         <NA>               0.5
#> 2           village_taiga          plains, snow, swamp               0.5
#> 3               swamp_hut          jungle, snow, taiga               0.5
#> 4          village_plains desert, savanna, snow, taiga               0.5
```
