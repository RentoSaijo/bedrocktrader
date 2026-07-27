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

Compact rows keep generated details together and may report a quantity range:

```r
library(bedrocktrader)

armor <- villager_trades()

armor[
  armor$gives_1_item == 'minecraft:diamond_helmet',
  c(
    'wants_1_quantity_min',
    'wants_1_quantity_max',
    'gives_1_item',
    'offer_probability'
  )
]
```

Expanded rows describe one exact outcome and price:

```r
enchanted_armor <- villager_trades(expanded = TRUE)

head(
  enchanted_armor[
    enchanted_armor$gives_1_item == 'minecraft:diamond_helmet',
    c(
      'wants_1_quantity_min',
      'gives_1_enchantments',
      'offer_probability'
    )
  ]
)
```

Minecraft organizes these possibilities as:

```text
tier -> group -> trade -> option
```

A group selects one or more trades. Explicit item choices form separate base
rows. Compact probabilities are marginal over collapsed outcomes, whereas an
expanded option's probability covers its exact items, specifications, and
price.

Use `villager_professions()`, `villager_variants()`, and `villager_tiers()` to
inspect accepted metadata. The
[`villager_trades()` reference](reference/villager_trades.html)
explains every column, contextual inputs, probabilities, and modeling limits.

## Source and license

The bundled values come from Mojang's immutable
[`v1.26.30.5` Bedrock Samples release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and are verified against pinned Git blob SHAs during development.

The R code is GPL-3-or-later. Values derived from Mojang's samples remain
subject to [Mojang's license notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula).
`bedrocktrader` is independent of Mojang and Microsoft.
