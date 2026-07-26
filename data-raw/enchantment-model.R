# Enchantment Data Helpers ------------------------------------------------------

# Create enchantment-level rows.
.enchantment_rows <- function(enchantment, weight, ranges) {
  data.frame(
    enchantment = enchantment,
    weight      = as.numeric(weight),
    level       = seq_len(nrow(ranges)),
    power_min   = as.numeric(ranges[, 1L]),
    power_max   = as.numeric(ranges[, 2L]),
    stringsAsFactors = FALSE
  )
}

# Combine enchantment definitions.
.combine_enchantments <- function(...) {
  do.call(rbind, list(...))
}

# Define protection enchantments.
.protection_enchantments <- function() {
  .combine_enchantments(
    .enchantment_rows(
      'blast_protection',
      2,
      rbind(c(5, 12), c(13, 20), c(21, 28), c(29, 37))
    ),
    .enchantment_rows(
      'fire_protection',
      5,
      rbind(c(10, 17), c(18, 25), c(26, 33), c(34, 42))
    ),
    .enchantment_rows(
      'projectile_protection',
      5,
      rbind(c(3, 8), c(9, 14), c(15, 20), c(21, 27))
    ),
    .enchantment_rows(
      'protection',
      10,
      rbind(c(5, 12), c(13, 20), c(21, 28), c(29, 37))
    )
  )
}

# Define shared armor enchantments.
.armor_enchantments <- function() {
  .combine_enchantments(
    .enchantment_rows(
      'thorns',
      1,
      rbind(c(10, 29), c(30, 49), c(50, 100))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    ),
    .protection_enchantments()
  )
}

# Define shared tool enchantments.
.tool_enchantments <- function() {
  .combine_enchantments(
    .enchantment_rows(
      'efficiency',
      10,
      rbind(c(1, 10), c(11, 20), c(21, 30), c(31, 40), c(41, 91))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    ),
    .enchantment_rows(
      'fortune',
      2,
      rbind(c(15, 23), c(24, 32), c(33, 83))
    ),
    .enchantment_rows('silk_touch', 1, rbind(c(15, 65)))
  )
}

# Define shared damage enchantments.
.damage_enchantments <- function() {
  .combine_enchantments(
    .enchantment_rows(
      'bane_of_arthropods',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 28), c(29, 36), c(37, 57))
    ),
    .enchantment_rows(
      'sharpness',
      10,
      rbind(c(1, 11), c(12, 22), c(23, 33), c(34, 44), c(45, 65))
    ),
    .enchantment_rows(
      'smite',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 28), c(29, 36), c(37, 57))
    )
  )
}

# Enchantment Data --------------------------------------------------------------

# Define eligible enchantments by item type.
.bedrock_equipment_enchantments <- list(
  helmet = .combine_enchantments(
    .enchantment_rows('aqua_affinity', 2, rbind(c(1, 41))),
    .enchantment_rows(
      'respiration',
      2,
      rbind(c(10, 19), c(20, 29), c(30, 60))
    ),
    .armor_enchantments()
  ),
  chestplate = .armor_enchantments(),
  leggings = .armor_enchantments(),
  boots = .combine_enchantments(
    .enchantment_rows(
      'feather_falling',
      5,
      rbind(c(5, 10), c(11, 16), c(17, 22), c(23, 29))
    ),
    .armor_enchantments(),
    .enchantment_rows(
      'depth_strider',
      2,
      rbind(c(10, 19), c(20, 29), c(30, 45))
    )
  ),
  sword = .combine_enchantments(
    .enchantment_rows(
      'fire_aspect',
      2,
      rbind(c(10, 19), c(20, 80))
    ),
    .enchantment_rows(
      'knockback',
      5,
      rbind(c(5, 24), c(25, 75))
    ),
    .enchantment_rows(
      'looting',
      2,
      rbind(c(15, 23), c(24, 32), c(33, 83))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    ),
    .damage_enchantments()
  ),
  axe = .combine_enchantments(
    .tool_enchantments(),
    .damage_enchantments()
  ),
  pickaxe = .tool_enchantments(),
  shovel = .tool_enchantments(),
  bow = .combine_enchantments(
    .enchantment_rows('flame', 2, rbind(c(20, 50))),
    .enchantment_rows(
      'power',
      10,
      rbind(c(1, 10), c(11, 20), c(21, 30), c(31, 40), c(41, 56))
    ),
    .enchantment_rows(
      'punch',
      2,
      rbind(c(12, 31), c(32, 57))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    ),
    .enchantment_rows('infinity', 1, rbind(c(20, 50)))
  ),
  crossbow = .combine_enchantments(
    .enchantment_rows(
      'quick_charge',
      5,
      rbind(c(12, 31), c(32, 50))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    ),
    .enchantment_rows('multishot', 2, rbind(c(20, 50))),
    .enchantment_rows(
      'piercing',
      10,
      rbind(c(1, 10), c(11, 20), c(21, 30), c(31, 50))
    )
  ),
  fishing_rod = .combine_enchantments(
    .enchantment_rows(
      'luck_of_the_sea',
      2,
      rbind(c(15, 23), c(24, 32), c(33, 83))
    ),
    .enchantment_rows(
      'lure',
      2,
      rbind(c(15, 23), c(24, 32), c(33, 83))
    ),
    .enchantment_rows(
      'unbreaking',
      5,
      rbind(c(5, 12), c(13, 20), c(21, 71))
    )
  )
)

# Define enchanted trade items.
.bedrock_enchanted_items <- data.frame(
  item = c(
    'minecraft:diamond_helmet',
    'minecraft:diamond_chestplate',
    'minecraft:diamond_leggings',
    'minecraft:diamond_boots',
    'minecraft:iron_sword',
    'minecraft:diamond_sword',
    'minecraft:iron_axe',
    'minecraft:diamond_axe',
    'minecraft:iron_pickaxe',
    'minecraft:diamond_pickaxe',
    'minecraft:iron_shovel',
    'minecraft:diamond_shovel',
    'minecraft:bow',
    'minecraft:crossbow',
    'minecraft:fishing_rod'
  ),
  item_type = c(
    'helmet',
    'chestplate',
    'leggings',
    'boots',
    'sword',
    'sword',
    'axe',
    'axe',
    'pickaxe',
    'pickaxe',
    'shovel',
    'shovel',
    'bow',
    'crossbow',
    'fishing_rod'
  ),
  enchantability = c(
    10L,
    10L,
    10L,
    10L,
    14L,
    10L,
    14L,
    10L,
    14L,
    10L,
    14L,
    10L,
    1L,
    1L,
    1L
  ),
  stringsAsFactors = FALSE
)

# Define incompatible enchantments.
.bedrock_enchantment_conflicts <- list(
  c(
    'blast_protection',
    'fire_protection',
    'projectile_protection',
    'protection'
  ),
  c('bane_of_arthropods', 'sharpness', 'smite'),
  c('fortune', 'silk_touch'),
  c('multishot', 'piercing')
)

# Probability Helpers -----------------------------------------------------------

# Calculate triangular multiplier distribution.
.enchantment_multiplier_cdf <- function(value) {
  output <- numeric(length(value))
  lower <- value > 0.85 & value <= 1
  upper <- value > 1 & value < 1.15
  output[value >= 1.15] <- 1
  output[lower] <- (value[lower] - 0.85)^2 / (2 * 0.15^2)
  output[upper] <- 1 -
    (1.15 - value[upper])^2 / (2 * 0.15^2)
  output
}

# Calculate modified enchanting-power probabilities.
.modified_power_probabilities <- function(
  levels_min,
  levels_max,
  enchantability
) {
  probabilities <- numeric()
  roll_max      <- floor(enchantability / 4)
  level_values  <- seq.int(levels_min, levels_max)
  branch_probability <- 1 /
    length(level_values) /
    (roll_max + 1)^2
  for (source_level in level_values) {
    for (roll_1 in 0:roll_max) {
      for (roll_2 in 0:roll_max) {
        base_power <- source_level + 1 + roll_1 + roll_2
        possible <- seq_len(ceiling(base_power * 1.15 + 0.5))
        upper <- .enchantment_multiplier_cdf(
          (possible + 0.5) / base_power
        )
        lower <- .enchantment_multiplier_cdf(
          (possible - 0.5) / base_power
        )
        branch <- (upper - lower) * branch_probability
        names(branch) <- as.character(possible)
        missing <- setdiff(names(branch), names(probabilities))
        probabilities[missing] <- 0
        probabilities[names(branch)] <-
          probabilities[names(branch)] + branch
      }
    }
  }
  probabilities[probabilities > .Machine$double.eps]
}

# Find eligible enchantment levels.
.eligible_enchantments <- function(item_type, power) {
  definitions <- .bedrock_equipment_enchantments[[item_type]]
  eligible <- definitions[
    definitions$power_min <= power &
      definitions$power_max >= power,
    ,
    drop = FALSE
  ]
  if (!nrow(eligible)) {
    return(eligible)
  }
  highest <- vapply(
    split(eligible$level, eligible$enchantment),
    max,
    integer(1)
  )
  keep <- vapply(
    seq_len(nrow(eligible)),
    function(index) {
      eligible$level[[index]] ==
        highest[[eligible$enchantment[[index]]]]
    },
    logical(1)
  )
  eligible[keep, , drop = FALSE]
}

# Check enchantment conflict.
.enchantments_conflict <- function(left, right) {
  if (identical(left, right)) {
    return(TRUE)
  }
  any(vapply(
    .bedrock_enchantment_conflicts,
    function(group) left %in% group && right %in% group,
    logical(1)
  ))
}

# Format complete enchantment set.
.format_enchantment_set <- function(enchantments, levels) {
  values <- paste0('minecraft:', enchantments, '=', levels)
  paste(sort(values), collapse = ',')
}

# Enumerate weighted enchantment selection.
.select_enchantment_sets <- function(
  eligible,
  power,
  selected = character(),
  selected_levels = integer(),
  probability = 1
) {
  rows <- list()
  row_n <- 0L
  total_weight <- sum(eligible$weight)
  for (index in seq_len(nrow(eligible))) {
    enchantment <- eligible$enchantment[[index]]
    level       <- eligible$level[[index]]
    selection_probability <- eligible$weight[[index]] / total_weight
    next_enchantments <- c(selected, enchantment)
    next_levels       <- c(selected_levels, level)
    next_probability  <- probability * selection_probability
    conflicts <- vapply(
      eligible$enchantment,
      .enchantments_conflict,
      logical(1),
      right = enchantment
    )
    remaining <- eligible[!conflicts, , drop = FALSE]
    continuation_probability <- min((power + 1) / 50, 1)
    if (!nrow(remaining)) {
      row_n <- row_n + 1L
      rows[[row_n]] <- data.frame(
        enchantments = .format_enchantment_set(
          next_enchantments,
          next_levels
        ),
        enchantment_count = length(next_enchantments),
        probability       = next_probability,
        stringsAsFactors  = FALSE
      )
    } else {
      row_n <- row_n + 1L
      rows[[row_n]] <- data.frame(
        enchantments = .format_enchantment_set(
          next_enchantments,
          next_levels
        ),
        enchantment_count = length(next_enchantments),
        probability       = next_probability *
          (1 - continuation_probability),
        stringsAsFactors  = FALSE
      )
      row_n <- row_n + 1L
      rows[[row_n]] <- .select_enchantment_sets(
        eligible          = remaining,
        power             = floor(power / 2),
        selected          = next_enchantments,
        selected_levels   = next_levels,
        probability       = next_probability *
          continuation_probability
      )
    }
  }
  do.call(rbind, rows)
}

# Model Helpers -----------------------------------------------------------------

# Model complete equipment enchantment sets.
.equipment_enchantment_outcomes <- function(
  item,
  levels_min,
  levels_max
) {
  item_index <- match(item, .bedrock_enchanted_items$item)
  if (is.na(item_index)) {
    stop(
      'No enchanting model is registered for `',
      item,
      '`.',
      call. = FALSE
    )
  }
  item_type      <- .bedrock_enchanted_items$item_type[[item_index]]
  enchantability <- .bedrock_enchanted_items$enchantability[[item_index]]
  power_probabilities <- .modified_power_probabilities(
    levels_min,
    levels_max,
    enchantability
  )
  rows  <- list()
  row_n <- 0L
  for (power_text in names(power_probabilities)) {
    power    <- as.integer(power_text)
    eligible <- .eligible_enchantments(item_type, power)
    if (!nrow(eligible)) {
      stop(
        'No enchantments are eligible for `',
        item,
        '` at enchanting power ',
        power,
        '.',
        call. = FALSE
      )
    }
    selection <- .select_enchantment_sets(eligible, power)
    selection$probability <- selection$probability *
      power_probabilities[[power_text]]
    row_n <- row_n + 1L
    rows[[row_n]] <- selection
  }
  outcomes <- do.call(rbind, rows)
  probabilities <- tapply(
    outcomes$probability,
    outcomes$enchantments,
    sum
  )
  counts <- tapply(
    outcomes$enchantment_count,
    outcomes$enchantments,
    unique
  )
  result <- data.frame(
    enchantments     = names(probabilities),
    enchantment_count = as.integer(unlist(counts[names(probabilities)])),
    probability      = as.numeric(probabilities),
    stringsAsFactors = FALSE
  )
  result <- result[order(result$enchantments), , drop = FALSE]
  rownames(result) <- NULL
  result
}
