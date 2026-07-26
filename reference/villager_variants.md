# List Villager Variants

Retrieves the vanilla villager entity definition from one stable Mojang
release and derives its seven stored `mark_variant` values.

## Usage

``` r
villager_variants(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version.

## Value

A base data frame containing canonical variant identifiers, vanilla
`mark_variant` values, and aliases.

## Examples

``` r
if (FALSE) { # \dontrun{
villager_variants()
villager_variants('1.26.30.5')
} # }
```
