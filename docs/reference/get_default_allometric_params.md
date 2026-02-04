# Get default allometric parameters for pinyon-juniper woodland

Returns a list of allometric parameters for common pinyon-juniper
species. Users can modify these parameters or create new parameter sets
for different forest
types.

## Usage

``` r
get_default_allometric_params(use_reese_cbh = TRUE, use_miller_foliage = TRUE)
```

## Arguments

  - use\_reese\_cbh:
    
    Logical. If TRUE, uses Reese's quadratic CBH equations (more
    realistic crown shapes). If FALSE, uses simple linear CBH = 0.4\*H.
    Default is TRUE.

  - use\_miller\_foliage:
    
    Logical. If TRUE, uses Miller et al. (1981) published foliage
    biomass equations. If FALSE, uses generic crown volume approach.
    Default is TRUE.

## Value

List containing species-specific parameters:

  - crown\_radius:
    
    Parameters for crown radius (m) = a + b \* DBH

  - height:
    
    Parameters for height (m) = 1.3 + a \* (1 - exp(-b \* DBH))

  - crown\_ratio:
    
    Parameters for crown ratio = a - b \* log(DBH)

  - crown\_mass:
    
    Parameters for crown mass (kg) = a \* DBH^b

  - cbh\_method:
    
    Method for crown base height calculation

  - cbh\_reese:
    
    Reese quadratic coefficients (if use\_reese\_cbh = TRUE)

  - foliage\_method:
    
    Method for foliage biomass calculation

  - foliage\_miller:
    
    Miller et al. coefficients (if use\_miller\_foliage = TRUE)

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
