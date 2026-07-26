# bedrocktrader

### Overview

Villager trades look compact in Minecraft, yet their source tables contain
nested tiers, selection groups, item choices, functions, and contextual
filters. `bedrocktrader` brings that structure into R directly from official
vanilla Minecraft Bedrock releases.

This development version establishes the data foundation. It retrieves the 13
employable villager profession tables, normalizes their structure, and records
the exact release, Git commit, source path, and blob identifier behind each
result.

### Installation

Install the development version from [GitHub](https://github.com/) with:

```r
install.packages('pak')
pak::pak('RentoSaijo/bedrocktrader')
```

### Quick Start

```r
library(bedrocktrader)

villager_professions()
villager_variants()

farmer <- villager_trades('farmer')
source_info(farmer)
```

The default `version = 'latest'` resolves Mojang's current stable release when
the function is called. Supply a stable version for a repeatable source:

```r
farmer <- villager_trades(
  'farmer',
  version = '1.26.30.5'
)
```

Every retrieval is online and uncached. The selected release is resolved once
per call, and all requested files then come from its immutable Git tag.

### Current Scope

Version `0.0.0.9000` focuses on retrieval, validation, normalization, and
provenance. Trade catalogs, context evaluation, probability calculations,
plots, custom trade tables, wandering traders, saved-world data, price
modifiers, and exact enchantment outcomes are not part of this iteration.

Mojang data is downloaded at runtime from the
[Bedrock Samples repository](https://github.com/Mojang/bedrock-samples) and
remains subject to the
[Minecraft End User License Agreement](https://www.minecraft.net/eula).
`bedrocktrader` is an independent project and is not affiliated with Mojang or
Microsoft.
