# Generate Template Configuration File

Creates an R script template with a custom simulation configuration that
users can edit. The template includes all required parameters with
descriptions and example values. This is useful for creating custom
simulations.

## Usage

``` r
generate_config_template(
  file = "my_simulation_config.R",
  config_name = "my_custom_config",
  base_config = c("pj", "custom")
)
```

## Arguments

  - file:
    
    Character, path to save the template file (default:
    "my\_simulation\_config.R")

  - config\_name:
    
    Character, name for the config function (default:
    "my\_custom\_config")

  - base\_config:
    
    Character, which config to use as starting point: "pj" for
    pinyon-juniper (default), or "custom" for blank template

## Value

Invisibly returns the file path

## Examples

``` r
# \donttest{
# Generate a template based on P-J config
generate_config_template("my_pj_config.R", "my_pj_simulation")
#> Template created: my_pj_config.R
#> Edit the file, then: source("my_pj_config.R"); config <- my_pj_simulation()

# Generate a blank custom template
generate_config_template("custom_sim.R", "custom_simulation", base_config = "custom")
#> Template created: custom_sim.R
#> Edit the file, then: source("custom_sim.R"); config <- custom_simulation()
# }
```
