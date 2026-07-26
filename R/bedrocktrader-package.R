# Package Documentation ---------------------------------------------------------

#' bedrocktrader: Retrieve Minecraft Bedrock Villager Trade Data
#'
#' `bedrocktrader` retrieves official vanilla Minecraft Bedrock villager trade
#' data and returns ordinary base R data frames. This release supports Minecraft
#' Bedrock Edition `1.26.30.5` only.
#'
#' @section Meta:
#' Use [villager_professions()] to discover supported professions and their
#' trade-table features. [villager_variants()] connects biome variants with
#' Mojang's `minecraft:mark_variant` values.
#'
#' @section Data:
#' [villager_trades()] retrieves the possible offers for one profession and
#' expands concrete item choices. Librarian books are modeled by enchantment and
#' level. More complex engine-generated outcomes remain clearly identified.
#'
#' @section Analysis:
#' [offer_probabilities()] calculates the marginal probability that each row
#' appears among a villager's offers. It separates group selection, item choice,
#' and generated-outcome probabilities so their sources remain visible.
#'
#' @section Source behavior:
#' Each public function retrieves its source data online from Mojang's immutable
#' `v1.26.30.5` release tag. Downloaded files are checked against pinned Git
#' blob SHAs, and the package does not write a cache. Later Minecraft versions
#' remain unsupported until their data and mechanics are reviewed.
#'
#' @references
#' [Mojang, "Bedrock Samples v1.26.30.5"](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
#'
#' @name bedrocktrader
#' @aliases bedrocktrader-package

"_PACKAGE"
