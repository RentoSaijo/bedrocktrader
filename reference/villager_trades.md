# Retrieve Villager Trades

Retrieves and normalizes official vanilla Minecraft Bedrock trade tables
for one supported villager profession or all supported professions.

## Usage

``` r
villager_trades(profession, version = "latest")
```

## Arguments

- profession:

  A canonical profession identifier, documented alias, or `"all"`.

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version.

## Value

A `bedrock_villager_trades` object containing normalized profession,
level, selection-group, candidate, item-position, and item-choice
records.

## Examples

``` r
if (FALSE) { # \dontrun{
farmer <- villager_trades('farmer')
mason <- villager_trades('mason', version = '1.26.30.5')
all_trades <- villager_trades('all')
} # }
```
