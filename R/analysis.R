# Input Helpers ----------------------------------------------------------------

# Normalize maximum emerald input.
.normalize_max_emeralds <- function(max_emeralds) {
  if (
    length(max_emeralds) != 1L ||
    is.na(max_emeralds) ||
    !is.numeric(max_emeralds) ||
    !is.finite(max_emeralds) ||
    max_emeralds != floor(max_emeralds) ||
    max_emeralds < 0 ||
    max_emeralds > 64
  ) {
    stop(
      '`max_emeralds` must be one whole number from 0 through 64.',
      call. = FALSE
    )
  }
  as.integer(max_emeralds)
}

# Normalize higher-level input.
.normalize_higher_level <- function(include_higher_level) {
  if (
    length(include_higher_level) != 1L ||
    is.na(include_higher_level) ||
    !is.logical(include_higher_level)
  ) {
    stop(
      '`include_higher_level` must be TRUE or FALSE.',
      call. = FALSE
    )
  }
  include_higher_level
}

# Normalize enchantment query.
.normalize_enchantment_query <- function(value, multiple, argument) {
  if (
    length(value) != 1L ||
    is.na(value) ||
    !is.character(value) ||
    !nzchar(trimws(value))
  ) {
    stop(
      '`',
      argument,
      '` must be one nonempty character value.',
      call. = FALSE
    )
  }
  normalized <- tolower(gsub('[[:space:]]+', '', value))
  specifications <- strsplit(normalized, ',', fixed = TRUE)[[1L]]
  if (any(!nzchar(specifications))) {
    stop(
      '`',
      argument,
      '` contains an empty enchantment specification.',
      call. = FALSE
    )
  }
  pattern <- '^(minecraft:)?([a-z0-9_]+)=([0-9]+)$'
  matches <- regexec(pattern, specifications)
  parts   <- regmatches(specifications, matches)
  if (any(lengths(parts) != 4L)) {
    stop(
      '`',
      argument,
      '` must use comma-separated `identifier=level` pairs.',
      call. = FALSE
    )
  }
  identifiers <- vapply(parts, function(part) part[[3L]], character(1))
  levels <- suppressWarnings(as.integer(vapply(parts, function(part) {
    part[[4L]]
  }, character(1))))
  if (anyNA(levels)) {
    stop(
      '`',
      argument,
      '` contains an invalid enchantment level.',
      call. = FALSE
    )
  }
  if (anyDuplicated(identifiers)) {
    stop(
      '`',
      argument,
      '` cannot repeat an enchantment identifier.',
      call. = FALSE
    )
  }
  canonical <- paste0('minecraft:', identifiers)
  registry_rows <- match(canonical, .bedrock_enchantments_data$enchantment)
  if (anyNA(registry_rows)) {
    unknown <- canonical[is.na(registry_rows)]
    stop(
      'Unknown enchantment `',
      unknown[[1L]],
      '`. Use `enchantments()` to inspect supported values.',
      call. = FALSE
    )
  }
  maximums <- .bedrock_enchantments_data$max_level[registry_rows]
  invalid_level <- levels < 1L | levels > maximums
  if (any(invalid_level)) {
    index <- which(invalid_level)[[1L]]
    stop(
      'Level for `',
      canonical[[index]],
      '` must be from 1 through ',
      maximums[[index]],
      '.',
      call. = FALSE
    )
  }
  if (!multiple && length(canonical) != 1L) {
    stop(
      '`',
      argument,
      '` must contain exactly one enchantment.',
      call. = FALSE
    )
  }
  result <- data.frame(
    enchantment = canonical,
    level       = levels,
    stringsAsFactors = FALSE
  )
  result[order(result$enchantment), , drop = FALSE]
}

# Normalize enchanted item input.
.normalize_enchanted_item <- function(item, profession) {
  if (
    length(item) != 1L ||
    is.na(item) ||
    !is.character(item) ||
    !nzchar(trimws(item))
  ) {
    stop('`item` must be one nonempty character value.', call. = FALSE)
  }
  items <- data.frame(
    item = c(
      'helmet',
      'chestplate',
      'leggings',
      'boots',
      'sword',
      'axe',
      'pickaxe',
      'shovel',
      'bow',
      'crossbow',
      'fishing_rod'
    ),
    item_id = c(
      'minecraft:diamond_helmet',
      'minecraft:diamond_chestplate',
      'minecraft:diamond_leggings',
      'minecraft:diamond_boots',
      'minecraft:diamond_sword',
      'minecraft:diamond_axe',
      'minecraft:diamond_pickaxe',
      'minecraft:diamond_shovel',
      'minecraft:bow',
      'minecraft:crossbow',
      'minecraft:fishing_rod'
    ),
    profession = c(
      'armorer',
      'armorer',
      'armorer',
      'armorer',
      'weaponsmith',
      NA_character_,
      'toolsmith',
      'toolsmith',
      'fletcher',
      'fletcher',
      'fisherman'
    ),
    stringsAsFactors = FALSE
  )
  value <- tolower(trimws(item))
  item_row <- match(value, items$item)
  if (is.na(item_row)) {
    item_row <- match(value, items$item_id)
  }
  if (is.na(item_row)) {
    stop(
      'Unsupported enchanted item `',
      item,
      '`.',
      call. = FALSE
    )
  }
  expected_profession <- items$profession[[item_row]]
  if (is.na(expected_profession)) {
    if (is.null(profession)) {
      stop(
        '`profession` must be toolsmith or weaponsmith for a diamond axe.',
        call. = FALSE
      )
    }
    normalized_profession <- .normalize_profession_input(profession)
    if (!(normalized_profession %in% c('toolsmith', 'weaponsmith'))) {
      stop(
        '`profession` must be toolsmith or weaponsmith for a diamond axe.',
        call. = FALSE
      )
    }
  } else {
    normalized_profession <- expected_profession
    if (!is.null(profession)) {
      supplied_profession <- .normalize_profession_input(profession)
      if (!identical(supplied_profession, expected_profession)) {
        stop(
          '`',
          items$item[[item_row]],
          '` is sold by ',
          expected_profession,
          ', not ',
          supplied_profession,
          '.',
          call. = FALSE
        )
      }
    }
  }
  list(
    item       = items$item[[item_row]],
    item_id    = items$item_id[[item_row]],
    profession = normalized_profession
  )
}

# Probability Helpers -----------------------------------------------------------

# Calculate offer probabilities for one profession.
.profession_offer_probabilities <- function(profession) {
  rows <- .bedrock_trade_offers[
    .bedrock_trade_offers$profession == profession,
    ,
    drop = FALSE
  ]
  rows$.offer_probability <- .trade_probabilities(rows) *
    .choice_probabilities(rows) *
    rows$.function_probability
  rows
}

# Parse one modeled enchantment set.
.parse_modeled_enchantments <- function(value) {
  specifications <- strsplit(value, ',', fixed = TRUE)[[1L]]
  parts <- strsplit(specifications, '=', fixed = TRUE)
  identifiers <- vapply(parts, function(part) part[[1L]], character(1))
  levels      <- as.integer(vapply(parts, function(part) {
    part[[2L]]
  }, character(1)))
  setNames(levels, identifiers)
}

# Match one modeled enchantment set.
.matches_enchantment_query <- function(
  value,
  query,
  include_higher_level,
  match
) {
  modeled <- .parse_modeled_enchantments(value)
  requested <- setNames(query$level, query$enchantment)
  if (identical(match, 'exact') && !setequal(names(modeled), names(requested))) {
    return(FALSE)
  }
  if (!all(names(requested) %in% names(modeled))) {
    return(FALSE)
  }
  modeled_levels <- modeled[names(requested)]
  if (include_higher_level) {
    return(all(modeled_levels >= requested))
  }
  all(modeled_levels == requested)
}

# Public Functions --------------------------------------------------------------

#' Calculate Enchanted Book Probability
#'
#' Calculates the probability that a fully unlocked Librarian has at least one
#' qualifying enchanted-book offer.
#'
#' @param enchantment One `identifier=level` pair. The `minecraft:` namespace
#'   is optional.
#' @param max_emeralds Inclusive original emerald-price cutoff.
#' @param include_higher_level Whether levels above the request also qualify.
#'
#' @return One numeric probability.
#' @export
#'
#' @examples
#' enchanted_book_probability()
#' enchanted_book_probability('mending=1', max_emeralds = 26)
enchanted_book_probability <- function(
  enchantment = 'minecraft:aqua_affinity=1',
  max_emeralds = 64,
  include_higher_level = FALSE
) {
  query <- .normalize_enchantment_query(
    enchantment,
    multiple = FALSE,
    argument = 'enchantment'
  )
  max_emeralds <- .normalize_max_emeralds(max_emeralds)
  include_higher_level <- .normalize_higher_level(include_higher_level)
  rows <- .profession_offer_probabilities('librarian')
  rows <- rows[
    rows$functions %in% 'enchant_book_for_trading',
    ,
    drop = FALSE
  ]
  book_trade_ids <- unique(rows$trade_id)
  requested_id <- paste0(query$enchantment[[1L]], '=')
  enchantment_ids <- sub('=[0-9]+$', '=', rows$gives_1_enchantments)
  enchantment_levels <- as.integer(sub(
    '^.*=',
    '',
    rows$gives_1_enchantments
  ))
  level_matches <- if (include_higher_level) {
    enchantment_levels >= query$level[[1L]]
  } else {
    enchantment_levels == query$level[[1L]]
  }
  qualifying <- enchantment_ids == requested_id &
    level_matches &
    rows$wants_1_quantity_min <= max_emeralds
  trade_probabilities <- setNames(
    numeric(length(book_trade_ids)),
    book_trade_ids
  )
  if (any(qualifying)) {
    matching_probabilities <- tapply(
      rows$.offer_probability[qualifying],
      rows$trade_id[qualifying],
      sum
    )
    trade_probabilities[names(matching_probabilities)] <-
      matching_probabilities
  }
  as.numeric(1 - prod(1 - trade_probabilities))
}

#' Calculate Enchanted Item Probability
#'
#' Calculates the probability that a fully unlocked villager offers one
#' qualifying enchanted equipment item.
#'
#' @param item One supported short item name or canonical Minecraft item ID.
#' @param enchantments Comma-separated `identifier=level` pairs. The
#'   `minecraft:` namespace is optional.
#' @param profession Required for diamond axes; use `"toolsmith"` or
#'   `"weaponsmith"`. Other items infer their profession.
#' @param max_emeralds Inclusive original emerald-price cutoff.
#' @param include_higher_level Whether levels above each request also qualify.
#' @param match `"exact"` requires the complete requested set. `"contains"`
#'   permits additional enchantments.
#'
#' @return One numeric probability.
#' @export
#'
#' @examples
#' enchanted_item_probability('sword', 'sharpness=3')
#' enchanted_item_probability(
#'   item         = 'axe',
#'   enchantments = 'efficiency=2,unbreaking=1',
#'   profession   = 'weaponsmith',
#'   match        = 'contains'
#' )
enchanted_item_probability <- function(
  item,
  enchantments,
  profession = NULL,
  max_emeralds = 64,
  include_higher_level = FALSE,
  match = c('exact', 'contains')
) {
  item <- .normalize_enchanted_item(item, profession)
  query <- .normalize_enchantment_query(
    enchantments,
    multiple = TRUE,
    argument = 'enchantments'
  )
  max_emeralds <- .normalize_max_emeralds(max_emeralds)
  include_higher_level <- .normalize_higher_level(include_higher_level)
  match <- match.arg(match)
  rows <- .profession_offer_probabilities(item$profession)
  rows <- rows[
    rows$gives_1_item == item$item_id &
      rows$functions %in% 'enchant_with_levels' &
      rows$wants_1_quantity_min <= max_emeralds,
    ,
    drop = FALSE
  ]
  if (!nrow(rows)) {
    return(0)
  }
  qualifying <- vapply(
    rows$gives_1_enchantments,
    .matches_enchantment_query,
    logical(1),
    query                = query,
    include_higher_level = include_higher_level,
    match                = match
  )
  as.numeric(sum(rows$.offer_probability[qualifying]))
}
