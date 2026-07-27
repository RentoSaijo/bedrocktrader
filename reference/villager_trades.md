# Retrieve Villager Trades

Returns the possible vanilla trades for one profession in Minecraft
Bedrock `1.26.30.5`, together with the probability represented at the
requested trade, option, or offer resolution.

## Usage

``` r
villager_trades(
  profession = "armorer",
  view = c("trade", "option", "offer"),
  variant = NULL,
  dimension = NULL
)
```

## Arguments

- profession:

  One canonical profession or alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`; `"all"` is not a profession value.

- view:

  Resolution of the returned rows. `"trade"` summarizes generated
  specifications and prices, `"option"` resolves item specifications
  while retaining price bounds, and `"offer"` resolves exact
  specifications and prices.

- variant:

  One villager biome variant when the profession has variant-dependent
  trades. Use
  [`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
  for canonical values and aliases.

- dimension:

  One of `"overworld"`, `"nether"`, or `"end"` when the profession has
  dimension-dependent trades.

## Value

A plain base data frame containing only atomic columns. Trade results
contain 29 columns. Option results add `option_id` after `trade_id`, for
30 columns. Offer results add `offer_id` after `option_id`, for 31
columns.

## Hierarchical views

Minecraft trade tables follow `tier -> group -> trade`; the package
extends that structure as `trade_id -> option_id -> offer_id`. Explicit
Mojang item choices remain separate rows so every `wants` and `gives`
field stays atomic.

`view = "trade"` returns 281 base item-choice combinations from 182
authored source entries across the pinned tables. Generated details
remain summarized, so a Librarian book row covers every modeled
enchantment, level, and price. A `trade_id` can repeat when Mojang
supplies explicit item choices.

`view = "option"` returns 2,787 concrete item specifications. For
example, one enchanted-equipment option names its complete enchantment
set while its emerald columns span every price that can produce that
set. The probability is marginal over those prices.

`view = "offer"` returns 30,592 exact configurations. Each populated
quantity minimum equals its maximum, and `offer_probability` covers the
displayed items, specification, and price jointly. Offers are grouped by
option and sorted by price.

Fixed potion and exploration-map instructions resolve in every view
because they do not create alternatives. `random_dye` remains one
partial row because its color distribution is not established by the
pinned sources.

## Identity and selection columns

- `profession` (`character`) is the canonical profession.

- `tier` (`integer`) is the numeric trading tier. Join it to
  [`villager_tiers()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_tiers.md)
  for its name and experience requirement.

- `group_id` (`character`) identifies a pool of possible source trades.

- `num_trades` (`integer`) counts source entries that apply to the
  requested context in that group. Item and function expansions do not
  increase it; repeated identical entries still count because they
  affect selection probability.

- `num_to_select` (`integer`) is Mojang's number of trades selected from
  the group. `-1` means every applicable trade is selected.

- `trade_id` (`character`) identifies one source trade. Explicit
  item-choice rows share this identifier.

- `option_id` (`character`) identifies one concrete item specification.
  It appears in option and offer views and repeats across an option's
  prices.

- `offer_id` (`character`) uniquely identifies an exact configuration.
  It appears only in the offer view.

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

Trade rows span every modeled price when a function changes the emerald
cost. Option rows provide the bounds for one item specification; those
bounds do not promise that every interior integer is attainable. Offer
rows have equal minima and maxima and therefore identify exact modeled
prices. All returned values precede demand, curing, and Hero of the
Village adjustments.

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
  sword carrying both enchantments. It is `NA` on trade-view generated
  rows and ordinary items.

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
applicable source entries gives an ordinary source trade probability
`k / n`; select-all groups give every source trade probability one.
Identical source entries are treated as repeated ways to obtain the same
trade. Explicit choices and generated outcomes then contribute their
conditional probabilities.

Rows do not generally sum to one. A tier can contain several groups and
can therefore add several offers. A trade row is marginal over its
generated item specifications and prices. An option row is marginal over
prices for one specification. An offer row gives the joint probability
of one specification and exact price. Summing offers recovers their
option probability; summing options recovers the corresponding
trade-view row.

`probability_status` (`character`) describes the calculation:

- `"exact"` covers source-table selection, explicit choices, legacy
  data-value outcomes, fixed potions, and maps.

- `"documented_model"` covers Librarian books and complete enchanted
  equipment sets.

- `"partial"` marks `random_dye`, whose exact leather-color distribution
  is not established by the pinned sources.

## Enchantment models

Each Librarian book trade draws uniformly from 39 eligible enchantments,
then draws uniformly from the selected enchantment's valid levels. This
gives 116 enchantment-level combinations. Soul Speed, Swift Sneak, and
Wind Burst are excluded. For enchantment level `L`, the pinned
parameters produce the normal emerald price `2 + 3L + U`, where `U` is a
discrete uniform integer from zero through `4 + 10L`. Treasure prices
double before the 64-emerald cap. Offer rows enumerate the resulting
price support, and probabilities from every underlying price capped at
64 are combined. Consequently, treasure support is even below the cap
and need not contain every integer inside its trade or option
minimum–maximum range.

Armorers, Fishermen, Fletchers, Toolsmiths, and Weaponsmiths use the
pinned `enchant_with_levels` model. The source enchanting level is
uniform from 5 through 19. Mojang's base emerald cost is increased by
that selected level, and the enchantment set is generated conditionally
on the same value. The updater analytically integrates item
enchantability, the two enchantability rolls, the triangular multiplier,
weights, conflicts, and additional-enchantment branches. Identical
complete sets at the same price are combined without simulation or
resampling. The same set at another price shares its `option_id` and
receives a distinct `offer_id`.

`"documented_model"` means exact probability under the documented model,
rather than a guarantee about Bedrock engine constants that Mojang has
not published.

## Pinned table details

The Librarian master candle group contains three identical red-candle
source entries and one yellow-candle entry. They are presented as two
rows: red has probability `0.75`, yellow has probability `0.25`, and
`num_trades` remains four to preserve the source selection pool.

Bed colors use the white-to-black auxiliary-value order. Banner colors
use Bedrock's black-to-white metadata order, so `minecraft:banner:0` is
black and `minecraft:banner:15` is white.

Mojang omits `num_to_select` from the pinned Fisherman master group.
That group contains the pufferfish trade and one variant-specific boat
trade; both are selected. The returned value is therefore `-1`, the
trade-table select-all convention. No other omission is accepted by the
data updater.

The Farmer suspicious-stew trade follows the six auxiliary values
authored in the pinned table. Option and offer output assign each effect
probability `1/6`, including Night Vision. This describes the source
table rather than the known Bedrock runtime defect affecting that
effect.

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

[Minecraft Wiki, "Banner
metadata"](https://minecraft.wiki/w/Banner#Metadata)

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

armor_options <- villager_trades(view = 'option')
head(
  armor_options[
    !is.na(armor_options$gives_1_enchantments),
    c(
      'wants_1_quantity_min',
      'wants_1_quantity_max',
      'gives_1_item',
      'gives_1_enchantments',
      'offer_probability'
    )
  ]
)
#>    wants_1_quantity_min wants_1_quantity_max               gives_1_item
#> 15                   19                   27 minecraft:diamond_leggings
#> 16                   19                   27 minecraft:diamond_leggings
#> 17                   19                   27 minecraft:diamond_leggings
#> 18                   19                   27 minecraft:diamond_leggings
#> 19                   20                   33 minecraft:diamond_leggings
#> 20                   20                   33 minecraft:diamond_leggings
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

book_offers <- villager_trades('librarian', view = 'offer')
head(
  book_offers[
    grepl(
      'minecraft:mending=',
      book_offers$gives_1_enchantments,
      fixed = TRUE
    ),
    c(
      'gives_1_enchantments',
      'wants_1_quantity_min',
      'offer_probability'
    )
  ]
)
#>      gives_1_enchantments wants_1_quantity_min offer_probability
#> 1875  minecraft:mending=1                   10      0.0008547009
#> 1876  minecraft:mending=1                   12      0.0008547009
#> 1877  minecraft:mending=1                   14      0.0008547009
#> 1878  minecraft:mending=1                   16      0.0008547009
#> 1879  minecraft:mending=1                   18      0.0008547009
#> 1880  minecraft:mending=1                   20      0.0008547009

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
