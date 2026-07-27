# List enchantments

Lists the 42 enchantments registered in Minecraft Bedrock Edition
`1.26.30.5` and identifies those available through the bundled villager
model.

## Usage

``` r
enchantments()
```

## Value

A base data frame with one row per enchantment:

- `enchantment` (`character`) is the namespaced identifier.

- `display_name` (`character`) is the readable enchantment name.

- `max_level` (`integer`) is the highest valid level.

- `treasure` (`logical`) identifies treasure enchantments.

- `villager_attainable` (`logical`) indicates availability through the
  pinned librarian trade model.

- `traded_items` (`character`) lists directly traded enchanted
  equipment, separated by commas. It is `NA` when none applies.

## Details

The registry contains the 39 enchantments available from librarians plus
Soul Speed, Swift Sneak, and Wind Burst. The latter three remain visible
for validation and return `FALSE` in `villager_attainable`.

`traded_items` concerns equipment generated directly by armorer,
fisherman, fletcher, toolsmith, or weaponsmith trades. It does not list
items that can receive a librarian book later through an anvil.

Values are bundled and verified against Mojang's pinned enchantment
registry during package development. Calling the function performs no
download.

## References

[Microsoft, "`/enchant`
Command"](https://learn.microsoft.com/en-us/minecraft/creator/commands/commands/enchant?view=minecraft-bedrock-stable)

[Microsoft, "Introduction to
Enchantments"](https://learn.microsoft.com/en-us/minecraft/creator/documents/introtoenchantments?view=minecraft-bedrock-stable)

## Examples

``` r
registry <- enchantments()
head(registry)
#>                    enchantment       display_name max_level treasure
#> 1      minecraft:aqua_affinity      Aqua Affinity         1    FALSE
#> 2 minecraft:bane_of_arthropods Bane of Arthropods         5    FALSE
#> 3            minecraft:binding   Curse of Binding         1     TRUE
#> 4   minecraft:blast_protection   Blast Protection         4    FALSE
#> 5             minecraft:breach             Breach         4    FALSE
#> 6         minecraft:channeling         Channeling         1    FALSE
#>   villager_attainable
#> 1                TRUE
#> 2                TRUE
#> 3                TRUE
#> 4                TRUE
#> 5                TRUE
#> 6                TRUE
#>                                                                                                  traded_items
#> 1                                                                                    minecraft:diamond_helmet
#> 2                    minecraft:diamond_axe, minecraft:diamond_sword, minecraft:iron_axe, minecraft:iron_sword
#> 3                                                                                                        <NA>
#> 4 minecraft:diamond_boots, minecraft:diamond_chestplate, minecraft:diamond_helmet, minecraft:diamond_leggings
#> 5                                                                                                        <NA>
#> 6                                                                                                        <NA>

registry[!registry$villager_attainable, ]
#>              enchantment display_name max_level treasure villager_attainable
#> 37  minecraft:soul_speed   Soul Speed         3     TRUE               FALSE
#> 38 minecraft:swift_sneak  Swift Sneak         3     TRUE               FALSE
#> 42  minecraft:wind_burst   Wind Burst         3     TRUE               FALSE
#>    traded_items
#> 37         <NA>
#> 38         <NA>
#> 42         <NA>
```
