# bedrocktrader

`bedrocktrader` brings vanilla Minecraft villager trades into R as
ordinary base data frames. The package bundles normalized data for
**Minecraft Bedrock Edition 1.26.30.5** and works entirely offline.

## Installation

Install the development version from GitHub:

``` r

install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

## Quick start

The compact table keeps one row for each base item choice:

``` r

library(bedrocktrader)

armor <- villager_trades()

head(
  armor[
    ,
    c(
      'tier',
      'wants_1_item',
      'gives_1_item',
      'offer_probability'
    )
  ]
)
```

Set `expanded = TRUE` to separate modeled enchantments and other
generated outcomes:

``` r

enchanted_armor <- villager_trades(expanded = TRUE)

head(
  enchanted_armor[
    !is.na(enchanted_armor$gives_1_enchantments),
    c(
      'gives_1_item',
      'gives_1_enchantments',
      'offer_probability'
    )
  ]
)
```

Minecraft organizes these possibilities as:

``` text
tier -> group -> trade -> option
```

A group selects one or more trades. Explicit item choices form separate
base rows, while an expanded option describes one enchantment set,
color, effect, or other modeled outcome from its source trade.

Use
[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md),
[`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md),
and
[`villager_tiers()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_tiers.md)
to inspect accepted metadata. The [`villager_trades()`
reference](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
explains every column, contextual inputs, probabilities, and modeling
limits.

## Source and license

The bundled values come from Mojang’s immutable [`v1.26.30.5` Bedrock
Samples
release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and are verified against pinned Git blob SHAs during development.

The R code is GPL-3-or-later. Values derived from Mojang’s samples
remain subject to [Mojang’s license
notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula).
`bedrocktrader` is independent of Mojang and Microsoft.
