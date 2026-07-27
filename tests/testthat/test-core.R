# Core Contracts ---------------------------------------------------------------

# Test metadata contracts.
testthat::test_that('metadata tables retain their public contracts', {
  exports <- getNamespaceExports('bedrocktrader')
  testthat::expect_setequal(
    exports,
    c(
      'enchanted_book_probability',
      'enchanted_item_probability',
      'enchantments',
      'villager_professions',
      'villager_tiers',
      'villager_trades',
      'villager_variants'
    )
  )
  professions <- bedrocktrader::villager_professions()
  variants    <- bedrocktrader::villager_variants()
  tiers       <- bedrocktrader::villager_tiers()
  registry    <- bedrocktrader::enchantments()
  testthat::expect_identical(dim(professions), c(13L, 6L))
  testthat::expect_identical(dim(variants), c(7L, 3L))
  testthat::expect_identical(dim(tiers), c(5L, 3L))
  testthat::expect_identical(dim(registry), c(42L, 6L))
  testthat::expect_equal(sum(registry$villager_attainable), 39)
})

# Test trade hierarchy contracts.
testthat::test_that('trade views preserve hierarchy and probabilities', {
  trades  <- bedrocktrader::villager_trades(view = 'trade')
  options <- bedrocktrader::villager_trades(view = 'option')
  offers  <- bedrocktrader::villager_trades(view = 'offer')
  testthat::expect_identical(
    vapply(
      list(trades, options, offers),
      class,
      character(1)
    ),
    rep('data.frame', 3L)
  )
  testthat::expect_identical(
    vapply(
      list(trades, options, offers),
      nrow,
      integer(1)
    ),
    c(18L, 842L, 7522L)
  )
  testthat::expect_identical(
    vapply(
      list(trades, options, offers),
      ncol,
      integer(1)
    ),
    c(29L, 30L, 31L)
  )
  testthat::expect_true(all(vapply(offers, is.atomic, logical(1))))
  for (prefix in c('wants_1', 'wants_2', 'gives_1')) {
    minimum <- offers[[paste0(prefix, '_quantity_min')]]
    maximum <- offers[[paste0(prefix, '_quantity_max')]]
    populated <- !is.na(minimum)
    testthat::expect_identical(is.na(minimum), is.na(maximum))
    testthat::expect_true(all(minimum[populated] == maximum[populated]))
  }
  testthat::expect_false(anyDuplicated(offers$offer_id) > 0L)
  testthat::expect_setequal(options$option_id, offers$option_id)
  option_probabilities <- options$offer_probability
  names(option_probabilities) <- options$option_id
  offer_probabilities <- tapply(
    offers$offer_probability,
    offers$option_id,
    sum
  )
  testthat::expect_equal(
    as.numeric(offer_probabilities[names(option_probabilities)]),
    as.numeric(option_probabilities),
    tolerance = 1e-12
  )
  option_probabilities <- tapply(
    options$offer_probability,
    options$trade_id,
    sum
  )
  trade_probabilities <- tapply(
    trades$offer_probability,
    trades$trade_id,
    sum
  )
  testthat::expect_equal(
    as.numeric(option_probabilities[names(trade_probabilities)]),
    as.numeric(trade_probabilities),
    tolerance = 1e-12
  )
})

# Test pinned contextual behavior.
testthat::test_that('context and source multiplicity remain explicit', {
  librarian <- bedrocktrader::villager_trades('librarian')
  candles <- librarian[
    grepl('candle', librarian$gives_1_item),
    ,
    drop = FALSE
  ]
  testthat::expect_identical(
    candles$gives_1_item,
    c('minecraft:red_candle', 'minecraft:yellow_candle')
  )
  testthat::expect_equal(candles$offer_probability, c(0.75, 0.25))
  testthat::expect_equal(candles$num_trades, c(4, 4))
  testthat::expect_error(
    bedrocktrader::villager_trades('fisherman'),
    '`variant` is required'
  )
  fisherman <- bedrocktrader::villager_trades(
    profession = 'fisherman',
    variant    = 'snowy'
  )
  master <- fisherman[fisherman$tier == 5L, , drop = FALSE]
  testthat::expect_identical(master$num_to_select, c(-1L, -1L))
  testthat::expect_equal(master$offer_probability, c(1, 1))
})

# Test analysis contracts.
testthat::test_that('enchantment analyses retain known probabilities', {
  default_book <- bedrocktrader::enchanted_book_probability()
  mending <- bedrocktrader::enchanted_book_probability(
    enchantment  = 'minecraft:mending=1',
    max_emeralds = 26
  )
  toolsmith <- bedrocktrader::enchanted_item_probability(
    item         = 'axe',
    enchantments = 'efficiency=2',
    profession   = 'toolsmith'
  )
  weaponsmith <- bedrocktrader::enchanted_item_probability(
    item         = 'axe',
    enchantments = 'efficiency=2',
    profession   = 'weaponsmith'
  )
  impossible <- bedrocktrader::enchanted_item_probability(
    item         = 'pickaxe',
    enchantments = 'sharpness=1'
  )
  testthat::expect_equal(
    default_book,
    0.0461930230048369,
    tolerance = 1e-12
  )
  testthat::expect_equal(
    mending,
    0.027910633381184,
    tolerance = 1e-12
  )
  testthat::expect_equal(weaponsmith, 2 * toolsmith, tolerance = 1e-12)
  testthat::expect_identical(impossible, 0)
  testthat::expect_error(
    bedrocktrader::enchanted_book_probability('unknown=1'),
    'Unknown enchantment'
  )
  testthat::expect_error(
    bedrocktrader::enchanted_item_probability('sword', 'sharpness'),
    'identifier=level'
  )
})
