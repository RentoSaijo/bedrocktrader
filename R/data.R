# Input Helpers -----------------------------------------------------------------

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

# Normalize tier input.
.normalize_tier_input <- function(tier, allow_null = TRUE) {
  if (allow_null && is.null(tier)) {
    return(seq_along(.bedrock_tier_names))
  }
  if (length(tier) != 1L || is.na(tier)) {
    stop('`tier` must be one villager tier.', call. = FALSE)
  }
  if (is.numeric(tier)) {
    if (
      !is.finite(tier) ||
      tier != floor(tier) ||
      !(tier %in% seq_along(.bedrock_tier_names))
    ) {
      stop('`tier` must be an integer from 1 through 5.', call. = FALSE)
    }
    return(as.integer(tier))
  }
  if (!is.character(tier) || !nzchar(tier)) {
    stop(
      '`tier` must be an integer from 1 through 5 or a tier name.',
      call. = FALSE
    )
  }
  value   <- tolower(trimws(tier))
  matched <- match(value, .bedrock_tier_names)
  if (is.na(matched)) {
    stop(
      '`tier` must be novice, apprentice, journeyman, expert, or master.',
      call. = FALSE
    )
  }
  matched
}

# Public Functions --------------------------------------------------------------

#' List Supported Villager Professions
#'
#' Lists the 13 employable villager professions supported for Minecraft
#' Bedrock `1.26.30.5`.
#'
#' @return A base data frame describing each profession and its trade-table
#'   features.
#' @export
villager_professions <- function() {
  result <- .bedrock_professions_data
  rownames(result) <- NULL
  result
}

#' List Villager Variants
#'
#' Lists vanilla villager variants and their `minecraft:mark_variant` values
#' for Minecraft Bedrock `1.26.30.5`.
#'
#' @return A base data frame containing variant identifiers, mark-variant
#'   values, and accepted aliases.
#' @export
villager_variants <- function() {
  result <- .bedrock_variants_data
  rownames(result) <- NULL
  result
}

#' Retrieve Villager Trades
#'
#' Returns possible trade outcomes from the bundled Minecraft Bedrock
#' `1.26.30.5` model.
#'
#' @param profession One profession or documented alias.
#' @param tier `NULL` for every tier, or a number from 1 through 5 or tier name.
#'
#' @return A base data frame with one row per possible trade outcome.
#' @export
villager_trades <- function(profession = 'armorer', tier = NULL) {
  profession <- .normalize_profession_input(profession)
  tiers      <- .normalize_tier_input(tier)
  keep <- .bedrock_trade_outcomes$profession == profession &
    .bedrock_trade_outcomes$tier %in% tiers
  result <- .bedrock_trade_outcomes[
    keep,
    .bedrock_trade_columns,
    drop = FALSE
  ]
  rownames(result) <- NULL
  result
}
