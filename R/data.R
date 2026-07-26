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

# Load profession tables.
.load_profession_tables <- function(professions) {
  release <- .pinned_release()
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
    content <- .fetch_pinned_file(source_path)
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
#' Lists the 13 employable vanilla villager professions understood by
#' `bedrocktrader`. Each row also summarizes trade-table features that may need
#' special handling during analysis.
#'
#' @return A base data frame with one row per profession:
#'
#'   - `profession` (`character`) is the canonical identifier accepted by
#'     [villager_trades()].
#'   - `display_name` (`character`) is the human-readable profession name.
#'   - `aliases` (`character`) contains additional accepted identifiers
#'     separated by commas. `NA` means that the profession has no aliases.
#'   - `context_sensitive` (`logical`) is `TRUE` when at least one offer uses a
#'     villager-variant or dimension filter. Such offers are not available in
#'     every context.
#'   - `contains_item_choices` (`logical`) is `TRUE` when at least one item
#'     position contains Mojang's `choice` array. [villager_trades()] expands
#'     those alternatives into separate rows.
#'   - `contains_dynamic_functions` (`logical`) is `TRUE` when at least one
#'     item-generation function changes an offered item, such as by adding an
#'     enchantment, potion, dye, or exploration-map destination.
#'
#' @details
#' The feature flags describe the selected release, not permanent properties of
#' a profession. To calculate them, the function downloads and inspects all 13
#' profession tables. It does not evaluate filters or generate function
#' outcomes.
#' @export
#'
#' @examples
#' \dontrun{
#' professions <- villager_professions()
#' professions
#'
#' professions[
#'   professions$context_sensitive,
#'   c('profession', 'context_sensitive')
#' ]
#'
#' }
villager_professions <- function() {
  professions <- .bedrock_professions$profession
  object      <- .load_profession_tables(professions)
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
#' Lists the seven vanilla villager biome variants and their stored
#' `minecraft:mark_variant` values. Trade-table filters use these numeric values
#' to make certain offers dependent on a villager's variant.
#'
#' @return A base data frame with one row per variant:
#'
#'   - `variant` (`character`) is the canonical package identifier.
#'   - `mark_variant` (`integer`) is the value stored by Mojang's
#'     `minecraft:mark_variant` entity component and tested by vanilla
#'     `is_mark_variant` filters.
#'   - `aliases` (`character`) contains additional accepted names separated by
#'     commas. `NA` means that the variant has no aliases. The `snow` variant
#'     has the alias `snowy`.
#'
#' @details
#' Values are derived from the selected release's vanilla `villager_v2` entity
#' definition rather than assumed from a fixed lookup table. This function does
#' not determine the variant of a particular villager.
#' @export
#'
#' @examples
#' \dontrun{
#' variants <- villager_variants()
#' variants
#'
#' variants[variants$variant == 'snow', ]
#'
#' }
villager_variants <- function() {
  release <- .pinned_release()
  content <- .fetch_pinned_file(.bedrock_variant_path)
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
#' Retrieves the official vanilla trade table for one supported profession and
#' converts its nested structure into a flat base data frame.
#'
#' @param profession One canonical profession identifier or an alias listed by
#'   [villager_professions()]. The default is `"armorer"`.
#' @return A base data frame with one row per concrete combination of item
#' choices and 40 atomic columns.
#'
#' @section How to read a row:
#' A Bedrock profession table contains five villager levels. Each level contains
#' one or more selection groups, each group contains candidate trades, and a
#' candidate may contain alternative items. `villager_trades()` expands the
#' cross-product of those item alternatives. Consequently, rows sharing a
#' `candidate_id` represent alternative item realizations of one candidate;
#' `option_id` identifies the individual expanded row.
#'
#' The result describes every possible offer in the profession table. It does
#' not represent the offers selected for a particular villager, calculate offer
#' probabilities, evaluate contextual filters, or generate dynamic function
#' outcomes.
#'
#' @section Trade columns:
#'
#' - `profession` (`character`): canonical profession identifier.
#' - `level` (`integer`): numeric villager tier from 1 through 5.
#' - `level_name` (`character`): `novice`, `apprentice`, `journeyman`, `expert`,
#'   or `master`.
#' - `total_exp_required` (`double`): cumulative experience the villager, rather
#'   than the player, needs to unlock the level.
#' - `group_id` (`character`): package-generated identifier for a selection
#'   group, formatted from profession, level, and group position.
#' - `candidate_id` (`character`): package-generated identifier for one source
#'   trade within a group. It can repeat after item choices are expanded.
#' - `option_id` (`character`): unique identifier for one expanded output row.
#' - `candidate_count` (`integer`): number of source trade candidates in the
#'   group before item-choice expansion.
#' - `num_to_select` (`integer`): number of candidates Mojang selects from the
#'   group. `-1` represents the select-all convention.
#' - `select_all` (`logical`): convenient indicator for
#'   `num_to_select == -1`.
#' - `max_uses` (`double`): number of uses before the offer locks until the
#'   villager restocks.
#' - `trader_exp` (`double`): experience the villager gains when the trade is
#'   completed.
#' - `reward_exp` (`logical`): whether completing the trade rewards the player
#'   with experience.
#'
#' The three item-slot prefixes describe the exchange from the player's
#' perspective:
#'
#' - `wants_1_` is the first item the player pays.
#' - `wants_2_` is an optional second item the player pays. All nine fields are
#'   typed `NA` when a trade has only one input.
#' - `gives_1_` is the item the villager gives the player.
#'
#' @section Item-slot columns:
#' Each prefix is combined with the following nine fields:
#'
#' - `item_raw` (`character`): exact Mojang item identifier, including a
#'   numeric auxiliary suffix when one is present.
#' - `item` (`character`): normalized item identifier without that suffix.
#' - `aux_value` (`integer`): numeric auxiliary or legacy data value removed
#'   from `item_raw`; `NA` when no suffix exists.
#' - `quantity_min` and `quantity_max` (`double`): lower and upper bounds of the
#'   quantity. They are equal for a fixed quantity. An omitted source quantity
#'   becomes one.
#' - `price_multiplier` (`double`): Mojang's multiplier for price increases
#'   caused by supply and demand.
#' - `functions` (`character`): item-generation function names in source order,
#'   separated by commas.
#' - `function_parameters` (`character`): a JSON array whose objects align with
#'   the names in `functions`.
#' - `filters` (`character`): unevaluated filter JSON. A top-level `position` or
#'   `choice` key records where the filter appeared in Mojang's item structure.
#'
#' Optional properties remain `NA` when Mojang omits them; the package does not
#' replace them with Minecraft's runtime defaults. Functions, function
#' parameters, and filters are also `NA` when absent. The generated IDs are
#' deterministic for a release's source order, but their meaning should be
#' compared by content before matching different releases.
#'
#' @references
#' [Microsoft, "Creating a Trade Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)
#' @export
#'
#' @examples
#' \dontrun{
#' armorer <- villager_trades()
#' armorer[
#'   ,
#'   c(
#'     'level_name',
#'     'wants_1_item',
#'     'wants_1_quantity_min',
#'     'gives_1_item'
#'   )
#' ]
#'
#' cartographer <- villager_trades(
#'   profession = 'cartographer'
#' )
#' two_inputs <- !is.na(cartographer$wants_2_item)
#' cartographer[
#'   two_inputs,
#'   c('wants_1_item', 'wants_2_item', 'gives_1_item')
#' ]
#'
#' function_row <- which(!is.na(cartographer$gives_1_functions))[[1L]]
#' jsonlite::fromJSON(
#'   cartographer$gives_1_function_parameters[[function_row]]
#' )
#'
#' mason <- villager_trades('mason')
#' mason[
#'   mason$select_all,
#'   c('group_id', 'candidate_id', 'option_id', 'num_to_select')
#' ]
#' }
villager_trades <- function(profession = 'armorer') {
  profession <- .normalize_profession_input(profession)
  object     <- .load_profession_tables(profession)
  .flatten_trade_table(
    table   = object$professions[[profession]],
    release = object$release
  )
}
