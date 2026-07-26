# Public Functions ---------------------------------------------------------------

#' List Supported Minecraft Bedrock Versions
#'
#' Retrieves Mojang's stable-version registry and lists releases at or above the
#' minimum version supported by `bedrocktrader`.
#'
#' @return A base data frame containing stable version identifiers, release
#'   dates, and an indicator for Mojang's current latest stable release.
#' @export
#'
#' @examples
#' \dontrun{
#' bedrock_versions()
#' }
bedrock_versions <- function() {
  .stable_versions()
}
