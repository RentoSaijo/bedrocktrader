# Retrieve Villager Trades

Retrieves the official vanilla trade table for one supported profession
and converts its nested structure into a flat base data frame.

## Usage

``` r
villager_trades(profession = "armorer", version = "latest")
```

## Arguments

- profession:

  One canonical profession identifier or an alias listed by
  [`villager_professions()`](https://rentosaijo.github.io/bedrocktrader/reference/villager_professions.md).
  The default is `"armorer"`.

- version:

  `"latest"` or an explicit stable Minecraft Bedrock sample version
  returned by
  [`bedrock_versions()`](https://rentosaijo.github.io/bedrocktrader/reference/bedrock_versions.md).
  `"latest"` is resolved when the function is called.

## Value

A base data frame with one row per concrete combination of item choices
and 40 atomic columns.

## How to read a row

A Bedrock profession table contains five villager levels. Each level
contains one or more selection groups, each group contains candidate
trades, and a candidate may contain alternative items.
`villager_trades()` expands the cross-product of those item
alternatives. Consequently, rows sharing a `candidate_id` represent
alternative item realizations of one candidate; `option_id` identifies
the individual expanded row.

The result describes every possible offer in the profession table. It
does not represent the offers selected for a particular villager,
calculate offer probabilities, evaluate contextual filters, or generate
dynamic function outcomes.

## Trade columns

- `profession` (`character`): canonical profession identifier.

- `level` (`integer`): numeric villager tier from 1 through 5.

- `level_name` (`character`): `novice`, `apprentice`, `journeyman`,
  `expert`, or `master`.

- `total_exp_required` (`double`): cumulative experience the villager,
  rather than the player, needs to unlock the level.

- `group_id` (`character`): package-generated identifier for a selection
  group, formatted from profession, level, and group position.

- `candidate_id` (`character`): package-generated identifier for one
  source trade within a group. It can repeat after item choices are
  expanded.

- `option_id` (`character`): unique identifier for one expanded output
  row.

- `candidate_count` (`integer`): number of source trade candidates in
  the group before item-choice expansion.

- `num_to_select` (`integer`): number of candidates Mojang selects from
  the group. `-1` represents the select-all convention.

- `select_all` (`logical`): convenient indicator for
  `num_to_select == -1`.

- `max_uses` (`double`): number of uses before the offer locks until the
  villager restocks.

- `trader_exp` (`double`): experience the villager gains when the trade
  is completed.

- `reward_exp` (`logical`): whether completing the trade rewards the
  player with experience.

The three item-slot prefixes describe the exchange from the player's
perspective:

- `wants_1_` is the first item the player pays.

- `wants_2_` is an optional second item the player pays. All nine fields
  are typed `NA` when a trade has only one input.

- `gives_1_` is the item the villager gives the player.

## Item-slot columns

Each prefix is combined with the following nine fields:

- `item_raw` (`character`): exact Mojang item identifier, including a
  numeric auxiliary suffix when one is present.

- `item` (`character`): normalized item identifier without that suffix.

- `aux_value` (`integer`): numeric auxiliary or legacy data value
  removed from `item_raw`; `NA` when no suffix exists.

- `quantity_min` and `quantity_max` (`double`): lower and upper bounds
  of the quantity. They are equal for a fixed quantity. An omitted
  source quantity becomes one.

- `price_multiplier` (`double`): Mojang's multiplier for price increases
  caused by supply and demand.

- `functions` (`character`): item-generation function names in source
  order, separated by commas.

- `function_parameters` (`character`): a JSON array whose objects align
  with the names in `functions`.

- `filters` (`character`): unevaluated filter JSON. A top-level
  `position` or `choice` key records where the filter appeared in
  Mojang's item structure.

Optional properties remain `NA` when Mojang omits them; the package does
not replace them with Minecraft's runtime defaults. Functions, function
parameters, and filters are also `NA` when absent. The generated IDs are
deterministic for a release's source order, but their meaning should be
compared by content before matching different releases.

## References

[Microsoft, "Creating a Trade
Table"](https://learn.microsoft.com/en-us/minecraft/creator/documents/createtradetable?view=minecraft-bedrock-stable)

## Examples

``` r
if (FALSE) { # \dontrun{
armorer <- villager_trades()
armorer[
  ,
  c(
    'level_name',
    'wants_1_item',
    'wants_1_quantity_min',
    'gives_1_item'
  )
]

cartographer <- villager_trades(
  profession = 'cartographer',
  version    = '1.26.30.5'
)
two_inputs <- !is.na(cartographer$wants_2_item)
cartographer[
  two_inputs,
  c('wants_1_item', 'wants_2_item', 'gives_1_item')
]

function_row <- which(!is.na(cartographer$gives_1_functions))[[1L]]
jsonlite::fromJSON(
  cartographer$gives_1_function_parameters[[function_row]]
)

mason <- villager_trades('mason', version = '1.26.30.5')
mason[
  mason$select_all,
  c('group_id', 'candidate_id', 'option_id', 'num_to_select')
]
} # }
```
