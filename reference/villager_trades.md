# Retrieve Villager Trades

Retrieves and normalizes an official vanilla Minecraft Bedrock trade
table for one supported villager profession.

## Usage

``` r
villager_trades(profession = "armorer", version = "latest")
```

## Arguments

- profession:

  A canonical profession identifier or documented alias.

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version
  returned by
  [`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md).

## Value

A base data frame with one row per concrete combination of item choices.
Dynamic function outcomes remain unresolved and are retained as function
names and JSON parameters.

## Examples

``` r
if (FALSE) { # \dontrun{
armorer <- villager_trades()
farmer <- villager_trades('farmer')
mason <- villager_trades('mason', version = '1.26.30.5')
} # }
```
