# Pinyon-Juniper Woodland Simulation

## Overview

This vignette demonstrates a complete workflow for simulating
pinyon-juniper woodland structure using the pre-built
[`pj_huffman_2009()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/pj_huffman_2009.md)
configuration based on published field data. We’ll cover:

- Using pre-built configurations
- Understanding nurse tree effects (pinyons near junipers)
- Simulating mortality events
- Comprehensive results analysis

## Background

Pinyon-juniper woodlands are widespread throughout the southwestern
United States. This example uses target values from **Huffman et
al. (2009)** control treatment plots, representing typical woodland
structure with:

- Moderate tree density (~900 trees/ha)
- Two-species composition (Pinus edulis and Juniperus osteosperma)
- Nurse tree associations (juvenile pinyons establish near junipers)
- Moderate canopy cover and fuel loads

## Step 1: Load Package and Configuration

``` r
library(EmpericalPatternR)

# Use pre-built configuration for pinyon-juniper
config <- pj_huffman_2009(
  density_ha = 927,
  cfl = 1.10,
  canopy_cover = 0.40,
  max_iterations = 10000
)

# Display configuration
print(config)
```

The configuration includes:

- **Targets**: Density, species composition, size distributions, canopy
  metrics
- **Weights**: How important each target is during optimization
- **Simulation**: Plot size, iterations, temperature schedule
- **Allometric**: Species-specific equations for crown, height, foliage

## Step 2: Understanding Key Parameters

### Species Composition

``` r
# Species proportions
config$targets$species_props
#   PIED   JUSO 
#   0.48   0.52
```

This represents 48% pinyon pine (PIED) and 52% Utah juniper (JUSO),
matching field observations.

### Nurse Tree Effect

``` r
config$simulation$use_nurse_effect  # TRUE
config$simulation$nurse_distance    # 3.0 meters
```

The nurse tree effect simulates the ecological pattern where pinyon
pines establish near junipers. The simulation tracks the proportion of
pinyons within 3 meters of a juniper, matching the target (32%).

### Optimization Weights

``` r
# Higher weights = more important during optimization
config$weights
# weight_density: 100  (very important)
# weight_species: 80   (important)
# weight_canopy_cover: 50
# weight_nurse: 40
# ... etc.
```

## Step 3: Run Simulation

``` r
set.seed(123)  # For reproducibility

result <- simulate_stand(
  targets = config$targets,
  weights = config$weights,
  plot_size = config$simulation$plot_size,
  max_iterations = config$simulation$max_iterations,
  initial_temp = config$simulation$temp_initial,
  cooling_rate = config$simulation$cooling_rate,
  verbose = TRUE,
  plot_interval = 1000,
  nurse_distance = config$simulation$nurse_distance,
  use_nurse_effect = config$simulation$use_nurse_effect,
  mortality_prop = config$simulation$mortality_prop
)
```

The simulation uses **simulated annealing** to optimize stand structure:

1.  Start with random trees
2.  Iteratively add, remove, move, or modify trees
3.  Accept changes that improve match to targets
4.  Gradually reduce acceptance of worse solutions (cooling)
5.  Converge to optimal structure

## Step 4: Analyze Results

The
[`analyze_simulation_results()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/analyze_simulation_results.md)
function provides comprehensive analysis:

``` r
analyze_simulation_results(
  result = result,
  targets = config$targets,
  prefix = "pj_woodland",
  save_plots = TRUE,
  nurse_distance_target = config$simulation$nurse_distance,
  target_mortality = config$simulation$mortality_prop * 100
)
```

This produces:

### Console Output

    ================================================================================
    SIMULATION RESULTS SUMMARY
    Stand: pj_woodland
    ================================================================================

    OPTIMIZATION PERFORMANCE:
      Final Energy:            1234.56
      Convergence:             Excellent (energy < 2000)

    STAND METRICS:
                              Achieved    Target      Diff     Status
      Density (trees/ha)      925         927         -2       ✓ GOOD
      Mean DBH (cm)           15.2        15.0        +0.2     ✓ GOOD
      Canopy Cover (%)        39.8        40.0        -0.2     ✓ GOOD
      CFL (kg/m²)             1.09        1.10        -0.01    ✓ GOOD
      Clark-Evans R           1.02        1.05        -0.03    ✓ GOOD

    SPECIES COMPOSITION:
      PIED (Pinyon Pine)      47.8%       48.0%       -0.2%    ✓ GOOD
      JUSO (Utah Juniper)     52.2%       52.0%       +0.2%    ✓ GOOD

    NURSE TREE ASSOCIATIONS:
      PIED within 3.0m of JUSO: 31.5%     32.0%       -0.5%    ✓ GOOD

    MORTALITY SIMULATION:
      Trees killed:           93 (10.0%)
      Surviving trees:        834 (90.0%)
      Post-mortality density: 834 trees/ha

### CSV Files

Four CSV files are saved:

1.  **`pj_woodland_all_trees.csv`**: All trees (live + dead)

    - Tree ID, species, DBH, height, x/y coordinates
    - Crown radius, CBH, foliage mass, CFL
    - Status (alive/dead), distance to nearest nurse

2.  **`pj_woodland_live_trees.csv`**: Live trees only

3.  **`pj_woodland_history.csv`**: Optimization convergence

    - Iteration, energy value, temperature
    - Track improvement over time

4.  **`pj_woodland_summary.csv`**: Summary statistics

    - All achieved vs. target metrics
    - Species composition
    - Size distributions

### PDF Plots

**`pj_woodland_plots.pdf`** contains 4 pages:

1.  **Spatial Distribution**: Tree locations colored by species
    - Shows spatial patterns and spacing
2.  **DBH Distribution**: Histogram comparing achieved vs. target
    - Demonstrates size structure match
3.  **Height Distribution**: Histogram comparing achieved vs. target
    - Shows vertical structure
4.  **Convergence**: Energy over iterations
    - Confirms optimization success

## Step 5: Accessing Individual Results

``` r
# Final tree list
head(result$trees)
#   tree_id species  dbh height      x      y crown_radius ...
#   1       PIED     12.3  8.5    15.2  42.1   2.1
#   2       JUSO     18.7  7.2    67.8  23.4   2.8
#   ...

# Species counts
table(result$trees$species, result$trees$status)
#       alive  dead
# PIED  420    45
# JUSO  459    48

# Optimization history
plot(result$history$iteration, result$history$energy, 
     type = "l", xlab = "Iteration", ylab = "Energy")
```

## Customization Examples

### Adjust Density

``` r
# Lower density (thinned stand)
config_thinned <- pj_huffman_2009(
  density_ha = 500,
  canopy_cover = 0.25,
  cfl = 0.60
)
```

### Increase Mortality

``` r
# Higher mortality (drought scenario)
config_drought <- pj_huffman_2009(
  density_ha = 927,
  mortality_prop = 0.30  # 30% mortality
)
```

### Faster Testing

``` r
# Quick test run
config_test <- pj_huffman_2009(
  density_ha = 927,
  max_iterations = 1000,
  plot_size = 50  # Smaller plot
)
```

## Interpretation Guide

### Good Convergence Indicators

- Final energy \< 2000
- Energy plot shows clear decline and plateau
- All metrics achieve “GOOD” status
- Species proportions within ±2% of targets
- Spatial R within ±0.10 of target

### Common Issues

**High Final Energy (\>5000)** - Solution: Increase max_iterations or
adjust conflicting targets

**Species Proportions Off** - Solution: Increase weight_species in
configuration

**Canopy Cover Mismatch** - Solution: Adjust both canopy_cover target
and weight_canopy_cover

**Nurse Effect Not Matching** - Solution: Check nurse_distance setting
and weight_nurse

## Next Steps

- **Custom Configurations**: See
  [`vignette("getting-started")`](https://bi0m3trics.github.io/EmpericalPatternR/articles/getting-started.md)
  for creating custom configs
- **Ponderosa Pine**: See
  [`vignette("ponderosa-pine")`](https://bi0m3trics.github.io/EmpericalPatternR/articles/ponderosa-pine.md)
  for different forest types
- **Advanced Analysis**: Write custom R scripts to analyze output CSVs
- **Publication**: Use results for fire behavior modeling, restoration
  planning, etc.

## References

Huffman, D.W., Stoddard, M.T., Springer, J.D., Crouse, J.E., Chancellor,
W.W., 2013. Stand dynamics and fuel loadings in an old-growth
piñon-juniper woodland in northern Arizona. Canadian Journal of Forest
Research 43, 605-619.

## See Also

- [`?pj_huffman_2009`](https://bi0m3trics.github.io/EmpericalPatternR/reference/pj_huffman_2009.md) -
  Configuration details
- [`?simulate_stand`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_stand.md) -
  Simulation parameters
- [`?analyze_simulation_results`](https://bi0m3trics.github.io/EmpericalPatternR/reference/analyze_simulation_results.md) -
  Analysis options
- [`?get_default_allometric_params`](https://bi0m3trics.github.io/EmpericalPatternR/reference/get_default_allometric_params.md) -
  Allometric equations
