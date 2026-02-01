# Calculate Size-Dependent Mortality Probability

Calculates mortality probability for each tree based on size (DBH) using
negative exponential relationships. Smaller trees have higher mortality.

## Usage

``` r
calc_mortality_probability(trees, mort_params = NULL)
```

## Arguments

- trees:

  Data.table with columns: DBH (cm), Species

- mort_params:

  List. Species-specific mortality parameters with structure:
  list(SPECIES = list(base = ..., size_effect = ..., dbh_coef = ...))
  Default parameters favor mortality of small trees: - PIED: base=0.05,
  size_effect=0.45, dbh_coef=0.08 - JUMO: base=0.04, size_effect=0.40,
  dbh_coef=0.07 - JUSO: base=0.04, size_effect=0.40, dbh_coef=0.07

## Value

Numeric vector. Mortality probability for each tree (0-1)

## Details

Mortality probability calculated as: P(mortality) = base + size_effect
\* exp(-dbh_coef \* DBH)

This creates decreasing mortality with increasing DBH: - Small trees
(DBH \< 10cm): High probability (0.3-0.5) - Medium trees (DBH 10-30cm):
Moderate probability (0.1-0.3) - Large trees (DBH \> 30cm): Low
probability (0.05-0.15)

Probabilities are constrained to \[0, 1\].

## Examples

``` r
# \donttest{
trees <- data.frame(DBH = c(5, 15, 25, 35), 
                    Species = c("PIED", "PIED", "JUSO", "JUSO"))
calc_mortality_probability(trees)
#> [1] 0.35164402 0.18553740 0.10950958 0.07451743
# }
```
