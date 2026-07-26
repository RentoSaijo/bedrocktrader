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

# Define compact trade columns.
.bedrock_compact_trade_columns <- c(
  'profession',
  'tier',
  'group_id',
  'num_trades',
  'num_to_select',
  'trade_id',
  'wants_1_item',
  'wants_1_quantity_min',
  'wants_1_quantity_max',
  'wants_1_price_multiplier',
  'wants_2_item',
  'wants_2_quantity_min',
  'wants_2_quantity_max',
  'wants_2_price_multiplier',
  'gives_1_item',
  'gives_1_quantity_min',
  'gives_1_quantity_max',
  'gives_1_color',
  'gives_1_effect',
  'gives_1_potion',
  'gives_1_map_destination',
  'gives_1_enchantments',
  'gives_1_treasure',
  'functions',
  'max_uses',
  'trader_exp',
  'reward_exp',
  'offer_probability',
  'probability_status'
)

# Define expanded trade columns.
.bedrock_expanded_trade_columns <- append(
  .bedrock_compact_trade_columns,
  'option_id',
  after = match('trade_id', .bedrock_compact_trade_columns)
)
