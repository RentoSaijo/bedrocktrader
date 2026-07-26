# Retrieve Villager Trades

Returns the possible vanilla trades for one profession in Minecraft
Bedrock `1.26.30.5`, together with the marginal probability that each
displayed row appears among a villager's offers.

## Usage

``` r
villager_trades(
  profession = "armorer",
  expanded = FALSE,
  variant = NULL,
  dimension = NULL
)
```

## Arguments

- profession:

  One canonical profession or alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`; `"all"` is not a profession value.

- expanded:

  `FALSE` returns base item-choice combinations. `TRUE` separates
  modeled enchantments, random legacy data values, and other
  reconstructable function outcomes.

- variant:

  One villager biome variant when the profession has variant-dependent
  trades. Use
  [`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
  for canonical values and aliases.

- dimension:

  One of `"overworld"`, `"nether"`, or `"end"` when the profession has
  dimension-dependent trades.

## Value

A plain base data frame containing only atomic columns. Compact results
contain 29 columns. Expanded results add `option_id` immediately after
`trade_id`, for 30 columns.

## Compact and expanded rows

Minecraft trade tables follow `tier -> group -> trade`. Explicit Mojang
item choices create separate base rows so each `wants` and `gives` field
remains a single value.

With `expanded = FALSE`, generated details remain collapsed into their
base row. For example, a Librarian enchanted-book row describes the full
emerald range but does not name one enchantment. Its probability is the
chance that the base item combination appears, marginal over every
function outcome.

With `expanded = TRUE`, each reconstructable function outcome receives
its own row and `option_id`. Repeated `trade_id` values remain
alternatives from one source trade; they are not additional candidates
in a group.

Fixed potion and exploration-map functions resolve to one value in
either form because they do not create alternative outcomes.
`random_dye` cannot be reconstructed faithfully from the pinned sources
and remains one partial expanded row.

## Identity and selection columns

- `profession` (`character`) is the canonical profession.

- `tier` (`integer`) is the numeric trading tier. Join it to
  [`villager_tiers()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_tiers.md)
  for its name and experience requirement.

- `group_id` (`character`) identifies a pool of possible source trades.

- `num_trades` (`integer`) counts source trades that apply to the
  requested context in that group. Item and function expansions do not
  increase it.

- `num_to_select` (`integer`) is Mojang's number of trades selected from
  the group. `-1` means every applicable trade is selected.

- `trade_id` (`character`) identifies one source trade.

- `option_id` (`character`) uniquely identifies an expanded row and is
  present only when `expanded = TRUE`.

The identifiers are stable within the pinned package release and do not
appear in Mojang's source files.

## Wants columns

`wants_1_*` describes the first item the villager wants from the player;
`wants_2_*` describes an optional second item. Each slot contains:

- `item` (`character`) is Mojang's namespaced identifier. Legacy data
  suffixes remain attached, as in `minecraft:coal:0`.

- `quantity_min` and `quantity_max` (`double`) are inclusive bounds.
  Equal values describe a fixed quantity.

- `price_multiplier` (`double`) controls supply-and-demand price
  increases.

Every `wants_2_*` field is typed `NA` for a one-item payment. An omitted
quantity becomes one, while an omitted price multiplier on an existing
item becomes Mojang's documented default of `0.05`.

Librarian emerald bounds incorporate `enchant_book_for_trading`. Compact
rows span all modeled enchantments and levels; expanded rows give the
range for the displayed enchantment. These values precede demand,
curing, and Hero of the Village adjustments.

## Gives columns

- `gives_1_item` (`character`) is the namespaced item given to the
  player.

- `gives_1_quantity_min` and `gives_1_quantity_max` (`double`) give the
  inclusive amount range.

- `gives_1_color`, `gives_1_effect`, `gives_1_potion`, and
  `gives_1_map_destination` (`character`) give a resolved color,
  suspicious stew effect, potion identifier, or exploration-map
  destination. Each is `NA` when the specification does not apply or
  remains collapsed.

- `gives_1_enchantments` (`character`) records a complete enchantment
  set as sorted `minecraft:id=level` pairs separated by commas. For
  example, `minecraft:sharpness=2,minecraft:unbreaking=1` describes one
  sword carrying both enchantments. It is `NA` on compact generated rows
  and ordinary items.

- `gives_1_treasure` (`logical`) indicates whether the set contains a
  treasure enchantment. It is `NA` when no single treasure status
  applies.

## Generation and behavior columns

- `functions` (`character`) names the Mojang item function or is `NA`.
  Mojang defines `functions` as an array; the supported vanilla rows
  contain at most one result function.

- `max_uses` (`double`) is the number of completed trades before the
  offer locks until restocking.

- `trader_exp` (`double`) is experience gained by the villager.

- `reward_exp` (`logical`) says whether the player receives experience.

When Mojang omits these properties, the package returns the documented
runtime defaults: 12 uses, one trader experience point, and player
experience enabled.

## Offer probability

`offer_probability` (`double`) is the marginal chance that the displayed
row appears among the villager's offers. A group selecting `k` of `n`
applicable trades gives each source trade probability `k / n`;
select-all groups give every source trade probability one. Explicit
choices and expanded function outcomes then contribute their conditional
probabilities.

Rows do not generally sum to one. A tier can contain several groups and
can therefore add several offers. Compact probabilities do equal the sum
of the corresponding expanded probabilities.

`probability_status` (`character`) describes the calculation:

- `"exact"` covers source-table selection, explicit choices, legacy
  data-value outcomes, fixed potions, and maps.

- `"documented_model"` covers Librarian books and complete enchanted
  equipment sets.

- `"partial"` marks `random_dye`, whose exact leather-color distribution
  is not established by the pinned sources.

## Enchantment models

Each expanded Librarian book trade has 116 enchantment-level outcomes
drawn from 39 eligible enchantments. Enchantment is uniform first; level
is then uniform within that enchantment. Soul Speed, Swift Sneak, and
Wind Burst are excluded. Normal emerald ranges are 5–19 for level I,
8–32 for II, 11–45 for III, 14–58 for IV, and 17–64 for V. Treasure
prices double before the 64-emerald cap.

Armorers, Fishermen, Fletchers, Toolsmiths, and Weaponsmiths use the
pinned `enchant_with_levels` model. The updater analytically integrates
enchanting power from 5 through 19, item enchantability, weights,
conflicts, and additional-enchantment branches. Identical complete sets
are combined without simulation or resampling.

`"documented_model"` means exact probability under the documented model,
rather than a guarantee about Bedrock engine constants that Mojang has
not published.

## Villager context

Filters are applied before group sizes and probabilities are calculated.
Fisherman requires `variant`; Cartographer requires both `variant` and
`dimension`. Other professions need neither. The function stops when
required context is missing rather than assuming Plains or the
Overworld.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

[Microsoft, "Trade Group
Reference"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/tradetablereference/examples/tradetablecomponents/tradegroup?view=minecraft-bedrock-stable)

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Enchanting table mechanics," revision
3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)

## Examples

``` r
armor <- villager_trades()
head(
  armor[
    ,
    c(
      'tier',
      'wants_1_item',
      'gives_1_item',
      'offer_probability'
    )
  ]
)
#>   tier         wants_1_item              gives_1_item offer_probability
#> 1    1     minecraft:coal:0         minecraft:emerald              1.00
#> 2    1    minecraft:emerald   minecraft:iron_leggings              0.25
#> 3    1    minecraft:emerald      minecraft:iron_boots              0.25
#> 4    1    minecraft:emerald     minecraft:iron_helmet              0.25
#> 5    1    minecraft:emerald minecraft:iron_chestplate              0.25
#> 6    2 minecraft:iron_ingot         minecraft:emerald              1.00

enchanted_armor <- villager_trades(expanded = TRUE)
head(
  enchanted_armor[
    !is.na(enchanted_armor$gives_1_enchantments),
    c(
      'gives_1_item',
      'gives_1_enchantments',
      'offer_probability'
    )
  ]
)
#>                  gives_1_item
#> 15 minecraft:diamond_leggings
#> 16 minecraft:diamond_leggings
#> 17 minecraft:diamond_leggings
#> 18 minecraft:diamond_leggings
#> 19 minecraft:diamond_leggings
#> 20 minecraft:diamond_leggings
#>                                                      gives_1_enchantments
#> 15                                           minecraft:blast_protection=1
#> 16                        minecraft:blast_protection=1,minecraft:thorns=1
#> 17 minecraft:blast_protection=1,minecraft:thorns=1,minecraft:unbreaking=1
#> 18                    minecraft:blast_protection=1,minecraft:unbreaking=1
#> 19                                           minecraft:blast_protection=2
#> 20                        minecraft:blast_protection=2,minecraft:thorns=1
#>    offer_probability
#> 15      0.0105131839
#> 16      0.0003051833
#> 17      0.0002780594
#> 18      0.0030375988
#> 19      0.0122614313
#> 20      0.0010950188

books <- villager_trades('librarian', expanded = TRUE)
books[
  grepl('minecraft:mending=', books$gives_1_enchantments, fixed = TRUE),
  c(
    'gives_1_enchantments',
    'wants_1_quantity_min',
    'wants_1_quantity_max'
  )
]
#>     gives_1_enchantments wants_1_quantity_min wants_1_quantity_max
#> 71   minecraft:mending=1                   10                   38
#> 189  minecraft:mending=1                   10                   38
#> 307  minecraft:mending=1                   10                   38
#> 426  minecraft:mending=1                   10                   38

maps <- villager_trades(
  profession = 'cartographer',
  variant    = 'snowy',
  dimension  = 'overworld'
)
maps[
  !is.na(maps$gives_1_map_destination),
  c('tier', 'gives_1_map_destination', 'offer_probability')
]
#>    tier gives_1_map_destination offer_probability
#> 4     2           village_taiga         0.5000000
#> 5     2               swamp_hut         0.5000000
#> 6     2          village_plains         0.5000000
#> 8     3                monument         0.6666667
#> 9     3          trial_chambers         0.6666667
#> 17    5                 mansion         1.0000000
```
