# Calculate Nurse Tree Association Energy

Calculates deviation from target nurse tree associations. In
pinyon-juniper ecosystems, pinyon pines (PIED) often establish near
junipers (JUMO/JUSO) which act as "nurse trees" providing shade and
protection. This function quantifies how well the current tree pattern
matches this association.

## Usage

``` r
calc_nurse_tree_energy(trees, nurse_distance = 3)
```

## Arguments

- trees:

  Data.table with columns: x, y, Species

- nurse_distance:

  Numeric. Target mean distance from PIED to nearest juniper (m).
  Default 3.0m based on field observations.

## Value

Numeric. Energy value representing squared deviation from target
distance. Lower values indicate better match to target association
pattern.

## Details

For each PIED tree, calculates distance to nearest JUMO or JUSO tree.
Returns squared deviation of mean distance from target. Returns 0 if
either species is absent.

## Examples

``` r
# \donttest{
trees <- data.table::data.table(x = runif(100, 0, 100), y = runif(100, 0, 100),
                    Species = sample(c("PIED", "JUSO"), 100, replace = TRUE))
calc_nurse_tree_energy(trees, nurse_distance = 3.0)
#> [1] 24.43518
# }
```
