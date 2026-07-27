# List supported villager professions

Lists the 13 employable vanilla villager professions included in the
Minecraft: Bedrock Edition `1.26.30.5` data model. The feature flags
identify tables that need contextual inputs or contain generated source
instructions.

## Usage

``` r
villager_professions()
```

## Value

A base data frame with one row per profession:

- `profession` (`character`) is the canonical value accepted by
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

- `display_name` (`character`) is the readable profession name.

- `aliases` (`character`) contains additional accepted inputs separated
  by commas. It is `NA` when a profession has no aliases.

- `context_sensitive` (`logical`) is `TRUE` when at least one trade uses
  a villager-variant or dimension filter.

- `contains_item_choices` (`logical`) is `TRUE` when Mojang supplies at
  least one `choice` array.

- `contains_dynamic_functions` (`logical`) is `TRUE` when at least one
  item uses a trade-table function, including enchanting, random
  auxiliary values, potion setting, map creation, or random dye.

## Details

Inputs are case-insensitive. `mason` and `stonemason` resolve to
`stone_mason`; `leather_worker`, `tool_smith`, and `weapon_smith`
likewise resolve to their canonical package identifiers.

`context_sensitive = TRUE` means
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
needs `variant`, `dimension`, or both before it can determine applicable
groups and their probabilities.

These rows are bundled with the package. Calling the function performs
no download and does not inspect a saved world.

## Examples

``` r
# Inspect villager professions.
professions <- villager_professions()
professions
#>       profession  display_name           aliases context_sensitive
#> 1        armorer       Armorer              <NA>             FALSE
#> 2        butcher       Butcher              <NA>             FALSE
#> 3   cartographer  Cartographer              <NA>              TRUE
#> 4         cleric        Cleric              <NA>             FALSE
#> 5         farmer        Farmer              <NA>             FALSE
#> 6      fisherman     Fisherman              <NA>              TRUE
#> 7       fletcher      Fletcher              <NA>             FALSE
#> 8  leatherworker Leatherworker    leather_worker             FALSE
#> 9      librarian     Librarian              <NA>             FALSE
#> 10   stone_mason         Mason mason, stonemason             FALSE
#> 11      shepherd      Shepherd              <NA>             FALSE
#> 12     toolsmith     Toolsmith        tool_smith             FALSE
#> 13   weaponsmith   Weaponsmith      weapon_smith             FALSE
#>    contains_item_choices contains_dynamic_functions
#> 1                  FALSE                       TRUE
#> 2                   TRUE                      FALSE
#> 3                   TRUE                       TRUE
#> 4                   TRUE                      FALSE
#> 5                  FALSE                       TRUE
#> 6                   TRUE                       TRUE
#> 7                   TRUE                       TRUE
#> 8                  FALSE                       TRUE
#> 9                  FALSE                       TRUE
#> 10                  TRUE                      FALSE
#> 11                  TRUE                       TRUE
#> 12                 FALSE                       TRUE
#> 13                 FALSE                       TRUE

# Inspect professions with generated source instructions.
professions[
  professions$contains_dynamic_functions,
  c('profession', 'contains_dynamic_functions')
]
#>       profession contains_dynamic_functions
#> 1        armorer                       TRUE
#> 3   cartographer                       TRUE
#> 5         farmer                       TRUE
#> 6      fisherman                       TRUE
#> 7       fletcher                       TRUE
#> 8  leatherworker                       TRUE
#> 9      librarian                       TRUE
#> 11      shepherd                       TRUE
#> 12     toolsmith                       TRUE
#> 13   weaponsmith                       TRUE
```
