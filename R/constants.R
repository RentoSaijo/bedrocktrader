# Package Constants -------------------------------------------------------------

# Define pinned Minecraft version.
.bedrock_version <- '1.26.30.5'

# Define villager tier names.
.bedrock_tier_names <- c(
  'novice',
  'apprentice',
  'journeyman',
  'expert',
  'master'
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

# Define villager variant aliases.
.bedrock_variant_aliases <- list(
  plains  = character(),
  desert  = character(),
  jungle  = character(),
  savanna = character(),
  snow    = 'snowy',
  swamp   = character(),
  taiga   = character()
)

# Define public trade columns.
.bedrock_trade_columns <- c(
  'profession',
  'tier',
  'tier_name',
  'total_exp_required',
  'group_id',
  'trade_id',
  'option_id',
  'num_trades',
  'num_to_select',
  'select_all',
  'variants',
  'dimensions',
  'wants_1_item',
  'wants_1_aux_value',
  'wants_1_quantity_min',
  'wants_1_quantity_max',
  'wants_1_price_multiplier',
  'wants_2_item',
  'wants_2_aux_value',
  'wants_2_quantity_min',
  'wants_2_quantity_max',
  'wants_2_price_multiplier',
  'gives_1_item',
  'gives_1_aux_value',
  'gives_1_quantity_min',
  'gives_1_quantity_max',
  'gives_1_color',
  'gives_1_effect',
  'gives_1_potion',
  'gives_1_map_destination',
  'gives_1_enchantments',
  'gives_1_enchantment_count',
  'gives_1_treasure',
  'functions',
  'levels_min',
  'levels_max',
  'outcome_status',
  'max_uses',
  'trader_exp',
  'reward_exp'
)

# Define public probability columns.
.bedrock_probability_columns <- c(
  .bedrock_trade_columns,
  'trade_probability',
  'choice_probability',
  'function_probability',
  'offer_probability',
  'probability_status',
  'probability_basis'
)
