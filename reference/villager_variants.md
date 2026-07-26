# List Villager Variants

Lists the seven vanilla villager biome variants and their stored
`minecraft:mark_variant` values. Trade-table filters use these numeric
values to make certain offers dependent on a villager's variant.

## Usage

``` r
villager_variants(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version
  returned by
  [`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md).
  `"latest"` is resolved when the function is called.

## Value

A base data frame with one row per variant:

- `variant` (`character`) is the canonical package identifier.

- `mark_variant` (`integer`) is the value stored by Mojang's
  `minecraft:mark_variant` entity component and tested by vanilla
  `is_mark_variant` filters.

- `aliases` (`character`) contains additional accepted names separated
  by commas. `NA` means that the variant has no aliases. The `snow`
  variant has the alias `snowy`.

## Details

Values are derived from the selected release's vanilla `villager_v2`
entity definition rather than assumed from a fixed lookup table. This
function does not determine the variant of a particular villager.

## Examples

``` r
if (FALSE) { # \dontrun{
variants <- villager_variants()
variants

variants[variants$variant == 'snow', ]

villager_variants(version = '1.26.30.5')
} # }
```
