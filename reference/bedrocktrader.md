# bedrocktrader: Minecraft Bedrock Villager Trade Data

`bedrocktrader` provides normalized vanilla villager trades for
Minecraft Bedrock Edition `1.26.30.5`. The data and modeled outcomes are
bundled with the package, so its public functions return ordinary base R
data frames without downloading files or reading `GITHUB_PAT`.

## Meta

[`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md)
lists accepted professions and summarizes important trade-table
features.
[`villager_variants()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_variants.md)
connects biome names with Mojang's `minecraft:mark_variant` values.
[`villager_tiers()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_tiers.md)
pairs each numeric tier with its name and cumulative experience
requirement.
[`enchantments()`](https://rentosaijo.github.io/bedrocktrader/reference/enchantments.md)
provides the pinned enchantment registry and Villager availability.

## Data

[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md)
follows Mojang's `tiers`, `groups`, `trades`, `wants`, and `gives`
terminology. Its trade, option, and offer views move from summarized
source rows to exact item specifications and prices. Every view reports
the probability represented by its rows.

## Analysis

[`enchanted_book_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_book_probability.md)
calculates the chance that a fully unlocked Librarian has a qualifying
book.
[`enchanted_item_probability()`](https://rentosaijo.github.io/bedrocktrader/reference/enchanted_item_probability.md)
evaluates complete enchantment sets on directly traded equipment.

## Version and modeling boundary

This package supports `1.26.30.5` only. Source-resolved rows come
directly from Mojang's pinned trade tables. Librarian books and
enchanted equipment use documented models; `random_dye` remains marked
as engine-generated. Later Bedrock versions are unsupported until their
data and mechanics are reviewed and the bundled model is regenerated.

## Licensing

The R code is GPL-3-or-later. Normalized values derived from Mojang's
Bedrock Samples remain subject to Mojang's license notice and the
Minecraft EULA. `bedrocktrader` is independent of Mojang and Microsoft.

## References

[Mojang, "Bedrock Samples
v1.26.30.5"](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)

[Mojang, "Bedrock Samples license
notice"](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)

[Minecraft, "End User License
Agreement"](https://www.minecraft.net/en-us/eula)

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
