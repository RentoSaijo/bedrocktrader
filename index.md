# bedrocktrader

## Overview

A villager's trading screen is simple; the table behind it is not. Minecraft
Bedrock organizes possible offers by villager level, divides them into selection
groups, and may vary their items by biome, dimension, random choice, or an
item-generation function. `bedrocktrader` retrieves those official vanilla
tables from Mojang and turns them into ordinary base R data frames.

The package has two parts:

- **Meta** identifies supported Bedrock releases, professions, and villager
  variants.
- **Data** describes every possible offer in one profession table.

The returned trade data is a catalog of possibilities. It does not reproduce
the realized offers of a particular villager in a saved world, calculate offer
probabilities, or resolve dynamic outcomes such as enchantments.

## Installation

Install the development version from GitHub with:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

Then load the package:

```r
library(bedrocktrader)
```

## Quick Start

The four public functions return base R data frames:

```r
bedrock_versions()
villager_professions()
villager_variants()

armorer <- villager_trades()
```

`villager_trades()` defaults to the Armorer profession and Mojang's latest
stable release. A stable version can be requested when the source should remain
fixed:

```r
farmer <- villager_trades(
  profession = 'farmer',
  version    = '1.26.30.5'
)
```

## Meta

### Supported versions

`bedrock_versions()` lists the stable releases that the package can read,
newest first.

| Column | Type | Meaning |
|---|---|---|
| `version` | character | Bedrock version accepted by the other functions |
| `release_date` | Date | Release date recorded in Mojang's registry |
| `latest` | logical | Whether the row is Mojang's current latest stable release |

Support begins with `1.26.20.4`. Preview releases are excluded. Because
`"latest"` is resolved when a function is called, use a version from this table
when an analysis must return to the same upstream release later.

### Villager professions

`villager_professions()` returns one row for each of the 13 employable vanilla
professions.

```r
professions <- villager_professions(version = '1.26.30.5')
professions
```

| Column | Type | Meaning |
|---|---|---|
| `profession` | character | Canonical identifier accepted by `villager_trades()` |
| `display_name` | character | Human-readable profession name |
| `aliases` | character | Additional accepted identifiers, separated by commas; `NA` when none exist |
| `context_sensitive` | logical | At least one offer uses a villager-variant or dimension filter |
| `contains_item_choices` | logical | At least one item position contains Mojang's `choice` array |
| `contains_dynamic_functions` | logical | At least one item is modified by an item-generation function |

The feature flags describe the selected release. For example,
`context_sensitive = TRUE` warns that some rows require a particular biome
variant or dimension; it does not mean that every offer from the profession is
conditional.

Aliases are valid inputs. These two calls retrieve the same profession:

```r
mason_1 <- villager_trades('stone_mason')
mason_2 <- villager_trades('mason')
```

### Villager variants

`villager_variants()` connects readable biome names with Mojang's stored
`minecraft:mark_variant` values.

```r
variants <- villager_variants(version = '1.26.30.5')
variants
```

| Column | Type | Meaning |
|---|---|---|
| `variant` | character | Canonical package identifier |
| `mark_variant` | integer | Value stored by Mojang and queried by vanilla `is_mark_variant` filters |
| `aliases` | character | Additional names, separated by commas; `NA` when none exist |

The canonical snowy-biome identifier is `snow`; `snowy` is its alias. These
values describe the villager's biome appearance and can also control
context-sensitive trades.

## Data

`villager_trades()` returns a profession's complete vanilla trade table. To
understand one row, follow the source hierarchy:

1. A **level** is one of the five villager tiers, from Novice through Master.
2. Each level contains one or more **groups** of candidate trades.
3. `num_to_select` says how many candidates from a group become offers. A value
   of `-1` means that all candidates are selected.
4. A **candidate** defines what the player pays and what the villager supplies.
5. When an item position contains several choices, each concrete combination
   becomes an **option** row.

In short, `group_id` locates the selection pool, `candidate_id` locates a trade
inside that pool, and `option_id` identifies one row after item choices have
been expanded. A repeated `candidate_id` therefore signals alternative item
realizations rather than several independently selected trades.

### Start with a simple offer

The three item-slot prefixes describe the exchange from the player's
perspective:

- `wants_1_` is the first item the player pays.
- `wants_2_` is an optional second item the player pays.
- `gives_1_` is the item supplied by the villager.

Select a few columns to make the Armorer table read like the in-game exchange:

```r
armorer <- villager_trades(
  profession = 'armorer',
  version    = '1.26.30.5'
)

armorer[
  ,
  c(
    'level_name',
    'wants_1_item',
    'wants_1_quantity_min',
    'wants_1_quantity_max',
    'gives_1_item',
    'gives_1_quantity_min',
    'gives_1_quantity_max'
  )
]
```

When a minimum and maximum are equal, the quantity is fixed. Different bounds
describe a range from which Minecraft chooses the amount.

### Read two-item costs, functions, and filters

Cartographers illustrate several richer mechanisms. Some map offers require
both emeralds and a compass:

```r
cartographer <- villager_trades(
  profession = 'cartographer',
  version    = '1.26.30.5'
)

two_inputs <- !is.na(cartographer$wants_2_item)

cartographer[
  two_inputs,
  c(
    'level_name',
    'wants_1_item',
    'wants_1_quantity_min',
    'wants_2_item',
    'wants_2_quantity_min',
    'gives_1_item'
  )
]
```

An exploration-map function determines the map destination, while filters
limit the contexts in which an option applies. Both structures remain
unevaluated JSON so no source detail is discarded:

```r
function_row <- which(!is.na(cartographer$gives_1_functions))[[1L]]

cartographer[
  function_row,
  c(
    'gives_1_functions',
    'gives_1_function_parameters',
    'gives_1_filters'
  )
]

jsonlite::fromJSON(
  cartographer$gives_1_function_parameters[[function_row]]
)

jsonlite::fromJSON(
  cartographer$gives_1_filters[[function_row]]
)
```

The objects in `function_parameters` align, in order, with the comma-separated
names in `functions`. Inside `filters`, the top-level key `position` or `choice`
records where Mojang attached the condition.

### Recognize expanded item choices

Mason's Journeyman table provides a compact choice example. One source
candidate accepts granite, diorite, or andesite, so it appears as three option
rows:

```r
mason <- villager_trades(
  profession = 'mason',
  version    = '1.26.30.5'
)

mason[
  mason$candidate_id == 'stone_mason_l3_g1_c1',
  c(
    'group_id',
    'candidate_id',
    'option_id',
    'num_to_select',
    'select_all',
    'wants_1_item',
    'gives_1_item'
  )
]
```

All three rows share a `candidate_id`, but each has a distinct `option_id`.
Meanwhile, `num_to_select = -1` and `select_all = TRUE` indicate that every
candidate in the surrounding group is selected. Choice expansion and group
selection are separate parts of the table.

### Trade-level columns

The first 13 fields describe progression, selection, and behavior:

| Column | Type | Meaning |
|---|---|---|
| `profession` | character | Canonical profession identifier |
| `level` | integer | Numeric tier from 1 through 5 |
| `level_name` | character | `novice`, `apprentice`, `journeyman`, `expert`, or `master` |
| `total_exp_required` | double | Cumulative experience the villager needs to unlock the level |
| `group_id` | character | Package-generated identifier for one selection group |
| `candidate_id` | character | Package-generated identifier for one source trade; repeats across expanded choices |
| `option_id` | character | Unique identifier for one expanded row |
| `candidate_count` | integer | Number of source candidates in the group before choice expansion |
| `num_to_select` | integer | Number of candidates selected from the group; `-1` means all |
| `select_all` | logical | Whether every candidate in the group is selected |
| `max_uses` | double | Uses before the offer locks until the villager restocks |
| `trader_exp` | double | Experience the villager gains when the trade succeeds |
| `reward_exp` | logical | Whether the player receives experience for the trade |

The generated identifiers follow source positions. They are deterministic for
a given release, but matching IDs across releases should also compare the
corresponding trade contents.

### Item-slot columns

Each of the three prefixes—`wants_1_`, `wants_2_`, and `gives_1_`—is combined
with the same nine fields:

| Field | Type | Meaning |
|---|---|---|
| `item_raw` | character | Exact Mojang identifier, including a numeric auxiliary suffix when present |
| `item` | character | Item identifier with the auxiliary suffix removed |
| `aux_value` | integer | Auxiliary or legacy data value from that suffix; `NA` when absent |
| `quantity_min` | double | Smallest possible item quantity |
| `quantity_max` | double | Largest possible item quantity |
| `price_multiplier` | double | Multiplier governing demand-driven price increases |
| `functions` | character | Item-generation function names, separated by commas |
| `function_parameters` | character | JSON array of parameters aligned with `functions` |
| `filters` | character | Unevaluated contextual filter JSON |

For example, `wants_1_quantity_min` is the lower quantity bound for the first
item paid by the player, whereas `gives_1_functions` lists functions applied to
the item supplied by the villager.

Trades with only one input have typed `NA` values throughout the `wants_2_`
columns. Other optional properties also remain `NA` when Mojang leaves them out
of the source; `bedrocktrader` does not replace them with Minecraft's runtime
defaults. The exception is item quantity, which becomes one when omitted.

For more background on the underlying fields, see Microsoft's
[trade-table documentation](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable).

## Source and Scope

Every top-level call retrieves current source data online without a disk or
session cache. The requested release is resolved once, files are downloaded
from its immutable Mojang tag, and their Git blob hashes are checked against
the release manifest.

Version `0.0.0.9000` focuses on retrieval, validation, and normalization.
Context evaluation, offer probabilities, saved-world inventories, plots,
custom trade tables, wandering traders, price calculations, and generated
enchantment outcomes remain outside this iteration.

Mojang data is downloaded at runtime from the
[Bedrock Samples repository](https://github.com/Mojang/bedrock-samples) and
remains subject to the
[Minecraft End User License Agreement](https://www.minecraft.net/eula).
`bedrocktrader` is an independent project and is not affiliated with Mojang or
Microsoft.
