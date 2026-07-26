# Package Constants -------------------------------------------------------------

# Define pinned Mojang release.
.bedrock_raw_url <- 'https://raw.githubusercontent.com/Mojang/bedrock-samples'
.bedrock_version <- '1.26.30.5'
.bedrock_release_tag <- 'v1.26.30.5'
.bedrock_release_date <- as.Date('2026-06-16')
.bedrock_trade_directory <- 'behavior_pack/trading/economy_trades'
.bedrock_variant_path <- 'behavior_pack/entities/villager_v2.json'
.bedrock_enchantment_path <-
  'metadata/vanilladata_modules/mojang-enchantments.json'

# Define pinned source checksums.
.bedrock_blob_shas <- c(
  'behavior_pack/trading/economy_trades/armorer_trades.json' =
    '31d6fd2973645f0c972a3b152b7cb2fcd39bbace',
  'behavior_pack/trading/economy_trades/butcher_trades.json' =
    '4a22616415f3b7b96523aa1198cba9e08c366aa8',
  'behavior_pack/trading/economy_trades/cartographer_trades.json' =
    '994a0e9d2583d1304f727e5507f4af4a31cfde27',
  'behavior_pack/trading/economy_trades/cleric_trades.json' =
    '20dc0260417991beee4bd2e805260c64dbe1c6ff',
  'behavior_pack/trading/economy_trades/farmer_trades.json' =
    'c6b2ec7e61430270e126ac86593cf6bb7868db41',
  'behavior_pack/trading/economy_trades/fisherman_trades.json' =
    'fba7a6b0a37d5e3c4bdb6910fbc7942d9f71b354',
  'behavior_pack/trading/economy_trades/fletcher_trades.json' =
    'fb6917ca882f41bc8a15bf762f02b4aabc398b28',
  'behavior_pack/trading/economy_trades/leather_worker_trades.json' =
    '346d71c1d6436cce636fef7f6a18f0a915c32031',
  'behavior_pack/trading/economy_trades/librarian_trades.json' =
    '2a5a57d4fb591ee398bb27b27776b05252a9adf4',
  'behavior_pack/trading/economy_trades/stone_mason_trades.json' =
    '1c1228c754b35b2944dfcf10a2bf16d96a3b0ef0',
  'behavior_pack/trading/economy_trades/shepherd_trades.json' =
    'fc01fde0623157ffca30e3041673ffac60961340',
  'behavior_pack/trading/economy_trades/tool_smith_trades.json' =
    'fd11c068c55a298ef1c27a030026941ceadb81ee',
  'behavior_pack/trading/economy_trades/weapon_smith_trades.json' =
    '7854722ad086c50ef75f947fba65d9741bfd708e',
  'behavior_pack/entities/villager_v2.json' =
    '8eff99b5176cb9952e217f557bec604fa02f98ac',
  'metadata/vanilladata_modules/mojang-enchantments.json' =
    'ab01e9eaf88ff3a3d25a2b13a2bc1b144ddf8acf'
)

# Define villager level vocabulary.
.bedrock_level_names <- c(
  'novice',
  'apprentice',
  'journeyman',
  'expert',
  'master'
)

# Define profession vocabulary.
.bedrock_professions <- data.frame(
  profession = c(
    'armorer',
    'butcher',
    'cartographer',
    'cleric',
    'farmer',
    'fisherman',
    'fletcher',
    'leatherworker',
    'librarian',
    'stone_mason',
    'shepherd',
    'toolsmith',
    'weaponsmith'
  ),
  display_name = c(
    'Armorer',
    'Butcher',
    'Cartographer',
    'Cleric',
    'Farmer',
    'Fisherman',
    'Fletcher',
    'Leatherworker',
    'Librarian',
    'Mason',
    'Shepherd',
    'Toolsmith',
    'Weaponsmith'
  ),
  source_file = c(
    'armorer_trades.json',
    'butcher_trades.json',
    'cartographer_trades.json',
    'cleric_trades.json',
    'farmer_trades.json',
    'fisherman_trades.json',
    'fletcher_trades.json',
    'leather_worker_trades.json',
    'librarian_trades.json',
    'stone_mason_trades.json',
    'shepherd_trades.json',
    'tool_smith_trades.json',
    'weapon_smith_trades.json'
  ),
  stringsAsFactors = FALSE
)

# Define profession aliases.
.bedrock_profession_aliases <- list(
  armorer       = character(),
  butcher       = character(),
  cartographer  = character(),
  cleric        = character(),
  farmer        = character(),
  fisherman     = character(),
  fletcher      = character(),
  leatherworker = 'leather_worker',
  librarian     = character(),
  stone_mason   = c('mason', 'stonemason'),
  shepherd      = character(),
  toolsmith     = 'tool_smith',
  weaponsmith   = 'weapon_smith'
)

# Define variant vocabulary.
.bedrock_variants <- c(
  'plains',
  'desert',
  'jungle',
  'savanna',
  'snow',
  'swamp',
  'taiga'
)

# Define variant aliases.
.bedrock_variant_aliases <- list(
  plains  = character(),
  desert  = character(),
  jungle  = character(),
  savanna = character(),
  snow    = 'snowy',
  swamp   = character(),
  taiga   = character()
)

# Define librarian enchantment model.
.bedrock_enchantments <- data.frame(
  enchantment = c(
    'aqua_affinity',
    'bane_of_arthropods',
    'binding',
    'blast_protection',
    'breach',
    'channeling',
    'density',
    'depth_strider',
    'efficiency',
    'feather_falling',
    'fire_aspect',
    'fire_protection',
    'flame',
    'fortune',
    'frost_walker',
    'impaling',
    'infinity',
    'knockback',
    'looting',
    'loyalty',
    'luck_of_the_sea',
    'lunge',
    'lure',
    'mending',
    'multishot',
    'piercing',
    'power',
    'projectile_protection',
    'protection',
    'punch',
    'quick_charge',
    'respiration',
    'riptide',
    'sharpness',
    'silk_touch',
    'smite',
    'thorns',
    'unbreaking',
    'vanishing'
  ),
  enchantment_name = c(
    'Aqua Affinity',
    'Bane of Arthropods',
    'Curse of Binding',
    'Blast Protection',
    'Breach',
    'Channeling',
    'Density',
    'Depth Strider',
    'Efficiency',
    'Feather Falling',
    'Fire Aspect',
    'Fire Protection',
    'Flame',
    'Fortune',
    'Frost Walker',
    'Impaling',
    'Infinity',
    'Knockback',
    'Looting',
    'Loyalty',
    'Luck of the Sea',
    'Lunge',
    'Lure',
    'Mending',
    'Multishot',
    'Piercing',
    'Power',
    'Projectile Protection',
    'Protection',
    'Punch',
    'Quick Charge',
    'Respiration',
    'Riptide',
    'Sharpness',
    'Silk Touch',
    'Smite',
    'Thorns',
    'Unbreaking',
    'Curse of Vanishing'
  ),
  max_level = c(
    1L, 5L, 1L, 4L, 4L, 1L, 5L, 3L, 5L, 4L,
    2L, 4L, 1L, 3L, 2L, 5L, 1L, 2L, 3L, 3L,
    3L, 3L, 3L, 1L, 1L, 4L, 5L, 4L, 4L, 2L,
    3L, 3L, 3L, 5L, 1L, 5L, 3L, 3L, 1L
  ),
  treasure = c(
    FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE
  ),
  stringsAsFactors = FALSE
)

# Define specialized enchantments outside librarian model.
.bedrock_special_enchantments <- c(
  'soul_speed',
  'swift_sneak',
  'wind_burst'
)

# Define legacy color values.
.bedrock_colors <- c(
  'white',
  'orange',
  'magenta',
  'light_blue',
  'yellow',
  'lime',
  'pink',
  'gray',
  'light_gray',
  'cyan',
  'purple',
  'blue',
  'brown',
  'green',
  'red',
  'black'
)

# Define suspicious stew effects.
.bedrock_stew_effects <- c(
  'night_vision',
  'jump_boost',
  'weakness',
  'blindness',
  'poison',
  'saturation'
)

# Define public trade columns.
.bedrock_trade_columns <- c(
  'profession',
  'level',
  'level_name',
  'total_exp_required',
  'group_id',
  'trade_id',
  'option_id',
  'trades_in_group',
  'trades_selected',
  'all_trades_selected',
  'variants',
  'dimensions',
  'cost_1_item',
  'cost_1_aux_value',
  'cost_1_quantity_min',
  'cost_1_quantity_max',
  'cost_1_price_multiplier',
  'cost_2_item',
  'cost_2_aux_value',
  'cost_2_quantity_min',
  'cost_2_quantity_max',
  'cost_2_price_multiplier',
  'result_item',
  'result_aux_value',
  'result_quantity_min',
  'result_quantity_max',
  'result_color',
  'result_effect',
  'potion',
  'map_destination',
  'enchantment',
  'enchantment_name',
  'enchantment_level',
  'enchantment_max_level',
  'treasure',
  'generator',
  'enchanting_power_min',
  'enchanting_power_max',
  'outcome_status',
  'max_uses',
  'villager_exp',
  'player_exp'
)

# Define public probability columns.
.bedrock_probability_columns <- c(
  'profession',
  'level',
  'level_name',
  'group_id',
  'trade_id',
  'option_id',
  'variants',
  'dimensions',
  'result_item',
  'result_aux_value',
  'result_color',
  'result_effect',
  'potion',
  'map_destination',
  'enchantment',
  'enchantment_name',
  'enchantment_level',
  'cost_1_quantity_min',
  'cost_1_quantity_max',
  'outcome_status',
  'selection_probability',
  'choice_probability',
  'generator_probability',
  'probability',
  'probability_status',
  'probability_basis'
)
