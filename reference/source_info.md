# Report Source Provenance

Returns the exact Mojang sources associated with a `bedrocktrader`
result.

## Usage

``` r
source_info(x)
```

## Arguments

- x:

  An object returned by a public `bedrocktrader` function.

## Value

A tibble with source roles, release identifiers, paths, Git blob
identifiers, retrieval times, and parser versions.

## Examples

``` r
if (FALSE) { # \dontrun{
farmer <- villager_trades('farmer')
source_info(farmer)
} # }
```
