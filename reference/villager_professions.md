# List Supported Villager Professions

Retrieves and inspects all supported vanilla profession tables from one
stable Mojang release.

## Usage

``` r
villager_professions(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version.

## Value

A base data frame containing canonical profession identifiers, display
names, aliases, and structural feature flags. `context_sensitive` marks
tables with variant or dimension filters. `contains_item_choices` marks
tables with Mojang item `choice` arrays. `contains_dynamic_functions`
marks tables with item-generation functions.

## Examples

``` r
if (FALSE) { # \dontrun{
villager_professions()
villager_professions('1.26.30.5')
} # }
```
