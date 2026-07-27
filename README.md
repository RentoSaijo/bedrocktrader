# bedrocktrader

`bedrocktrader` brings vanilla Minecraft villager trades into R as ordinary
base data frames. The package bundles normalized data for **Minecraft Bedrock
Edition 1.26.30.5** and works entirely offline.

## Installation

Install the development version from GitHub:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

## Quick start

Choose the resolution that matches the question:

```r
library(bedrocktrader)

helmet_options <- villager_trades(view = 'option')

head(
  helmet_options[
    helmet_options$gives_1_item == 'minecraft:diamond_helmet',
    c(
      'gives_1_enchantments',
      'wants_1_quantity_min',
      'wants_1_quantity_max',
      'offer_probability'
    )
  ]
)

enchanted_book_probability('mending=1', max_emeralds = 26)
```

Minecraft organizes these possibilities as:

```text
tier -> group -> trade -> option -> offer
```

The trade view summarizes generated details and prices. The option view names
one concrete item specification while retaining price bounds. The offer view
separates every exact specification and price.

Use `villager_professions()`, `villager_variants()`, `villager_tiers()`, and
`enchantments()` to inspect accepted metadata. The
[`villager_trades()` reference](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.html)
explains every column and view. Detailed help for
[`enchanted_book_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_book_probability.html)
and
[`enchanted_item_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_item_probability.html)
covers the analysis queries.

## Source and license

The bundled values come from Mojang's immutable
[`v1.26.30.5` Bedrock Samples release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and are verified against pinned Git blob SHAs during development.

The R code is GPL-3-or-later. Values derived from Mojang's samples remain
subject to [Mojang's license notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula).
`bedrocktrader` is independent of Mojang and Microsoft.
