# bedrocktrader

Villager trade tables pack a surprising amount of structure into a small slice
of Minecraft. Tiers contain selection groups; candidates may contain item
choices, dynamic functions, and filters tied to the villager's stored variant.
`bedrocktrader` retrieves that official vanilla Bedrock data and arranges it
consistently for analysis in R.

The current development release provides a focused data foundation for all 13
employable villager professions. Each result identifies the exact upstream
release, Git commit, source path, blob SHA, retrieval time, and parser version.

## Installation

Install the development version from [GitHub](https://github.com/) with:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

## Retrieve Villager Data

```r
library(bedrocktrader)

villager_professions()
villager_variants()

farmer <- villager_trades('farmer')
farmer

source_info(farmer)
```

Use Mojang's current stable release at call time or request a specific stable
version:

```r
bedrocktrader_data_version()

mason <- villager_trades(
  'mason',
  version = '1.26.30.5'
)
```

The package contacts Mojang's GitHub repository for every top-level retrieval.
It verifies each downloaded file against the release manifest and does not
write a cache.

## Development Boundary

This iteration retrieves and normalizes source data. It does not yet calculate
offer probabilities, evaluate villager context, build trade catalogs, produce
plots, or accept custom trade tables. Those features can grow from a compact,
auditable source model instead of being layered over an unstable parser.

Mojang data remains subject to the
[Minecraft End User License Agreement](https://www.minecraft.net/eula).
`bedrocktrader` is independent of Mojang and Microsoft.
