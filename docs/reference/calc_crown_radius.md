# Calculate crown radius from DBH and height using allometric equations

Calculates crown radius using Reese species-specific equations built
from measured pinyon-juniper crown data (n=5,119 trees).

## Usage

``` r
calc_crown_radius(
  dbh,
  height,
  species,
  allometric_params = get_default_allometric_params()
)
```

## Arguments

- dbh:

  Numeric vector. Tree diameter at breast height (cm)

- height:

  Numeric vector. Tree total height (m)

- species:

  Character vector. Species codes (e.g., "PIED", "JUMO", "JUOS")

- allometric_params:

  List. Allometric parameters from
  [`get_default_allometric_params()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/get_default_allometric_params.md)
  or custom parameters

## Value

Numeric vector. Crown radius (m), minimum 0.3m

## Details

\*\*Model:\*\* ln(CD) = a + b\*ln(DBH) + c\*ln(H)

Where CD = crown diameter (m), DBH = diameter (cm), H = height (m).
Crown radius returned as CD/2.

## References

Reese et al. Crown diameter equations for pinyon-juniper species. Built
from n=1,658 PIED, n=2,520 JUMO, n=941 JUOS trees.

## Examples

``` r
# Single tree - now requires height!
dbh <- 20
height <- calc_height(dbh, "PIED")
calc_crown_radius(dbh, height, "PIED")
#> [1] 1.889725

# Multiple trees
dbh <- c(10, 20, 30)
species <- c("PIED", "JUMO", "JUOS")
height <- calc_height(dbh, species)
calc_crown_radius(dbh, height, species)
#> [1] 1.401265 2.755308 2.467473
```
