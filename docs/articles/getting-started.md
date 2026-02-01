# Getting Started with EmpericalPatternR

## Introduction

**EmpericalPatternR** simulates realistic forest stand patterns using
simulated annealing optimization to match empirical targets for:

  - Spatial patterns (Clark-Evans R)
  - Species composition
  - Tree size distributions (DBH and height)
  - Canopy structure (cover and fuel load)
  - Fire behavior metrics

This vignette shows you how to run your first simulation in just a few
lines of code.

## Quick Start

### Installation

``` r
# Install from GitHub (if not already installed)
# devtools::install_github("bi0m3trics/EmpericalPatternR")
library(EmpericalPatternR)
```

``` r
library(EmpericalPatternR)
```

### Your First Simulation

The easiest way to run a simulation is using a pre-built configuration:

``` r
# Load a pre-configured pinyon-juniper woodland
config <- pj_huffman_2009()

# Run simulation (reduced iterations for demo)
result <- simulate_stand(
  targets = config$targets,
  weights = config$weights,
  plot_size = 100,
  max_iterations = 1000,
  verbose = TRUE
)
```

That’s it\! The simulation creates a 1-hectare stand with realistic tree
positions, species, and sizes.

## Understanding the Configuration

Let’s examine what the configuration contains:

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

### Target Parameters

These define the forest characteristics you want to simulate:

  - **Density**: 927 trees/ha (total stand density)
  - **Species**: 75.5% Pinyon pine (PIED), 24.5% Utah juniper (JUSO)
  - **Size**: Mean DBH = 20.5 cm, Mean height = 6.5 m
  - **Canopy**: 40% cover, 1.10 kg/m² fuel load
  - **Pattern**: Clark-Evans R = 1.0 (random spatial distribution)

### Optimization Weights

Weights (0-100) control how hard the algorithm tries to match each
target:

  - **0-20**: Low priority (let it emerge naturally)
  - **20-50**: Moderate priority
  - **50-80**: High priority (actively optimize)
  - **80-100**: Critical priority (dominates optimization)

In the default config: - Species, density, canopy cover, and CFL are all
HIGH (60-70) - Tree size metrics are LOW (1-5) - they emerge from
allometry - Spatial pattern is LOW (10) - emerges from density/size

## Examining Results

### Basic Results

``` r
# View live trees
live_trees <- result$trees[result$trees$Status == "live", ]
head(live_trees)

# Calculate stand metrics
metrics <- calc_stand_metrics(live_trees, plot_size = 100)
print(metrics)
```

### Comprehensive Analysis

Use `analyze_simulation_results()` for detailed output:

``` r
analyze_simulation_results(
  result = result,
  targets = config$targets,
  prefix = "my_simulation",
  save_plots = TRUE
)
```

This generates: - Console summary comparing simulated vs. target values
- CSV files (all trees, live trees, history, summary stats) - PDF plots
(spatial patterns, diameter distributions)

### Simple Plots

``` r
# Tree map colored by species
plot(result$trees$x, result$trees$y,
     col = as.factor(result$trees$Species),
     pch = 19, cex = result$trees$DBH/10,
     main = "Simulated Stand",
     xlab = "X (m)", ylab = "Y (m)")
legend("topright", 
       legend = levels(as.factor(result$trees$Species)),
       col = 1:length(unique(result$trees$Species)),
       pch = 19)

# Convergence history
plot(result$history$iteration, result$history$energy,
     type = "l", log = "y",
     main = "Optimization Convergence",
     xlab = "Iteration", ylab = "Energy (log scale)")
```

## Creating Custom Configurations

### Method 1: Generate a Template

The easiest way to create a custom configuration:

``` r
# Generate an editable template
generate_config_template(
  file = "my_config.R",
  config_name = "my_custom_sim",
  base_config = "pj"  # or "custom" for blank
)

# Edit the file, then:
source("my_config.R")
my_config <- my_custom_sim(
  density_ha = 1200,
  cfl = 1.5,
  canopy_cover = 0.5
)
```

### Method 2: Use create\_config()

``` r
my_config <- create_config(
  name = "High Density Stand",
  targets = list(
    density_ha = 1500,
    species_props = c(PIED = 0.9, JUSO = 0.1),
    species_names = c("PIED", "JUSO"),
    mean_dbh = 15,
    sd_dbh = 6,
    mean_height = 5,
    sd_height = 2,
    canopy_cover = 0.6,
    cfl = 1.5,
    clark_evans_r = 0.8
  ),
  weights = list(
    density = 80,      # Very high priority
    species = 70,
    canopy_cover = 70,
    cfl = 60
  )
)
```

## Key Functions Reference

| Function                       | Purpose                              |
| ------------------------------ | ------------------------------------ |
| `pj_huffman_2009()`            | Pre-built P-J woodland config        |
| `simulate_stand()`             | Run the simulation                   |
| `calc_stand_metrics()`         | Calculate stand-level metrics        |
| `analyze_simulation_results()` | Comprehensive analysis & output      |
| `generate_config_template()`   | Create editable config template      |
| `create_config()`              | Build custom config programmatically |

## Next Steps

  - See `vignette("pinyon-juniper")` for a detailed P-J woodland example
  - See `vignette("ponderosa-pine")` for custom allometric equations
  - See `?simulate_stand` for all simulation parameters
  - See `?analyze_simulation_results` for analysis options

## Tips for Success

1.  **Start with fewer iterations** (1000-5000) to test, then increase
    to 50000 for final runs
2.  **Use high weights** (60-80) for metrics you measured in the field
3.  **Use low weights** (0-20) for emergent properties (spatial pattern,
    tree sizes)
4.  **Enable plotting** (`plot_interval = 500`) to watch optimization
    progress
5.  **Save your configs** with `save_config()` for reproducibility
