# Get default allometric parameters for pinyon-juniper woodland

Returns a list of allometric parameters for common pinyon-juniper
species. Users can modify these parameters or create new parameter sets
for different forest types.

## Usage

``` r
get_default_allometric_params(use_reese_cbh = TRUE, use_miller_foliage = TRUE)
```

## Arguments

- use_reese_cbh:

  Logical. If TRUE, uses Reese's quadratic CBH equations (more realistic
  crown shapes). If FALSE, uses simple linear CBH = 0.4\*H. Default is
  TRUE.

- use_miller_foliage:

  Logical. If TRUE, uses Miller et al. (1981) published foliage biomass
  equations. If FALSE, uses generic crown volume approach. Default is
  TRUE.

## Value

List containing species-specific parameters:

- crown_radius:

  Parameters for crown radius (m) = a + b \* DBH

- height:

  Parameters for height (m) = 1.3 + a \* (1 - exp(-b \* DBH))

- crown_ratio:

  Parameters for crown ratio = a - b \* log(DBH)

- crown_mass:

  Parameters for crown mass (kg) = a \* DBH^b

- cbh_method:

  Method for crown base height calculation

- cbh_reese:

  Reese quadratic coefficients (if use_reese_cbh = TRUE)

- foliage_method:

  Method for foliage biomass calculation

- foliage_miller:

  Miller et al. coefficients (if use_miller_foliage = TRUE)

## References

Reese et al. Crown base height equations for pinyon-juniper species.
Miller, Meeuwig & Budy (1981). USDA Forest Service INT-273.

## Examples

``` r
# Get default parameters with improved equations
params <- get_default_allometric_params()

# Use simple equations instead
params_simple <- get_default_allometric_params(
  use_reese_cbh = FALSE,
  use_miller_foliage = FALSE
)

# Modify for your own species
custom_params <- params
custom_params$crown_radius$PIPO <- list(a = 0.5, b = 0.10)
```
