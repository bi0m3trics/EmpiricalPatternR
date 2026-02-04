# Export Configuration to File

Save configuration as R script for reproducibility.

## Usage

``` r
save_config(config, file = "simulation_config.R")
```

## Arguments

  - config:
    
    Configuration list

  - file:
    
    Output file path (default: "simulation\_config.R")

## Examples

``` r
config <- pj_huffman_2009(density_ha = 1000)
save_config(config, "my_simulation.R")
#> Configuration saved to: my_simulation.R
```
