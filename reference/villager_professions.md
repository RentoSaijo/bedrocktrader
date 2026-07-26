# List Supported Villager Professions

Lists the 13 employable vanilla villager professions understood by
`bedrocktrader`. Each row also summarizes trade-table features that may
need special handling during analysis.

## Usage

``` r
villager_professions(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version
  returned by
  [`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md).
  `"latest"` is resolved when the function is called.

## Value

A base data frame with one row per profession:

- `profession` (`character`) is the canonical identifier accepted by
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

- `display_name` (`character`) is the human-readable profession name.

- `aliases` (`character`) contains additional accepted identifiers
  separated by commas. `NA` means that the profession has no aliases.

- `context_sensitive` (`logical`) is `TRUE` when at least one offer uses
  a villager-variant or dimension filter. Such offers are not available
  in every context.

- `contains_item_choices` (`logical`) is `TRUE` when at least one item
  position contains Mojang's `choice` array.
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
  expands those alternatives into separate rows.

- `contains_dynamic_functions` (`logical`) is `TRUE` when at least one
  item-generation function changes an offered item, such as by adding an
  enchantment, potion, dye, or exploration-map destination.

## Details

The feature flags describe the selected release, not permanent
properties of a profession. To calculate them, the function downloads
and inspects all 13 profession tables. It does not evaluate filters or
generate function outcomes.

## Examples

``` r
if (FALSE) { # \dontrun{
professions <- villager_professions()
professions

professions[
  professions$context_sensitive,
  c('profession', 'context_sensitive')
]

villager_professions(version = '1.26.30.5')
} # }
```
