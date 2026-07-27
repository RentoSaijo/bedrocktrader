# List villager tiers

Lists the five villager trading tiers and the cumulative experience a
villager needs to unlock each tier in Minecraft: Bedrock Edition
`1.26.30.5`.

## Usage

``` r
villager_tiers()
```

## Value

A base data frame with five rows:

- `tier` (`integer`) is the numeric tier used by
  [`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).

- `tier_name` (`character`) is the corresponding in-game rank.

- `total_exp_required` (`double`) is the cumulative trading experience
  the villager needs to unlock the tier. The novice tier is always
  available.

## Details

The bundled vanilla profession tables use the same tier names and
experience thresholds. Calling this function performs no download.

## Examples

``` r
# Inspect villager tiers.
villager_tiers()
#>   tier  tier_name total_exp_required
#> 1    1     novice                  0
#> 2    2 apprentice                 10
#> 3    3 journeyman                 70
#> 4    4     expert                150
#> 5    5     master                250
```
