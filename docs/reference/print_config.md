# Print Configuration Summary

Display a formatted summary of simulation configuration.

## Usage

``` r
print_config(config)
```

## Arguments

  - config:
    
    Configuration list from pj\_huffman\_2009() or create\_config()

## Examples

``` r
config <- pj_huffman_2009()
print_config(config)
#> 
#> ========================================================================
#> SIMULATION CONFIGURATION: Default
#> ========================================================================
#> TARGET METRICS:
#>   Density:        927 trees/ha
#>   Species:        75.5% PIED, 24.5% JUSO
#>   Mean DBH:       20.5 cm (SD = 8.5 cm)
#>   Canopy Cover:   40.0%
#>   CFL:            1.10 kg/m^2
#>   Spatial R:      1.00
#> 
#> OPTIMIZATION WEIGHTS (0-100 scale):
#>   Density:        70 (HIGH)
#>   Species:        70 (HIGH)
#>   Canopy Cover:   70 (HIGH)
#>   CFL:            60 (HIGH)
#>   Spatial R:      10 (emergent)
#> 
#> SIMULATION SETTINGS:
#>   Max Iterations: 50000
#>   Plot Size:      20.0 m
#>   Plotting:       ENABLED
#>   Mortality:      20.0%
#> ========================================================================
```
