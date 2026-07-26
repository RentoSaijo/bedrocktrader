# Package Documentation ---------------------------------------------------------

#' bedrocktrader: Minecraft Bedrock Villager Trade Data
#'
#' `bedrocktrader` provides normalized vanilla villager trades for Minecraft
#' Bedrock Edition `1.26.30.5`. The data and modeled outcomes are bundled with
#' the package, so its public functions return ordinary base R data frames
#' without downloading files or reading `GITHUB_PAT`.
#'
#' @section Meta:
#' [villager_professions()] lists accepted professions and summarizes important
#' trade-table features. [villager_variants()] connects biome names with
#' Mojang's `minecraft:mark_variant` values. [villager_tiers()] pairs each
#' numeric tier with its name and cumulative experience requirement.
#'
#' @section Data:
#' [villager_trades()] follows Mojang's `tiers`, `groups`, `trades`, `wants`,
#' and `gives` terminology. Its compact rows describe base item alternatives;
#' expanded rows separate modeled enchantments and other generated outcomes.
#' Both forms include the marginal probability that the displayed row appears.
#'
#' @section Version and modeling boundary:
#' This package supports `1.26.30.5` only. Source-resolved rows come directly
#' from Mojang's pinned trade tables. Librarian books and enchanted equipment
#' use documented models; `random_dye` remains marked as engine-generated.
#' Later Bedrock versions are unsupported until their data and mechanics are
#' reviewed and the bundled model is regenerated.
#'
#' @section Licensing:
#' The R code is GPL-3-or-later. Normalized values derived from Mojang's
#' Bedrock Samples remain subject to Mojang's license notice and the Minecraft
#' EULA. `bedrocktrader` is independent of Mojang and Microsoft.
#'
#' @references
#' [Mojang, "Bedrock Samples v1.26.30.5"](https://github.com/Mojang/bedrock-samples/releases/tag/v1.26.30.5)
#'
#' [Mojang, "Bedrock Samples license notice"](https://github.com/Mojang/bedrock-samples/blob/v1.26.30.5/LICENSE.md)
#'
#' [Minecraft, "End User License Agreement"](https://www.minecraft.net/en-us/eula)
#'
#' @name bedrocktrader
#' @aliases bedrocktrader-package

"_PACKAGE"
