# List Villager Variants

Lists the seven vanilla villager biome variants and their stored
`minecraft:mark_variant` values in Minecraft Bedrock `1.26.30.5`.

## Usage

``` r
villager_variants()
```

## Value

A base data frame with one row per variant:

- `variant` (`character`) is the canonical package identifier.

- `mark_variant` (`integer`) is the value stored by Mojang's
  `minecraft:mark_variant` entity component. Vanilla `is_mark_variant`
  filters compare against this value.

- `aliases` (`character`) lists additional accepted inputs, separated by
  commas. It is `NA` when no aliases exist.

## Details

Values are read from the pinned vanilla `villager_v2.json` entity
definition. The canonical snowy-biome identifier is `snow`; `snowy` is
an accepted alias in
[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md).
This function describes available codes and does not inspect a
saved-world villager.

## Examples

``` r
if (FALSE) { # \dontrun{
variants <- villager_variants()
variants

variants[variants$variant == 'snow', ]

} # }
```
