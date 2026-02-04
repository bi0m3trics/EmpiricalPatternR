# Add Tree with Nurse Tree Effect

Adds a new tree to the stand. If adding a pinyon pine (PIED), places it
near an existing juniper to reflect nurse tree facilitation. Other
species are placed randomly.

## Usage

``` r
perturb_add_with_nurse(
  trees,
  plot_size,
  species_names,
  species_probs,
  dbh_mean,
  dbh_sd,
  nurse_distance = 3
)
```

## Arguments

- trees:

  Data.table. Current tree data

- plot_size:

  Numeric. Plot dimension in meters

- species_names:

  Character vector. Available species codes

- species_probs:

  Numeric vector. Target species proportions (must sum to 1)

- dbh_mean:

  Numeric. Mean DBH for new tree (cm)

- dbh_sd:

  Numeric. Standard deviation of DBH (cm)

- nurse_distance:

  Numeric. Target distance to place PIED near juniper (m). Actual
  distance is drawn from normal distribution with mean = nurse_distance
  and SD = 0.3 \* nurse_distance.

## Value

Data.table. Updated tree data with new tree added

## Details

New tree species is selected based on species_probs. If PIED is selected
and junipers exist, tree is placed at distance ~ N(nurse_distance,
0.3\*nurse_distance) from a randomly selected juniper. Position is
constrained within plot bounds. DBH is drawn from N(dbh_mean, dbh_sd)
and constrained to minimum 5cm.

## Examples

``` r
# \donttest{
trees <- data.table::data.table(Number = 1:10, x = runif(10, 0, 100), 
                    y = runif(10, 0, 100), 
                    Species = sample(c("PIED", "JUSO"), 10, replace = TRUE),
                    DBH = rnorm(10, 20, 5))
trees_new <- perturb_add_with_nurse(trees, 100, c("PIED", "JUSO"),
                                    c(0.7, 0.3), 20, 5, 2.5)
# }
```
