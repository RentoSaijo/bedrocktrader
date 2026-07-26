# Retrieve Villager Trades

Returns possible vanilla trade outcomes for one profession in Minecraft
Bedrock `1.26.30.5`. Item choices, integer auxiliary-value ranges,
Librarian books, and enchanted equipment are expanded into separate
rows.

## Usage

``` r
villager_trades(profession = "armorer", tier = NULL)
```

## Arguments

- profession:

  One canonical profession or alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`; `"all"` is not a profession value.

- tier:

  `NULL` for all five tiers, or one integer from 1 through 5 or one of
  `"novice"`, `"apprentice"`, `"journeyman"`, `"expert"`, and
  `"master"`.

## Value

A plain base data frame with one row per possible option and 40 atomic
columns.

## Reading the hierarchy

Minecraft trade tables follow `tier -> group -> trade`. `bedrocktrader`
adds `option` for a concrete expansion of one source trade.

`group_id` identifies a pool from which trades are selected. `trade_id`
identifies one source trade and therefore repeats when that trade has
several item choices or generated outcomes. `option_id` uniquely
identifies each returned row. Repeated `trade_id` values are
alternatives from the same trade rather than separate candidates in the
group.

The result describes every possible definition for a profession, not one
villager's realized inventory. Use
[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md)
to apply context and calculate appearance probabilities.

## Progression and selection columns

- `profession` (`character`) is the canonical profession.

- `tier` (`integer`) and `tier_name` (`character`) identify the trade
  tier.

- `total_exp_required` (`double`) is the cumulative experience the
  trader needs to unlock the tier.

- `group_id`, `trade_id`, and `option_id` (`character`) identify the
  source group, source trade, and expanded option.

- `num_trades` (`integer`) counts source trades in the group before
  expansion.

- `num_to_select` (`double`) preserves Mojang's selection instruction.
  `-1` is the select-all convention.

- `select_all` (`logical`) makes the `num_to_select = -1` convention
  explicit.

## Applicability columns

- `variants` (`character`) lists allowed villager variants separated by
  commas.

- `dimensions` (`character`) lists allowed dimensions.

`NA` means that Mojang imposes no restriction on that axis.
`villager_trades()` preserves all possibilities rather than assuming
Plains or the Overworld.

## Wants columns

`wants_1_*` describes the first item requested from the player.
`wants_2_*` describes an optional second item. Both slots use:

- `item` (`character`) for the namespaced Minecraft item identifier.

- `aux_value` (`integer`) for a legacy numeric item suffix, otherwise
  `NA`.

- `quantity_min` and `quantity_max` (`double`) for the inclusive
  quantity range. Equal bounds indicate a fixed amount.

- `price_multiplier` (`double`) for demand-driven price adjustment; it
  is `NA` when Mojang omits the property.

All five `wants_2_*` fields are typed `NA` for a one-input trade.
Librarian emerald bounds include `enchant_book_for_trading`, but exclude
later demand, curing, and Hero of the Village adjustments.

## Gives columns

- `gives_1_item` (`character`) is the namespaced item given to the
  player.

- `gives_1_aux_value` (`integer`) is a resolved legacy item suffix.

- `gives_1_quantity_min` and `gives_1_quantity_max` (`double`) give the
  inclusive amount range.

- `gives_1_color`, `gives_1_effect`, `gives_1_potion`, and
  `gives_1_map_destination` (`character`) identify resolved bed or
  banner color, suspicious-stew effect, potion, or exploration-map
  destination.

- `gives_1_enchantments` (`character`) records a complete enchantment
  set as sorted `minecraft:id=level` pairs separated by commas. For
  example, `minecraft:sharpness=2,minecraft:unbreaking=1` describes one
  sword carrying both enchantments.

- `gives_1_enchantment_count` (`integer`) counts enchantments in that
  set.

- `gives_1_treasure` (`logical`) indicates whether the set contains a
  treasure enchantment.

The enchantment fields are `NA` for ordinary items. Omitted quantities
normalize to one according to the trade-table format; other absent
source properties remain typed `NA`.

## Function columns

- `functions` (`character`) names the Mojang item function, or is `NA`.

- `levels_min` and `levels_max` (`double`) preserve the inclusive
  `levels` range supplied to `enchant_with_levels`; they are source
  enchanting-power inputs, not enchantment levels on the finished item.

- `outcome_status` (`character`) is `source_resolved`,
  `documented_model`, or `engine_generated`.

Direct items, explicit choices, integer `random_aux_value` outcomes,
potions, and map destinations are `source_resolved`. Librarian books and
enchanted equipment are `documented_model`. `random_dye` remains
`engine_generated`, so its leather color is unresolved.

Each Librarian book trade expands to 116 enchantment-level options.
Normal emerald ranges are 5–19 for level I, 8–32 for II, 11–45 for III,
14–58 for IV, and 17–64 for V. Treasure prices double before the
64-emerald cap.

Equipment rows represent complete enchantment sets, including
multi-enchant items sold by Armorers, Fishermen, Fletchers, Toolsmiths,
and Weaponsmiths. Their source emerald amount remains fixed across
generated sets.

## Trade behavior columns

- `max_uses` (`double`) is the number of completed trades before the
  offer locks until restocking.

- `trader_exp` (`double`) is experience gained by the villager.

- `reward_exp` (`logical`) says whether the player receives experience.

These fields remain `NA` when Mojang omits the corresponding property;
the package does not insert documented game defaults.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Enchanting table mechanics," revision
3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)

## Examples

``` r
novice <- villager_trades(tier = 'novice')
novice[
  ,
  c(
    'wants_1_item',
    'wants_1_quantity_min',
    'gives_1_item'
  )
]
#>        wants_1_item wants_1_quantity_min              gives_1_item
#> 1    minecraft:coal                   15         minecraft:emerald
#> 2 minecraft:emerald                    7   minecraft:iron_leggings
#> 3 minecraft:emerald                    4      minecraft:iron_boots
#> 4 minecraft:emerald                    5     minecraft:iron_helmet
#> 5 minecraft:emerald                    9 minecraft:iron_chestplate

armor <- villager_trades('armorer', tier = 'expert')
head(
  armor[
    !is.na(armor$gives_1_enchantments),
    c(
      'gives_1_item',
      'gives_1_enchantments',
      'wants_1_quantity_min'
    )
  ]
)
#>                 gives_1_item
#> 1 minecraft:diamond_leggings
#> 2 minecraft:diamond_leggings
#> 3 minecraft:diamond_leggings
#> 4 minecraft:diamond_leggings
#> 5 minecraft:diamond_leggings
#> 6 minecraft:diamond_leggings
#>                                                     gives_1_enchantments
#> 1                                           minecraft:blast_protection=1
#> 2                        minecraft:blast_protection=1,minecraft:thorns=1
#> 3 minecraft:blast_protection=1,minecraft:thorns=1,minecraft:unbreaking=1
#> 4                    minecraft:blast_protection=1,minecraft:unbreaking=1
#> 5                                           minecraft:blast_protection=2
#> 6                        minecraft:blast_protection=2,minecraft:thorns=1
#>   wants_1_quantity_min
#> 1                   14
#> 2                   14
#> 3                   14
#> 4                   14
#> 5                   14
#> 6                   14

books <- villager_trades('librarian', tier = 'novice')
books[
  grepl('minecraft:mending=', books$gives_1_enchantments, fixed = TRUE),
  c(
    'gives_1_enchantments',
    'wants_1_quantity_min',
    'wants_1_quantity_max'
  )
]
#>    gives_1_enchantments wants_1_quantity_min wants_1_quantity_max
#> 71  minecraft:mending=1                   10                   38
```
