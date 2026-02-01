# Calculate canopy fuel mass from DBH

Calculates total foliage and fine twig mass. Two methods available:

## Usage

``` r
calc_canopy_fuel_mass(
  dbh,
  species,
  allometric_params = get_default_allometric_params()
)
```

## Arguments

- dbh:

  Numeric vector. Tree diameter at breast height (cm)

- species:

  Character vector. Species codes

- allometric_params:

  List. Allometric parameters (from get_default_allometric_params)

## Value

Numeric vector. Canopy fuel mass (kg, ovendry weight)

## Details

\*\*Miller (1981) method\*\* (default, published equations):
ln(W_foliage) = a + b \* ln(DBH) Based on destructive sampling of
pinyon-juniper trees.

\*\*Crown volume method\*\* (generic): mass (kg) = a \* DBH^b

Method is determined by allometric_params\$foliage_method.

## References

Miller, Meeuwig & Budy (1981). USDA Forest Service INT-273. Biomass of
Singleleaf Pinyon and Utah Juniper.

## Examples

``` r
# Using Miller (1981) equations (default)
calc_canopy_fuel_mass(20, "PIED")
#> [1] 88.97332

# Multiple trees
calc_canopy_fuel_mass(c(10, 20, 30), c("PIED", "JUSO", "JUMO"))
#> [1]  21.78557  63.88874 134.77468

# Using generic crown volume method
params <- get_default_allometric_params(use_miller_foliage = FALSE)
calc_canopy_fuel_mass(20, "PIED", params)
#> [1] 109.2339
```
