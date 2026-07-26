# List Supported Minecraft Bedrock Versions

Lists the stable Minecraft Bedrock releases that `bedrocktrader` can
read. The registry is retrieved from Mojang each time the function is
called, so the result grows as new supported stable releases appear.

## Usage

``` r
bedrock_versions()
```

## Value

A base data frame with one row per supported release, ordered from
newest to oldest:

- `version` (`character`) is the stable Bedrock version accepted by the
  `version` argument in the other package functions.

- `release_date` (`Date`) is the release date recorded in Mojang's
  stable-version registry.

- `latest` (`logical`) identifies Mojang's current latest stable
  release.

## Details

Supported releases begin with version `1.26.20.4`. Preview releases do
not appear in the result. Passing `version = "latest"` to another
package function selects the row where `latest` is `TRUE` at the time of
that call.

This function performs a fresh online retrieval and does not read or
write a cache.

## Examples

``` r
if (FALSE) { # \dontrun{
versions <- bedrock_versions()
versions

versions[versions$latest, ]
} # }
```
