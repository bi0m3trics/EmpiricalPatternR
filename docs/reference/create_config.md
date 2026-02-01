# Create Custom Simulation Configuration

Build a custom simulation configuration with full control over all
parameters. This is a template function showing all available options.

## Usage

``` r
create_config(
  name = "Custom",
  targets = NULL,
  weights = NULL,
  simulation = NULL,
  allometric_params = NULL
)
```

## Arguments

  - name:
    
    Configuration name for reference

  - targets:
    
    List of target stand metrics

  - weights:
    
    List of optimization weights

  - simulation:
    
    List of simulation control parameters

  - allometric\_params:
    
    Allometric equation parameters

## Value

Configuration list

## Examples

``` r
# Create custom high-density pinyon woodland
my_config <- create_config(
  name = "High Density PJ",
  targets = list(
    density_ha = 1500,
    species_props = c(PIED = 0.90, JUSO = 0.10),
    species_names = c("PIED", "JUSO"),
    mean_dbh = 15.0,
    sd_dbh = 6.0,
    canopy_cover = 0.60,
    cfl = 1.5,
    clark_evans_r = 0.8
  )
)
```
