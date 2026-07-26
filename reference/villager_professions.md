# List Supported Villager Professions

Lists the 13 employable vanilla villager professions understood by
`bedrocktrader`. Each row summarizes features found in that profession's
Minecraft Bedrock `1.26.30.5` trade table.

## Usage

``` r
villager_professions()
```

## Value

A base data frame with one row per profession:

- `profession` (`character`) is the canonical input accepted by
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
  and
  [`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md).

- `display_name` (`character`) is the readable profession name.

- `aliases` (`character`) lists additional accepted inputs, separated by
  commas. It is `NA` when no aliases exist.

- `context_sensitive` (`logical`) is `TRUE` when at least one offer uses
  a biome-variant or dimension filter. It does not imply that every
  offer from the profession is conditional.

- `contains_item_choices` (`logical`) is `TRUE` when Mojang supplies an
  item `choice` array.
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
  expands those alternatives.

- `contains_dynamic_functions` (`logical`) is `TRUE` when at least one
  result uses a generator such as enchanting, random dye, potion
  setting, or map creation.

## Details

The function retrieves and verifies all 13 pinned profession tables,
then inspects their source structure. The flags describe version
`1.26.30.5`; they are not permanent claims about later Minecraft
releases.

Canonical names and aliases are case-insensitive when passed to other
package functions. For example, `mason` and `stone_mason` both resolve
to the canonical `stone_mason` profession.

## Examples

``` r
if (FALSE) { # \dontrun{
professions <- villager_professions()
professions

professions[
  professions$contains_dynamic_functions,
  c('profession', 'contains_dynamic_functions')
]

} # }
```
