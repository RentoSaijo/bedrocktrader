# bedrocktrader: Retrieve Minecraft Bedrock Villager Trade Data

`bedrocktrader` retrieves official vanilla Minecraft Bedrock villager
trade data from stable Mojang releases and returns ordinary base R data
frames.

## Meta

Use
[`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md)
to inspect the stable releases the package can retrieve,
[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md)
to discover supported professions and their trade-table features, and
[`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
to connect biome variants with Mojang's `minecraft:mark_variant` values.

## Data

[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
retrieves the possible offers for one profession. Its rows preserve
villager levels, selection groups, item choices, item-generation
functions, and contextual filters from Mojang's source table. The result
describes the profession's possible trade definitions rather than the
realized offers held by one villager in a saved world.

## Source behavior

Each public function retrieves its source data online. A selected
release is read from an immutable Mojang release tag, and downloaded
files are checked against the release manifest. The package does not
write a cache.

## See also

Useful links:

- <https://rentosaijo.github.io/bedrocktrader/>

- <https://github.com/RentoSaijo/bedrocktrader>

- Report bugs at <https://github.com/RentoSaijo/bedrocktrader/issues>

## Author

**Maintainer**: Rento Saijo <rentosaijo0527@gmail.com>
([ORCID](https://orcid.org/0009-0008-4919-7349)) \[copyright holder\]

Authors:

- Rento Saijo <rentosaijo0527@gmail.com>
  ([ORCID](https://orcid.org/0009-0008-4919-7349)) \[copyright holder\]
