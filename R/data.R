# Profession Helpers ------------------------------------------------------------

# Normalize profession input.
.normalize_profession_input <- function(profession) {
  if (
    length(profession) != 1L ||
    is.na(profession) ||
    !is.character(profession) ||
    !nzchar(profession)
  ) {
    stop('`profession` must be one nonempty character value.', call. = FALSE)
  }
  value <- tolower(trimws(profession))
  for (canonical in names(.bedrock_profession_aliases)) {
    if (value %in% c(canonical, .bedrock_profession_aliases[[canonical]])) {
      return(canonical)
    }
  }
  stop(
    'Unsupported villager profession `',
    profession,
    '`. Use `villager_professions()` to inspect supported values.',
    call. = FALSE
  )
}

# Find source manifest entry.
.manifest_entry <- function(manifest, source_path, release) {
  manifest_paths <- vapply(
    manifest,
    function(entry) entry$path %||% '',
    character(1)
  )
  matches <- which(manifest_paths == source_path)
  if (length(matches) != 1L) {
    stop(
      'Mojang release `',
      release$bedrock_version,
      '` does not contain expected source `',
      source_path,
      '`.',
      call. = FALSE
    )
  }
  manifest[[matches]]
}

# Load profession tables.
.load_profession_tables <- function(professions, version) {
  release  <- .resolve_release(version)
  manifest <- .fetch_directory_manifest(
    release,
    .bedrock_trade_directory
  )
  tables <- vector('list', length(professions))
  names(tables) <- professions
  for (index in seq_along(professions)) {
    profession <- professions[[index]]
    source_file <- .bedrock_professions$source_file[
      match(profession, .bedrock_professions$profession)
    ]
    source_path <- paste0(
      .bedrock_trade_directory,
      '/',
      source_file
    )
    entry <- .manifest_entry(manifest, source_path, release)
    content <- .fetch_manifest_file(entry, release)
    table   <- .parse_json(content, source_path)
    tables[[index]] <- .normalize_trade_table(
      table       = table,
      profession  = profession,
      release     = release,
      source_path = source_path
    )
  }
  list(
    professions = tables,
    release     = release
  )
}

# Collapse aliases.
.collapse_aliases <- function(aliases) {
  if (!length(aliases)) {
    return(NA_character_)
  }
  paste(aliases, collapse = ', ')
}

# Flatten normalized item positions.
.trade_positions <- function(table) {
  positions <- list()
  for (level in table$levels) {
    for (group in level$groups) {
      for (candidate in group$candidates) {
        positions <- c(
          positions,
          candidate$wants,
          candidate$gives
        )
      }
    }
  }
  positions
}

# Summarize profession mechanisms.
.profession_features <- function(table) {
  positions <- .trade_positions(table)
  context_sensitive <- any(vapply(
    positions,
    function(position) {
      position_filtered <- !is.null(position$filters)
      choice_filtered <- any(vapply(
        position$choices,
        function(choice) !is.null(choice$filters),
        logical(1)
      ))
      position_filtered || choice_filtered
    },
    logical(1)
  ))
  contains_item_choices <- any(vapply(
    positions,
    function(position) position$has_choice,
    logical(1)
  ))
  contains_dynamic_functions <- any(vapply(
    positions,
    function(position) {
      position_dynamic <- length(position$functions) > 0L
      choice_dynamic <- any(vapply(
        position$choices,
        function(choice) length(choice$functions) > 0L,
        logical(1)
      ))
      position_dynamic || choice_dynamic
    },
    logical(1)
  ))
  c(
    context_sensitive         = context_sensitive,
    contains_item_choices     = contains_item_choices,
    contains_dynamic_functions = contains_dynamic_functions
  )
}

# Public Functions ---------------------------------------------------------------

#' List Supported Villager Professions
#'
#' Retrieves and inspects all supported vanilla profession tables from one
#' stable Mojang release.
#'
#' @param version `"latest"` or an explicit stable Minecraft Bedrock sample
#'   version.
#'
#' @return A base data frame containing canonical profession identifiers,
#'   display names, aliases, and structural feature flags. `context_sensitive`
#'   marks tables with variant or dimension filters. `contains_item_choices`
#'   marks tables with Mojang item `choice` arrays.
#'   `contains_dynamic_functions` marks tables with item-generation functions.
#' @export
#'
#' @examples
#' \dontrun{
#' villager_professions()
#' villager_professions('1.26.30.5')
#' }
villager_professions <- function(version = 'latest') {
  professions <- .bedrock_professions$profession
  object      <- .load_profession_tables(professions, version)
  features    <- lapply(object$professions, .profession_features)
  result <- data.frame(
    profession               = professions,
    display_name             = .bedrock_professions$display_name,
    aliases                  = vapply(
      .bedrock_profession_aliases[professions],
      .collapse_aliases,
      character(1)
    ),
    context_sensitive        = vapply(
      features,
      function(feature) feature[['context_sensitive']],
      logical(1)
    ),
    contains_item_choices    = vapply(
      features,
      function(feature) feature[['contains_item_choices']],
      logical(1)
    ),
    contains_dynamic_functions = vapply(
      features,
      function(feature) feature[['contains_dynamic_functions']],
      logical(1)
    ),
    stringsAsFactors = FALSE
  )
  rownames(result) <- NULL
  result
}

#' List Villager Variants
#'
#' Retrieves the vanilla villager entity definition from one stable Mojang
#' release and derives its seven stored `mark_variant` values.
#'
#' @param version `"latest"` or an explicit stable Minecraft Bedrock sample
#'   version.
#'
#' @return A base data frame containing canonical variant identifiers, vanilla
#'   `mark_variant` values, and aliases.
#' @export
#'
#' @examples
#' \dontrun{
#' villager_variants()
#' villager_variants('1.26.30.5')
#' }
villager_variants <- function(version = 'latest') {
  release <- .resolve_release(version)
  content <- .fetch_direct_file(
    release     = release,
    source_path = .bedrock_variant_path
  )
  entity <- .parse_json(content, .bedrock_variant_path)
  result <- data.frame(
    variant      = .bedrock_variants,
    mark_variant = .normalize_variants(entity, release),
    aliases      = vapply(
      .bedrock_variant_aliases[.bedrock_variants],
      .collapse_aliases,
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  rownames(result) <- NULL
  result
}

#' Retrieve Villager Trades
#'
#' Retrieves and normalizes an official vanilla Minecraft Bedrock trade table
#' for one supported villager profession.
#'
#' @param profession A canonical profession identifier or documented alias.
#' @param version `"latest"` or an explicit stable Minecraft Bedrock sample
#'   version returned by [bedrock_versions()].
#'
#' @return A base data frame with one row per concrete combination of item
#'   choices. Dynamic function outcomes remain unresolved and are retained as
#'   function names and JSON parameters.
#' @export
#'
#' @examples
#' \dontrun{
#' armorer <- villager_trades()
#' farmer <- villager_trades('farmer')
#' mason <- villager_trades('mason', version = '1.26.30.5')
#' }
villager_trades <- function(profession = 'armorer', version = 'latest') {
  profession <- .normalize_profession_input(profession)
  object     <- .load_profession_tables(profession, version)
  .flatten_trade_table(
    table   = object$professions[[profession]],
    release = object$release
  )
}
