# bedrocktrader

### Overview

bedrocktrader is an R package to access and analyze vanilla villager trades from
**Minecraft Bedrock Edition 1.26.30.5**. It bundles normalized professions,
variants, tiers, enchantments, and modeled trade outcomes as ordinary base R
data frames, so every public function works offline without GitHub credentials.
The package follows Mojang's `tiers`, `groups`, `trades`, `wants`, and `gives`
terminology while making the possible offers and their probabilities easier to
inspect.

### Installation

Install the development version from [GitHub](https://github.com/) with:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

### Usage

Minecraft organizes trading possibilities as
`tier -> group -> trade -> option -> offer`. The trade view summarizes generated
specifications and prices, the option view resolves one concrete item
specification while retaining its price bounds, and the offer view separates
every exact specification and price. For example, the following code inspects
enchanted diamond helmets and calculates the probability that a fully unlocked
librarian offers Mending for no more than 26 emeralds:

```r
library(bedrocktrader)

armorer_options <- villager_trades(
  profession = 'armorer',
  view       = 'option'
)
helmet_options <- armorer_options[
  armorer_options$gives_1_item == 'minecraft:diamond_helmet',
  c(
    'gives_1_enchantments',
    'wants_1_quantity_min',
    'wants_1_quantity_max',
    'offer_probability'
  )
]
head(helmet_options)

mending_probability <- enchanted_book_probability(
  enchantment  = 'minecraft:mending=1',
  max_emeralds = 26
)
mending_probability
```

Use `villager_professions()`, `villager_variants()`, `villager_tiers()`, and
`enchantments()` to inspect the bundled metadata. The
[`villager_trades()` reference](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.html)
explains every column and view, while the references for
[`enchanted_book_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_book_probability.html)
and
[`enchanted_item_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_item_probability.html)
document their assumptions and matching rules. The accompanying
[mathematics note](https://github.com/RentoSaijo/bedrocktrader/blob/main/other/math.pdf)
develops the probability model in full.

### Source and license

The bundled values come from Mojang's immutable
[`v1.26.30.5` Bedrock Samples release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and are verified against pinned Git blob SHAs during development. The R code is
GPL-3-or-later; values derived from Mojang's samples remain subject to
[Mojang's license notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula). bedrocktrader is
independent of Mojang and Microsoft.
