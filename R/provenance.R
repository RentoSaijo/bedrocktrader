# Provenance Helpers -------------------------------------------------------------

# Create source record.
.source_row <- function(
  source_role,
  profession,
  release,
  source_path,
  blob_sha
) {
  tibble::tibble(
    profession    = profession,
    source_role   = source_role,
    bedrock_version = release$bedrock_version,
    release_tag   = release$release_tag,
    repository    = .bedrock_repository_url,
    git_commit    = release$git_commit,
    source_path   = source_path,
    blob_sha      = blob_sha,
    retrieved_at  = release$retrieved_at,
    parser_version = .bedrock_parser_version
  )
}

# Combine source records.
.bind_source_rows <- function(rows) {
  if (!length(rows)) {
    return(tibble::tibble())
  }
  tibble::as_tibble(do.call(rbind, rows))
}

# Attach source records.
.attach_source <- function(x, source) {
  attr(x, 'bedrocktrader_source') <- source
  x
}

# Create release summary.
.release_tibble <- function(release) {
  result <- tibble::tibble(
    bedrocktrader_package = .package_version(),
    requested_version     = release$requested_version,
    bedrock_version       = release$bedrock_version,
    release_date          = release$release_date,
    channel               = release$channel,
    release_tag           = release$release_tag,
    repository            = .bedrock_repository_url,
    git_commit            = release$git_commit,
    parser_version        = .bedrock_parser_version,
    retrieved_at          = release$retrieved_at
  )
  class(result) <- c('bedrocktrader_data_version', class(result))
  .attach_source(
    result,
    .source_row(
      source_role = 'release',
      profession  = NA_character_,
      release     = release,
      source_path = NA_character_,
      blob_sha    = NA_character_
    )
  )
}

# Public Functions ---------------------------------------------------------------

#' Report Minecraft Bedrock Data Version
#'
#' Resolves a stable Mojang Bedrock Samples release and reports the exact release
#' tag and Git commit that would be used for a retrieval.
#'
#' @param version `"latest"` or an explicit stable Minecraft Bedrock sample
#'   version.
#'
#' @return A one-row tibble with package, release, commit, parser, and retrieval
#'   metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' bedrocktrader_data_version()
#' bedrocktrader_data_version('1.26.30.5')
#' }
bedrocktrader_data_version <- function(version = 'latest') {
  .release_tibble(.resolve_release(version))
}

#' Report Source Provenance
#'
#' Returns the exact Mojang sources associated with a `bedrocktrader` result.
#'
#' @param x An object returned by a public `bedrocktrader` function.
#'
#' @return A tibble with source roles, release identifiers, paths, Git blob
#'   identifiers, retrieval times, and parser versions.
#' @export
#'
#' @examples
#' \dontrun{
#' farmer <- villager_trades('farmer')
#' source_info(farmer)
#' }
source_info <- function(x) {
  source <- if (inherits(x, 'bedrock_villager_trades')) {
    x$source
  } else {
    attr(x, 'bedrocktrader_source', exact = TRUE)
  }
  if (is.null(source)) {
    stop(
      '`x` must be an object returned by a bedrocktrader function.',
      call. = FALSE
    )
  }
  tibble::as_tibble(source)
}
