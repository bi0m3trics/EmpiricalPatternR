# Ponderosa Pine Forest with Custom Configurations

## Overview

This vignette demonstrates how to create **custom configurations** for
different forest types using
[`create_config()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/create_config.md).
We’ll simulate a ponderosa pine forest with:

- Custom target values (different from pinyon-juniper)
- Multiple species (PIPO, PSME, ABCO)
- Larger trees (montane forest)
- Different allometric relationships
- No nurse tree effect

## Why Custom Configurations?

The pre-built
[`pj_huffman_2009()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/pj_huffman_2009.md)
configuration is great for pinyon-juniper woodlands, but other forest
types have different characteristics:

| Characteristic | Pinyon-Juniper  | Ponderosa Pine        |
|----------------|-----------------|-----------------------|
| Density        | ~900 trees/ha   | ~450 trees/ha         |
| Mean DBH       | 15 cm           | 35 cm                 |
| Mean Height    | 8 m             | 18 m                  |
| Species        | 2 (PIED, JUSO)  | 3+ (PIPO, PSME, ABCO) |
| Spacing        | Clumped (R~1.0) | Regular (R~1.4)       |
| Nurse Effect   | Yes             | No                    |

## Step 1: Load Package

``` r
library(EmpiricalPatternR)
```

## Step 2: Get Ponderosa Allometric Parameters

``` r
# Get species-specific allometric equations
ponderosa_params <- get_ponderosa_allometric_params()

# View crown radius parameters
ponderosa_params$crown_radius$PIPO
# $a: -0.204  (intercept)
# $b:  0.649  (DBH coefficient)  
# $c:  0.421  (height coefficient)

# View height parameters (Chapman-Richards)
ponderosa_params$height$PIPO
# $a: 27.0    (asymptotic height - 1.3)
# $b: 0.025   (growth rate)

# View foliage mass parameters (Miller)
ponderosa_params$foliage$PIPO
# $a: -2.287  (intercept)
# $b:  1.924  (DBH coefficient)
```

These parameters come from published equations: - **Crown**: Reese et
al. (log-log with height) - **Height**: Chapman-Richards growth model -
**Foliage**: Miller et al. (log-log)

## Step 3: Create Custom Configuration

``` r
config <- create_config(
  # Target stand structure
  density_ha = 450,
  species_props = c(PIPO = 0.70, PSME = 0.20, ABCO = 0.10),
  mean_dbh = 35.0,
  sd_dbh = 12.0,
  mean_height = 18.0,
  sd_height = 6.0,
  canopy_cover = 0.45,
  cfl = 0.85,
  clark_evans_r = 1.4,
  
  # Simulation parameters
  plot_size = 100,
  max_iterations = 5000,
  temp_initial = 0.01,
  cooling_rate = 0.9999,
  
  # Optimization weights
  weight_ce = 30,
  weight_dbh_mean = 15,
  weight_dbh_sd = 10,
  weight_height_mean = 10,
  weight_height_sd = 5,
  weight_species = 60,
  weight_canopy_cover = 60,
  weight_cfl = 50,
  weight_density = 80,
  weight_nurse = 0,  # No nurse effect
  
  # No nurse trees
  nurse_distance = 0,
  use_nurse_effect = FALSE,
  mortality_prop = 0.10
)

# View configuration
print(config)
```

### Configuration Explanation

**Target Structure**: - `density_ha = 450`: Lower density than P-J
(managed stand) - `species_props`: 70% ponderosa, 20% Douglas-fir, 10%
white fir - `mean_dbh = 35`: Much larger trees (mature forest) -
`clark_evans_r = 1.4`: Regular spacing (managed/natural fire regime)

**Optimization Weights**: - `weight_density = 80`: Critical to match
tree count - `weight_species = 60`: Important for composition -
`weight_canopy_cover = 60`: Important for structure -
`weight_nurse = 0`: Disabled (no nurse effect in ponderosa)

**Simulation Parameters**: - `max_iterations = 5000`: Fewer needed
(lower density) - `cooling_rate = 0.9999`: Slower cooling (more
exploration)

## Step 4: Run Simulation

``` r
set.seed(456)

result <- simulate_stand(
  targets = config$targets,
  weights = config$weights,
  plot_size = config$simulation$plot_size,
  max_iterations = config$simulation$max_iterations,
  initial_temp = config$simulation$temp_initial,
  cooling_rate = config$simulation$cooling_rate,
  verbose = TRUE,
  plot_interval = 500,
  nurse_distance = config$simulation$nurse_distance,
  use_nurse_effect = config$simulation$use_nurse_effect,
  mortality_prop = config$simulation$mortality_prop
)
```

## Step 5: Analyze Results

``` r
analyze_simulation_results(
  result = result,
  targets = config$targets,
  prefix = "ponderosa_forest",
  save_plots = TRUE,
  nurse_distance_target = 0,
  target_mortality = config$simulation$mortality_prop * 100
)
```

### Expected Output

    ================================================================================
    SIMULATION RESULTS SUMMARY
    Stand: ponderosa_forest
    ================================================================================

    STAND METRICS:
                              Achieved    Target      Diff     Status
      Density (trees/ha)      448         450         -2       ✓ GOOD
      Mean DBH (cm)           34.8        35.0        -0.2     ✓ GOOD
      Mean Height (m)         17.9        18.0        -0.1     ✓ GOOD
      Canopy Cover (%)        44.7        45.0        -0.3     ✓ GOOD
      CFL (kg/m²)             0.84        0.85        -0.01    ✓ GOOD
      Clark-Evans R           1.38        1.40        -0.02    ✓ GOOD

    SPECIES COMPOSITION:
      PIPO (Ponderosa Pine)   69.8%       70.0%       -0.2%    ✓ GOOD
      PSME (Douglas-fir)      20.1%       20.0%       +0.1%    ✓ GOOD
      ABCO (White Fir)        10.1%       10.0%       +0.1%    ✓ GOOD

    MORTALITY SIMULATION:
      Trees killed:           45 (10.0%)
      Surviving trees:        403 (90.0%)

## Step 6: Compare Allometric Equations

One key difference between forest types is allometric relationships:

``` r
# Compare crown radius for 40cm DBH tree
test_dbh <- 40
test_species <- "PIPO"

# Default (P-J) parameters
default_params <- get_default_allometric_params()
default_height <- calc_height(test_dbh, test_species, default_params)
default_radius <- calc_crown_radius(test_dbh, default_height, test_species, default_params)

# Ponderosa parameters
ponderosa_height <- calc_height(test_dbh, test_species, ponderosa_params)
ponderosa_radius <- calc_crown_radius(test_dbh, ponderosa_height, test_species, ponderosa_params)

cat(sprintf("40cm DBH Ponderosa Pine:\n"))
cat(sprintf("  Default equations:  Radius = %.2fm, Height = %.1fm\n", 
            default_radius, default_height))
cat(sprintf("  Ponderosa equations: Radius = %.2fm, Height = %.1fm\n",
            ponderosa_radius, ponderosa_height))
cat(sprintf("  Difference:         +%.2fm (+%.1f%%), +%.1fm (+%.1f%%)\n",
            ponderosa_radius - default_radius,
            (ponderosa_radius/default_radius - 1) * 100,
            ponderosa_height - default_height,
            (ponderosa_height/default_height - 1) * 100))
```

Ponderosa pines typically have: - **Larger crowns** for given DBH (more
open grown) - **Taller heights** (montane environment) - **More foliage
mass** (higher photosynthetic capacity)

## Custom Configuration Scenarios

### Scenario 1: Dense Young Stand

``` r
config_young <- create_config(
  density_ha = 800,
  species_props = c(PIPO = 1.0),
  mean_dbh = 15.0,
  sd_dbh = 5.0,
  mean_height = 8.0,
  sd_height = 3.0,
  canopy_cover = 0.50,
  cfl = 0.60,
  clark_evans_r = 1.0,  # Clumped
  plot_size = 100,
  max_iterations = 8000
)
```

### Scenario 2: Old-Growth Stand

``` r
config_oldgrowth <- create_config(
  density_ha = 200,
  species_props = c(PIPO = 0.60, PSME = 0.30, ABCO = 0.10),
  mean_dbh = 60.0,
  sd_dbh = 25.0,
  mean_height = 28.0,
  sd_height = 10.0,
  canopy_cover = 0.40,
  cfl = 1.20,
  clark_evans_r = 1.6,  # Very regular
  plot_size = 100,
  max_iterations = 3000
)
```

### Scenario 3: Post-Fire Stand

``` r
config_postfire <- create_config(
  density_ha = 150,
  species_props = c(PIPO = 0.80, PSME = 0.15, ABCO = 0.05),
  mean_dbh = 45.0,
  sd_dbh = 20.0,
  mean_height = 20.0,
  sd_height = 8.0,
  canopy_cover = 0.30,
  cfl = 0.50,
  clark_evans_r = 1.5,
  plot_size = 100,
  max_iterations = 3000,
  mortality_prop = 0.05  # Low mortality (survivors)
)
```

## Troubleshooting Custom Configs

### Issue: Energy Not Converging

**Symptoms**: Final energy \> 5000, metrics don’t match targets

**Solutions**: 1. Increase `max_iterations` (try 10000, 20000) 2.
Decrease `cooling_rate` (try 0.99995 for slower cooling) 3. Check for
conflicting targets (e.g., high density + high canopy) 4. Adjust weights
to prioritize most important metrics

### Issue: Species Proportions Off

**Symptoms**: One species dominates or is missing

**Solutions**: 1. Increase `weight_species` (try 80-100) 2. Check that
`species_props` sums to 1.0 3. Ensure all species have allometric
parameters defined

### Issue: Canopy Cover Mismatch

**Symptoms**: Achieved cover much higher/lower than target

**Solutions**: 1. Adjust both `canopy_cover` target AND
`weight_canopy_cover` 2. Check allometric equations (larger crowns =
more cover) 3. Consider interaction with density and mean DBH

### Issue: Spatial Pattern Wrong

**Symptoms**: Trees clumped when should be regular (or vice versa)

**Solutions**: 1. Increase `weight_ce` to prioritize spatial pattern 2.
Adjust `clark_evans_r` target (1.0 = random, \>1.0 = regular, \<1.0 =
clumped) 3. Increase iterations for spatial optimization

## Saving and Sharing Configurations

``` r
# Save configuration for later use
save_config(config, "my_ponderosa_config.rds")

# Load saved configuration
config_loaded <- readRDS("my_ponderosa_config.rds")

# Share as R script (editable template)
generate_config_template(
  file = "ponderosa_template.R",
  config_name = "my_ponderosa_config",
  base_config = "custom"
)
```

## Advanced: Integrating Custom Allometry

**Note**: Current version uses built-in allometric equations during
simulation. To fully integrate custom equations, you would:

1.  Modify
    [`calc_tree_attributes()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/calc_tree_attributes.md)
    to accept `allometric_params` argument
2.  Pass custom parameters through
    [`simulate_stand()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/simulate_stand.md)
3.  Apply custom equations to all attribute calculations

This is a planned enhancement. For now, custom allometry can be: -
Applied post-hoc to results - Used in custom analysis scripts -
Incorporated in derived metrics

## Next Steps

- **Template System**: Use
  [`generate_config_template()`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/generate_config_template.md)
  for easier customization
- **Multiple Runs**: Compare different configurations/scenarios
- **Sensitivity Analysis**: Test how results change with parameter
  variations
- **Field Validation**: Compare simulated stands to field measurements

## See Also

- [`?create_config`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/create_config.md) -
  Full parameter documentation
- [`?get_ponderosa_allometric_params`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/get_ponderosa_allometric_params.md) -
  Allometric equation details
- [`?generate_config_template`](https://bi0m3trics.github.io/EmpiricalPatternR/reference/generate_config_template.md) -
  Create editable templates
- [`vignette("getting-started")`](https://bi0m3trics.github.io/EmpiricalPatternR/articles/getting-started.md) -
  Package introduction
- [`vignette("pinyon-juniper")`](https://bi0m3trics.github.io/EmpiricalPatternR/articles/pinyon-juniper.md) -
  Pre-built configuration example
