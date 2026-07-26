# bedrocktrader

### Overview

Villager trades look compact in Minecraft, yet their source tables contain
nested tiers, selection groups, item choices, functions, and contextual
filters. `bedrocktrader` brings that structure into R directly from official
vanilla Minecraft Bedrock releases.

This development version establishes the data foundation. It retrieves the 13
employable villager profession tables, normalizes their structure, and expands
item choices into flat base R data frames.

### Installation

Install the development version from [GitHub](https://github.com/) with:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

### Quick Start

```r
library(bedrocktrader)

bedrock_versions()
villager_professions()
villager_variants()

armorer <- villager_trades()
head(armorer)
```

The default `version = 'latest'` resolves Mojang's current stable release when
the function is called. `bedrocktrader` supports stable releases beginning with
`1.26.20.4`; inspect the versions currently available with
`bedrock_versions()`.

```r
farmer <- villager_trades(
  'farmer',
  version = '1.26.30.5'
)
```

Every retrieval is online and uncached. The selected release comes from its
immutable Git tag, and each downloaded file is checked against Mojang's source
manifest.

`villager_professions()` includes three structural indicators:

- `context_sensitive` identifies tables with variant or dimension filters.
- `contains_item_choices` identifies Mojang item `choice` arrays.
- `contains_dynamic_functions` identifies item-generation functions such as
  enchantments, potions, dyes, or exploration maps.

### Current Scope

Version `0.0.0.9000` focuses on retrieval, validation, and normalization.
Context evaluation, probability calculations, plots, custom trade tables,
wandering traders, saved-world data, price modifiers, and exact enchantment
outcomes are not part of this iteration.

Mojang data is downloaded at runtime from the
[Bedrock Samples repository](https://github.com/Mojang/bedrock-samples) and
remains subject to the
[Minecraft End User License Agreement](https://www.minecraft.net/eula).
`bedrocktrader` is an independent project and is not affiliated with Mojang or
Microsoft.
