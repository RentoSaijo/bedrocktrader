# bedrocktrader: Retrieve Minecraft Bedrock Villager Trade Data

`bedrocktrader` retrieves official vanilla Minecraft Bedrock villager
trade data and returns ordinary base R data frames. This release
supports Minecraft Bedrock Edition `1.26.30.5` only.

## Meta

Use
[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md)
to discover supported professions and their trade-table features.
[`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
connects biome variants with Mojang's `minecraft:mark_variant` values.

## Data

[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
retrieves the possible offers for one profession and expands concrete
item choices. Librarian books are modeled by enchantment and level. More
complex engine-generated outcomes remain clearly identified.

## Analysis

[`offer_probabilities()`](https://rentosaijo.github.io/bedrocktrader/reference/offer_probabilities.md)
calculates the marginal probability that each row appears among a
villager's offers. It separates group selection, item choice, and
generated-outcome probabilities so their sources remain visible.

## Source behavior

Each public function retrieves its source data online from Mojang's
immutable `v1.26.30.5` release tag. Downloaded files are checked against
pinned Git blob SHAs, and the package does not write a cache. Later
Minecraft versions remain unsupported until their data and mechanics are
reviewed.

## References

[Mojang, "Bedrock Samples
v1.26.30.5"](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)

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
