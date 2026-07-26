# List Villager Variants

Lists vanilla villager biome variants and their `minecraft:mark_variant`
values for Minecraft Bedrock `1.26.30.5`.

## Usage

``` r
villager_variants()
```

## Value

A base data frame with seven rows:

- `variant` (`character`) is the canonical package identifier.

- `mark_variant` (`integer`) is Mojang's `minecraft:mark_variant`
  component value. Vanilla `is_mark_variant` filters compare against
  this number.

- `aliases` (`character`) contains additional accepted inputs separated
  by commas. It is `NA` when no aliases exist.

## Details

The canonical cold-biome identifier is `snow`, matching the pinned
entity definition. `snowy` remains an accepted convenience alias in
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

The values come from the bundled `villager_v2.json` model; the function
neither downloads data nor examines villagers in a saved world.

## Examples

``` r
variants <- villager_variants()
variants
#>   variant mark_variant aliases
#> 1  plains            0    <NA>
#> 2  desert            1    <NA>
#> 3  jungle            2    <NA>
#> 4 savanna            3    <NA>
#> 5    snow            4   snowy
#> 6   swamp            5    <NA>
#> 7   taiga            6    <NA>

variants[variants$variant == 'snow', ]
#>   variant mark_variant aliases
#> 5    snow            4   snowy
```
