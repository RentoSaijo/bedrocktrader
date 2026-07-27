# Calculate Enchanted Item Probability

Calculates the probability that a fully unlocked villager offers one
qualifying enchanted equipment item in Minecraft Bedrock `1.26.30.5`.

## Usage

``` r
enchanted_item_probability(
  item,
  enchantments,
  profession = NULL,
  max_emeralds = 64,
  include_higher_level = FALSE,
  match = c("exact", "contains")
)
```

## Arguments

- item:

  One supported short item name or canonical Minecraft item ID.

- enchantments:

  Comma-separated `identifier=level` pairs. The `minecraft:` namespace
  is optional.

- profession:

  Required for diamond axes; use `"toolsmith"` or `"weaponsmith"`. Other
  items infer their profession.

- max_emeralds:

  Inclusive original emerald-price cutoff from 0 through 64.

- include_higher_level:

  `FALSE` requires every requested level. `TRUE` treats each requested
  level as a minimum.

- match:

  `"exact"` requires the complete enchantment set to contain only the
  requested enchantments. `"contains"` permits additional enchantments.

## Value

One numeric probability from 0 through 1.

## Items and professions

Short names are `helmet`, `chestplate`, `leggings`, `boots`, `sword`,
`axe`, `pickaxe`, `shovel`, `bow`, `crossbow`, and `fishing_rod`. Armor,
swords, axes, pickaxes, and shovels refer to their diamond forms. Their
corresponding namespaced item IDs are also accepted. Iron equipment is
outside this analysis interface.

Profession is inferred as Armorer, Fisherman, Fletcher, Toolsmith, or
Weaponsmith. Diamond axes appear in two profession tables, so
`profession` is required for that item. The Toolsmith trade is selected
with probability `1/2`; the Weaponsmith trade is guaranteed. Profession
aliases accepted by
[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md)
remain valid.

## Enchantment matching

Input follows the atomic representation returned by
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md),
for example `minecraft:efficiency=2,minecraft:unbreaking=1`. Whitespace
and pair order do not matter, capitalization is normalized, and
`minecraft:` may be omitted. Display names are not accepted;
[`enchantments()`](https://rentosaijo.github.io/bedrocktrader/reference/enchantments.md)
lists canonical identifiers and valid levels.

With `match = "exact"`, the modeled item must have exactly the requested
enchantment identifiers. With `match = "contains"`, every requested
enchantment must appear, but unrequested enchantments may also occur.
When `include_higher_level = TRUE`, either rule accepts levels at or
above each requested value.

Recognized but impossible conditions return zero. This includes
item-inapplicable enchantments and incompatible combinations such as
Fortune with Silk Touch. Malformed pairs, unknown identifiers, repeated
identifiers, and levels outside the registry produce errors.

## Probability and price

The result includes source-trade selection and the complete documented
`enchant_with_levels` distribution for the requested item. It sums the
exact offers whose enchantment set and original emerald price meet the
query.

`max_emeralds` is evaluated before demand, curing, or other adjustments.
Its default of `64` includes every modeled equipment price. It is a
budget filter, not a prediction of the price after curing; price
multipliers differ across equipment trades.

The returned value is exact under the documented model described in
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md),
rather than a guarantee about undocumented Bedrock internals.

## References

[Microsoft, "Loot Tables Documentation - Enchanting
Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Enchanting table mechanics," revision
3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)

## Examples

``` r
enchanted_item_probability('sword', 'sharpness=3')
#> [1] 0.006747492

enchanted_item_probability(
  item                 = 'pickaxe',
  enchantments         = 'efficiency=2',
  include_higher_level = TRUE,
  match                = 'contains'
)
#> [1] 0.5698418

enchanted_item_probability(
  item         = 'axe',
  enchantments = 'efficiency=2,unbreaking=1',
  profession   = 'weaponsmith',
  match        = 'contains'
)
#> [1] 0.007448404
```
