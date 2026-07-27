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
  names(levels) <- identifiers
  levels
}

# Match one modeled enchantment set.
.matches_enchantment_query <- function(
  value,
  query,
  include_higher_level,
  match
) {
  modeled <- .parse_modeled_enchantments(value)
  requested <- query$level
  names(requested) <- query$enchantment
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

#' Calculate enchanted book probability
#'
#' Calculates the probability that a fully unlocked librarian has at least one
#' qualifying enchanted-book offer in Minecraft Bedrock Edition `1.26.30.5`.
#'
#' @param enchantment One `identifier=level` pair. The `minecraft:` namespace
#'   is optional. The default is the alphabetically first attainable
#'   enchantment.
#' @param max_emeralds Inclusive original emerald-price cutoff from 0 through
#'   64.
#' @param include_higher_level `FALSE` requires the requested level. `TRUE`
#'   also counts higher valid levels of the same enchantment.
#'
#' @returns One numeric probability from 0 through 1.
#'
#' @details
#' A fully unlocked Bedrock librarian has four independent opportunities to
#' offer an enchanted book. The book candidate is selected with probability
#' `1/2` at novice, apprentice, and journeyman tiers and `1/3` at expert. Within
#' each selected book trade, the model chooses one of 39 enchantments uniformly,
#' then chooses uniformly among that enchantment's valid levels and generates
#' its emerald price.
#'
#' The function sums all qualifying level-and-price offers within each source
#' trade, then calculates one minus the probability that none of the four book
#' trades qualifies. A recognized enchantment that villagers cannot offer,
#' such as Soul Speed, returns zero. Unknown identifiers and invalid levels
#' produce errors; use [enchantments()] to inspect the registry.
#'
#' `max_emeralds` applies to the original modeled price before demand, curing,
#' or other adjustments. The default `64` includes every book price. A cutoff
#' of `26` is useful when screening for the commonly targeted low-price
#' librarian books, but the function does not simulate curing or promise a
#' post-cure price.
#'
#' Probabilities for book identity, level, and price follow the documented
#' model described in [villager_trades()]. They are exact under that model,
#' rather than a guarantee about undocumented Bedrock internals.
#'
#' @references
#' [Microsoft, "Introduction to Enchantments"](https://learn.microsoft.com/en-us/minecraft/creator/documents/introtoenchantments?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Trading"](https://minecraft.wiki/w/Trading)
#' @export
#'
#' @examples
#' enchanted_book_probability()
#' enchanted_book_probability('mending=1', max_emeralds = 26)
#' enchanted_book_probability(
#'   'efficiency=2',
#'   include_higher_level = TRUE
#' )
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
  trade_probabilities <- numeric(length(book_trade_ids))
  names(trade_probabilities) <- book_trade_ids
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

#' Calculate enchanted item probability
#'
#' Calculates the probability that a fully unlocked villager offers one
#' qualifying enchanted equipment item in Minecraft Bedrock Edition
#' `1.26.30.5`.
#'
#' @param item One supported short item name or canonical Minecraft item ID.
#' @param enchantments Comma-separated `identifier=level` pairs. The
#'   `minecraft:` namespace is optional.
#' @param profession Required for diamond axes; use `"toolsmith"` or
#'   `"weaponsmith"`. Other items infer their profession.
#' @param max_emeralds Inclusive original emerald-price cutoff from 0 through
#'   64.
#' @param include_higher_level `FALSE` requires every requested level. `TRUE`
#'   treats each requested level as a minimum.
#' @param match `"exact"` requires the complete enchantment set to contain only
#'   the requested enchantments. `"contains"` permits additional enchantments.
#'
#' @returns One numeric probability from 0 through 1.
#'
#' @section Items and professions:
#' Short names are `helmet`, `chestplate`, `leggings`, `boots`, `sword`, `axe`,
#' `pickaxe`, `shovel`, `bow`, `crossbow`, and `fishing_rod`. Armor, swords,
#' axes, pickaxes, and shovels refer to their diamond forms. Their corresponding
#' namespaced item IDs are also accepted. Iron equipment is outside this
#' analysis interface.
#'
#' Profession is inferred as armorer, fisherman, fletcher, toolsmith, or
#' weaponsmith. Diamond axes appear in two profession tables, so `profession`
#' is required for that item. The toolsmith trade is selected with probability
#' `1/2`; the weaponsmith trade is guaranteed. Profession aliases accepted by
#' [villager_professions()] remain valid.
#'
#' @section Enchantment matching:
#' Input follows the atomic representation returned by [villager_trades()], for
#' example `minecraft:efficiency=2,minecraft:unbreaking=1`. Whitespace and pair
#' order do not matter, capitalization is normalized, and `minecraft:` may be
#' omitted. Display names are not accepted; [enchantments()] lists canonical
#' identifiers and valid levels.
#'
#' With `match = "exact"`, the modeled item must have exactly the requested
#' enchantment identifiers. With `match = "contains"`, every requested
#' enchantment must appear, but unrequested enchantments may also occur. When
#' `include_higher_level = TRUE`, either rule accepts levels at or above each
#' requested value.
#'
#' Recognized but impossible conditions return zero. This includes
#' item-inapplicable enchantments and incompatible combinations such as Fortune
#' with Silk Touch. Malformed pairs, unknown identifiers, repeated identifiers,
#' and levels outside the registry produce errors.
#'
#' @section Probability and price:
#' The result includes source-trade selection and the complete documented
#' `enchant_with_levels` distribution for the requested item. It sums the exact
#' offers whose enchantment set and original emerald price meet the query.
#'
#' `max_emeralds` is evaluated before demand, curing, or other adjustments. Its
#' default of `64` includes every modeled equipment price. It is a budget filter,
#' not a prediction of the price after curing; price multipliers differ across
#' equipment trades.
#'
#' The returned value is exact under the documented model described in
#' [villager_trades()], rather than a guarantee about undocumented Bedrock
#' internals.
#'
#' @references
#' [Microsoft, "Loot Tables Documentation - Enchanting Tables"](https://learn.microsoft.com/en-us/minecraft/creator/reference/content/loottablereference/examples/loottabledefinitions/enchantingtables?view=minecraft-bedrock-stable)
#'
#' [Minecraft Wiki, "Enchanting table mechanics," revision 3681507](https://minecraft.wiki/w/Enchanting_table_mechanics?oldid=3681507)
#' @export
#'
#' @examples
#' enchanted_item_probability('sword', 'sharpness=3')
#'
#' enchanted_item_probability(
#'   item                 = 'pickaxe',
#'   enchantments         = 'efficiency=2',
#'   include_higher_level = TRUE,
#'   match                = 'contains'
#' )
#'
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
