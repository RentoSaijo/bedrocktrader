# bedrocktrader

`bedrocktrader` makes vanilla villager trade data approachable from R.
It turns Minecraft’s nested trade tables into ordinary base data frames,
expands item choices and modeled enchantments, and calculates the chance
that each outcome appears among a villager’s offers.

This development release supports **Minecraft Bedrock Edition 1.26.30.5
only**. Its normalized data is bundled with the package, so every public
function works offline without `GITHUB_PAT`.

## Installation

Install the development version from GitHub:

``` r

install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

Then inspect an Armorer’s expert-tier outcomes:

``` r

library(bedrocktrader)

armor <- villager_trades(tier = 'expert')

armor[
  ,
  c(
    'wants_1_item',
    'wants_1_quantity_min',
    'gives_1_item',
    'gives_1_enchantments'
  )
]
```

Read the data through Minecraft’s own hierarchy:

``` text
tier -> group -> trade -> option
```

A group selects one or more trades. A trade can expand into several
options when it contains item choices or generated outcomes.
Consequently, rows that share a `trade_id` describe alternatives from
the same source trade rather than independently selected offers.

Use
[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md)
and
[`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
to discover accepted inputs.
[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md)
adds the trade-selection, item-choice, function, and overall
probabilities to the same outcome rows.

Complete column definitions and examples live in
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.html)
and
[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.html).

## Source and License

The bundled values were generated from Mojang’s immutable [`v1.26.30.5`
Bedrock Samples
release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and verified against pinned Git blob SHAs. Equipment enchantments follow
the documented Bedrock enchanting-table model described in the function
reference.

The R code is licensed under GPL-3-or-later. Values derived from
Mojang’s samples remain subject to [Mojang’s license
notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula).
`bedrocktrader` is independent of Mojang and Microsoft.
