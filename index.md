# bedrocktrader

Villager trade tables pack a surprising amount of structure into a small
slice of Minecraft. Tiers contain selection groups; candidates may
contain item choices, dynamic functions, and filters tied to the
villager’s stored variant. `bedrocktrader` retrieves that official
vanilla Bedrock data and arranges it consistently for analysis in R.

The current development release provides a focused data foundation for
all 13 employable villager professions. It expands Mojang item choices
into ordinary base R data frames while keeping quantities, functions,
filters, auxiliary values, and selection structure available as columns.

## Installation

Install the development version from [GitHub](https://github.com/) with:

``` r

install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

## Retrieve Villager Data

``` r

library(bedrocktrader)

bedrock_versions()
villager_professions()
villager_variants()

armorer <- villager_trades()
head(armorer)
```

Use Mojang’s current stable release at call time or request a specific
stable version:

``` r

mason <- villager_trades(
  'mason',
  version = '1.26.30.5'
)
```

The package contacts Mojang’s GitHub repository for every top-level
retrieval. Supported stable releases begin with `1.26.20.4`;
[`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md)
lists every stable release from that floor through Mojang’s runtime
latest version. Each downloaded file is verified against the release
manifest, and no cache is written.

## Profession Indicators

The profession table includes three quick structural indicators.
`context_sensitive` identifies variant or dimension filters,
`contains_item_choices` identifies Mojang `choice` arrays, and
`contains_dynamic_functions` identifies item-generation functions such
as enchantments, potions, dyes, or exploration maps.

## Development Boundary

This iteration retrieves, normalizes, and flattens source data. It does
not yet calculate offer probabilities, evaluate villager context,
produce plots, or accept custom trade tables. Those features can grow
from a compact source model instead of being layered over an unstable
parser.

Mojang data remains subject to the [Minecraft End User License
Agreement](https://www.minecraft.net/eula). `bedrocktrader` is
independent of Mojang and Microsoft.
