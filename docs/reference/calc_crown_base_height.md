# Calculate crown base height from DBH and total height

Calculates the height at which the live crown begins. Two methods
available:

## Usage

``` r
calc_crown_base_height(
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

  Numeric vector. Total tree height (m)

- species:

  Character vector. Species codes

- allometric_params:

  List. Allometric parameters (from get_default_allometric_params)

## Value

Numeric vector. Crown base height (m)

## Details

\*\*Reese quadratic method\*\* (default, more realistic): CBH = b0 +
b1\*H + b2\*D + b3\*H^2 + b4\*D^2 + b5\*(H\*D)

\*\*Simple ratio method\*\*: crown_ratio = a - b \* log(DBH)
crown_base_height = height \* (1 - crown_ratio)

Method is determined by allometric_params\$cbh_method.

## References

Reese et al. Species-specific crown base height equations for
pinyon-juniper woodlands (PIED, JUMO, JUOS).

## Examples

``` r
dbh <- c(10, 20, 30)
height <- calc_height(dbh, c("PIED", "PIED", "PIED"))

# Using Reese quadratic equations (default)
calc_crown_base_height(dbh, height, c("PIED", "PIED", "PIED"))
#> [1] 1.300000 1.300000 1.388753

# Using simple ratio method
params <- get_default_allometric_params(use_reese_cbh = FALSE)
calc_crown_base_height(dbh, height, c("PIED", "PIED", "PIED"), params)
#> [1] 2.582661 4.375771 5.666247
```
