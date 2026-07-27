<br>

<div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem;">
<a href="https://rentosaijo.github.io/bedrocktrader/">
<img src="man/figures/logo.png" width="100" alt="bedrocktrader logo"/>
</a>
<h2 style="margin: 0;"><strong>bedrocktrader</strong></h2>
</div>

### Overview

bedrocktrader is an R package to access and analyze vanilla villager trades from
**Minecraft: Bedrock Edition 1.26.30.5**. It connects Mojang's authored trade
tables to concrete item specifications and exact prices through three linked
views: `trade`, `option`, and `offer`. The package also supplies metadata for
professions, variants, tiers, and enchantments, and calculates the probability
that a fully unlocked villager offers selected enchanted books or equipment.

### Installation

Install the development version from [GitHub](https://github.com/) with:

```r
# Install package.
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
# Load package.
library(bedrocktrader)

# Inspect enchanted diamond helmet options.
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

# Calculate Mending probability.
mending_probability <- enchanted_book_probability(
  enchantment  = 'minecraft:mending=1',
  max_emeralds = 26
)
mending_probability
```

Use `villager_professions()`, `villager_variants()`, `villager_tiers()`, and
`enchantments()` to inspect the bundled metadata. The
[`villager_trades()` reference](reference/villager_trades.html)
explains every column and view, while the references for
[`enchanted_book_probability()`](reference/enchanted_book_probability.html)
and [`enchanted_item_probability()`](reference/enchanted_item_probability.html)
document their assumptions and matching rules. The accompanying
[mathematics note](https://github.com/RentoSaijo/bedrocktrader/blob/main/other/math.pdf)
develops the probability model in full.

### Source and License

The bundled values come from Mojang's immutable
[`v1.26.30.5` Bedrock Samples release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
and are verified against pinned Git blob SHAs during development. Normalized
data and modeled outcomes ship with the package, so its public functions work
offline without GitHub credentials. The R code is GPL-3-or-later; values
derived from Mojang's samples remain subject to
[Mojang's license notice](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
and the [Minecraft EULA](https://www.minecraft.net/en-us/eula). bedrocktrader is
independent of Mojang and Microsoft.
