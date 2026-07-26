# bedrocktrader

## Overview

Minecraft Bedrock villager trades begin as nested game data: each profession
has five levels, each level has groups of possible trades, and several offers
depend on item choices or game-generated outcomes. `bedrocktrader` turns that
structure into ordinary base R data frames that are ready to inspect and
analyze.

This development release supports **Minecraft Bedrock Edition 1.26.30.5
only**. Pinning one release lets the package provide a complete, checked
enchantment model without implying that the same rules apply to later game
versions. A future package release can advance the pin after its data and
mechanics have been reviewed.

## Installation

Install the development version from GitHub:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

Then load the package:

```r
library(bedrocktrader)
```

Every function retrieves Mojang's pinned files online when called. There is no
disk or session cache. Set `GITHUB_PAT` when authenticated GitHub access is
available.

## Quick Start

The Meta functions introduce the villagers represented by the package:

```r
villager_professions()
villager_variants()
```

The Data function returns possible offers. It defaults to every Armorer level;
use a number or name to focus on one:

```r
armorer <- villager_trades()
expert  <- villager_trades('armorer', level = 'expert')
```

Read each row through the same hierarchy:

```text
level -> group -> trade -> option
```

A group selects one or more trades. An option is a concrete row produced when
a trade contains item alternatives or a modeled outcome. Thus, several rows
can share a `trade_id` without representing independently selected offers.

The cost and result columns read from the player's perspective:

```r
armorer[
  ,
  c(
    'level_name',
    'cost_1_item',
    'cost_1_quantity_min',
    'cost_1_quantity_max',
    'result_item',
    'outcome_status'
  )
]
```

Librarian books are expanded by enchantment and level. Their emerald price is
a range because Minecraft rolls the price after choosing the book:

```r
books <- villager_trades('librarian', level = 'novice')

books[
  !is.na(books$enchantment) & books$enchantment == 'mending',
  c(
    'enchantment_name',
    'enchantment_level',
    'cost_1_quantity_min',
    'cost_1_quantity_max'
  )
]
```

`offer_probabilities()` separates selection, item-choice, and generated-outcome
probabilities. The combined probability is the marginal chance that a row
appears; rows need not sum to one because a villager can receive several
offers.

```r
mending <- offer_probabilities('librarian')

mending[
  !is.na(mending$enchantment) & mending$enchantment == 'mending',
  c('enchantment_name', 'probability', 'probability_status')
]
```

See the function reference for the complete column dictionary, contextual
Cartographer examples, probability assumptions, and the boundary between
resolved and engine-generated outcomes.

## Source and License

Trade and entity files come from Mojang's immutable
[`v1.26.30.5` Bedrock Samples release](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5).
The package verifies each download against a pinned Git blob SHA.

The R code is licensed under GPL-3-or-later. Mojang data is retrieved at
runtime, is not redistributed with the package, and remains subject to
Mojang's terms and the
[Minecraft EULA](https://www.minecraft.net/eula). `bedrocktrader` is an
independent project and is not affiliated with Mojang or Microsoft.
