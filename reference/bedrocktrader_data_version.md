# Report Minecraft Bedrock Data Version

Resolves a stable Mojang Bedrock Samples release and reports the exact
release tag and Git commit that would be used for a retrieval.

## Usage

``` r
bedrocktrader_data_version(version = "latest")
```

## Arguments

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version.

## Value

A one-row tibble with package, release, commit, parser, and retrieval
metadata.

## Examples

``` r
if (FALSE) { # \dontrun{
bedrocktrader_data_version()
bedrocktrader_data_version('1.26.30.5')
} # }
```
