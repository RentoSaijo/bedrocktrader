# List Supported Villager Professions

Retrieves and inspects all supported vanilla profession tables from one
stable Mojang release.

## Usage

``` r
villager_professions(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version.

## Value

A tibble containing canonical profession identifiers, display names,
aliases, source files, and structural feature flags.

## Examples

``` r
if (FALSE) { # \dontrun{
villager_professions()
villager_professions('1.26.30.5')
} # }
```
