# Package Documentation ---------------------------------------------------------

#' bedrocktrader: Retrieve Minecraft Bedrock Villager Trade Data
#'
#' `bedrocktrader` retrieves official vanilla Minecraft Bedrock villager trade
#' data from stable Mojang releases and returns ordinary base R data frames.
#'
#' @section Meta:
#' Use [bedrock_versions()] to inspect the stable releases the package can
#' retrieve, [villager_professions()] to discover supported professions and
#' their trade-table features, and [villager_variants()] to connect biome
#' variants with Mojang's `minecraft:mark_variant` values.
#'
#' @section Data:
#' [villager_trades()] retrieves the possible offers for one profession. Its
#' rows preserve villager levels, selection groups, item choices, item-generation
#' functions, and contextual filters from Mojang's source table. The result
#' describes the profession's possible trade definitions rather than the
#' realized offers held by one villager in a saved world.
#'
#' @section Source behavior:
#' Each public function retrieves its source data online. A selected release is
#' read from an immutable Mojang release tag, and downloaded files are checked
#' against the release manifest. The package does not write a cache.
#'
#' @name bedrocktrader
#' @aliases bedrocktrader-package

"_PACKAGE"
