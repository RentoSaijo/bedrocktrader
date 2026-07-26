# Package Constants -------------------------------------------------------------

# Define Mojang repository endpoints.
.bedrock_repository <- 'Mojang/bedrock-samples'
.bedrock_repository_url <- 'https://github.com/Mojang/bedrock-samples'
.bedrock_api_url <- 'https://api.github.com/repos/Mojang/bedrock-samples'
.bedrock_raw_url <- 'https://raw.githubusercontent.com/Mojang/bedrock-samples'
.bedrock_version_path <- 'version.json'
.bedrock_trade_directory <- 'behavior_pack/trading/economy_trades'
.bedrock_variant_path <- 'behavior_pack/entities/villager_v2.json'
.bedrock_parser_version <- 1L

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
