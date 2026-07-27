# Calculate enchanted book probability

Calculates the probability that a fully unlocked librarian has at least
one qualifying enchanted-book offer in Minecraft Bedrock Edition
`1.26.30.5`.

## Usage

``` r
enchanted_book_probability(
  enchantment = "minecraft:aqua_affinity=1",
  max_emeralds = 64,
  include_higher_level = FALSE
)
```

## Arguments

- enchantment:

  One `identifier=level` pair. The `minecraft:` namespace is optional.
  The default is the alphabetically first attainable enchantment.

- max_emeralds:

  Inclusive original emerald-price cutoff from 0 through 64.

- include_higher_level:

  `FALSE` requires the requested level. `TRUE` also counts higher valid
  levels of the same enchantment.

## Value

One numeric probability from 0 through 1.

## Details

A fully unlocked Bedrock librarian has four independent opportunities to
offer an enchanted book. The book candidate is selected with probability
`1/2` at novice, apprentice, and journeyman tiers and `1/3` at expert.
Within each selected book trade, the model chooses one of 39
enchantments uniformly, then chooses uniformly among that enchantment's
valid levels and generates its emerald price.

The function sums all qualifying level-and-price offers within each
source trade, then calculates one minus the probability that none of the
four book trades qualifies. A recognized enchantment that villagers
cannot offer, such as Soul Speed, returns zero. Unknown identifiers and
invalid levels produce errors; use
[`enchantments()`](https://rentosaijo.github.io/bedrocktrader/reference/enchantments.md)
to inspect the registry.

`max_emeralds` applies to the original modeled price before demand,
curing, or other adjustments. The default `64` includes every book
price. A cutoff of `26` is useful when screening for the commonly
targeted low-price librarian books, but the function does not simulate
curing or promise a post-cure price.

Probabilities for book identity, level, and price follow the documented
model described in
[`villager_trades()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_trades.md).
They are exact under that model, rather than a guarantee about
undocumented Bedrock internals.

## References

[Microsoft, "Introduction to
Enchantments"](https://learn.microsoft.com/en-us/minecraft/creator/documents/introtoenchantments?view=minecraft-bedrock-stable)

[Minecraft Wiki, "Trading"](https://minecraft.wiki/w/Trading)

## Examples

``` r
enchanted_book_probability()
#> [1] 0.04619302
enchanted_book_probability('mending=1', max_emeralds = 26)
#> [1] 0.02791063
enchanted_book_probability(
  'efficiency=2',
  include_higher_level = TRUE
)
#> [1] 0.0370841
```
