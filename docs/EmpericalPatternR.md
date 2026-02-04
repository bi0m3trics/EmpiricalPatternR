# EmpericalPatternR: Complete Technical Documentation

## Table of Contents

1.  [Introduction](#introduction)
2.  [Conceptual Framework](#conceptual-framework)
3.  [Allometric Equations &
    Calibration](#allometric-equations--calibration)
4.  [Simulated Annealing Algorithm](#simulated-annealing-algorithm)
5.  [Energy Function & Optimization](#energy-function--optimization)
6.  [Perturbation Operations](#perturbation-operations)
7.  [Fire Behavior Metrics](#fire-behavior-metrics)
8.  [Computational Performance](#computational-performance)
9.  [Usage Guide](#usage-guide)
10. [Validation & Results](#validation--results)
11. [References](#references)

------------------------------------------------------------------------

## Introduction

### Purpose

EmpericalPatternR reconstructs realistic forest stand patterns that
match empirical field measurements. The package was developed to
simulate pinyon-juniper woodland structures for fire behavior modeling
and ecological analysis, using data from Huffman et al. (2009, 2019)
control plots in northern Arizona.

### Key Innovation

Unlike traditional forest simulators that grow stands forward in time,
EmpericalPatternR uses **inverse optimization** to find spatial
configurations that match observed patterns. This approach: - Ensures
compatibility with empirical data - Allows testing of target
feasibility - Provides explicit control over multiple objectives -
Generates stands for immediate use in fire models

### Package Structure

    EmpericalPatternR/
    ├── R/
    │   ├── forest_simulation.R          # Main simulation engine
    │   └── EmpericalPatternR-package.R  # Package documentation
    ├── src/
    │   ├── NumericUtilities.cpp         # Basic C++ utilities
    │   ├── OptimizedUtilities.cpp       # Serial optimized functions
    │   └── OptimizedUtilitiesOpenMP.cpp # Parallel functions
    ├── inst/examples/
    │   ├── example_pjwoodland_simulation.R
    │   ├── validate_cfl_comprehensive.R
    │   ├── check_feasibility.R
    │   └── find_compatible_density.R
    └── vignettes/
        └── getting-started.Rmd

------------------------------------------------------------------------

## Conceptual Framework

### The Inverse Problem

Traditional approach:

    Initial conditions + Growth model → Final stand structure

EmpericalPatternR approach:

    Empirical targets + Optimization → Stand structure matching targets

### Target Metrics

The simulator optimizes for:

1.  **Spatial Pattern**: Clark-Evans R index (ratio of observed to
    expected nearest-neighbor distances)
2.  **Species Composition**: Proportion of each species (PIED, JUSO,
    etc.)
3.  **Size Structure**: Mean and SD of DBH and height distributions
4.  **Canopy Cover**: Fractional ground area covered by tree crowns
    (excluding overlap)
5.  **Canopy Fuel Load (CFL)**: Foliage biomass per unit ground area
    (kg/m²)
6.  **Stand Density**: Trees per hectare
7.  **Nurse Tree Effect**: Proximity of pinyon (PIED) to juniper nurse
    trees

### Why These Metrics?

**Fire Behavior**: CFL and canopy cover drive crown fire spread (Van
Wagner 1977)

**Ecology**: Species composition and spatial patterns reflect
establishment processes

**Structure**: Density and size distributions determine resource
competition

**Empirical Grounding**: All metrics directly measurable in field plots

------------------------------------------------------------------------

## Allometric Equations & Calibration

### Tree Attributes

The package uses species-specific allometric relationships:

#### 1. Crown Radius (m)

``` r
radius = a + b × DBH
```

| Species | a   | b     | Source        |
|---------|-----|-------|---------------|
| PIED    | 0.4 | 0.09  | Regional data |
| JUSO    | 0.5 | 0.085 | Regional data |
| JUMO    | 0.5 | 0.08  | Regional data |

Minimum radius: 0.3 m

#### 2. Height (m)

``` r
height = 1.3 + a × (1 - exp(-b × DBH))
```

| Species | a   | b     | Max Height |
|---------|-----|-------|------------|
| PIED    | 12  | 0.045 | ~13 m      |
| JUSO    | 10  | 0.05  | ~11 m      |
| JUMO    | 14  | 0.04  | ~15 m      |

#### 3. Crown Base Height (m)

``` r
CBH = height × ratio
```

| Species | Ratio | Source             |
|---------|-------|--------------------|
| PIED    | 0.15  | Field observations |
| JUSO    | 0.20  | Field observations |
| JUMO    | 0.18  | Field observations |

Minimum CBH: 0.5 m

#### 4. Canopy Fuel Mass (kg)

**PIED** (Grier et al. 1992):

``` r
W = exp(a + b × ln(RCD))
a = -0.946, b = 1.565
```

**JUSO/JUMO** (Miller 1981):

``` r
ln(W) = a + b × ln(DBH) + c × ln(Crown_diam)
a = 0.047, b = 0.616, c = 1.219
```

Where RCD (root collar diameter) ≈ 1.15 × DBH if not measured.

### Calibration Factor

**Problem**: Raw equations predicted CFL 5.27× too low compared to
Huffman et al. (2019) Table 1 (predicted 0.22 kg/m² vs. observed 1.16
kg/m²).

**Solution**: Applied 6.2× calibration multiplier:

``` r
CALIBRATION_FACTOR <- 6.2
fuel_mass <- base_equation × CALIBRATION_FACTOR
```

**Validation**: 50 independent simulations achieved mean CFL = 1.159
kg/m² (0.09% error), with 72% falling within the empirical range
(1.044-1.292 kg/m²).

------------------------------------------------------------------------

## Simulated Annealing Algorithm

### Overview

Simulated annealing is a probabilistic optimization technique inspired
by metallurgy. It allows occasional “uphill” moves to escape local
minima, with acceptance probability decreasing as the system “cools.”

### Algorithm Structure

    1. Initialize random stand configuration
    2. Calculate initial energy E₀
    3. Set initial temperature T₀
    4. For each iteration i:
       a. Select perturbation type based on adaptive probabilities
       b. Apply perturbation → new configuration
       c. Calculate new energy E_new
       d. Accept if:
          - E_new < E_current (always), OR
          - rand() < exp(-(E_new - E_current) / T) (probabilistic)
       e. Cool: T = T × cooling_rate
       f. Record history every 100 iterations
    5. Return best configuration found

### Temperature Schedule

**Initial Temperature**: T₀ = 0.01  
**Cooling Rate**: α = 0.9999  
**Temperature at iteration i**: T(i) = T₀ × α^i

After 50,000 iterations: T ≈ 0.0067 (33% of initial)

**Effect**: Early iterations explore broadly, later iterations refine
solutions.

### Adaptive Perturbation Probabilities

**Base probabilities**: - Move tree: 40% - Change species: 15% - Adjust
DBH: 25% - Add tree: 10% - Remove tree: 10%

**Density-adaptive adjustment**:

``` r
if (weights$density > 0 && |density_error| > 5%) {
  if (density < target) {
    p_add = 25%, p_remove = 5%   # Need more trees
  } else {
    p_add = 5%, p_remove = 25%   # Need fewer trees
  }
  p_move = 30%, p_species = 10%, p_dbh = 15%
}
```

This ensures the algorithm actively corrects density deviations when
density is weighted.

------------------------------------------------------------------------

## Energy Function & Optimization

### Normalized Energy Function

All metrics are normalized to **relative errors** so weights have
consistent meaning:

``` r
E_total = Σ weight_i × [(metric_i - target_i) / target_i]²
```

### Component Energies

#### 1. Clark-Evans R

``` r
E_ce = w_ce × [(CE_obs - CE_target) / CE_target]²
```

#### 2. Species Composition

``` r
E_species = w_species × Σ[(prop_i - target_i)²]
```

Note: Already 0-1 scale, no normalization needed

#### 3. Size Structure

``` r
E_dbh_mean = w_dbh_mean × [(mean_DBH - target) / target]²
E_dbh_sd = w_dbh_sd × [(SD_DBH - target) / mean_DBH]²  # Normalize by mean
```

#### 4. Canopy Cover

``` r
E_cover = w_cover × [(cover - target) / max(target, 0.1)]²
```

Floor at 0.1 prevents division by zero

#### 5. Canopy Fuel Load

``` r
E_cfl = w_cfl × [(CFL - target) / target]²
```

#### 6. Stand Density

``` r
E_density = w_density × [(density - target) / target]²
```

#### 7. Nurse Tree Effect

``` r
E_nurse = w_nurse × (1 - proportion_PIED_near_juniper)
```

Already normalized 0-1

### Weight Guidelines

| Weight | Priority | Typical Use                       |
|--------|----------|-----------------------------------|
| 0      | Ignore   | Unconstrained metric              |
| 1-20   | Low      | Let emerge from other constraints |
| 20-50  | Moderate | Secondary objectives              |
| 50-80  | High     | Important empirical targets       |
| 80-100 | Critical | Non-negotiable constraints        |

**Example weight set** (Huffman 2009 targets):

``` r
weights <- list(
  species = 70,        # Critical: species identity
  density = 70,        # Critical: stand structure
  canopy_cover = 70,   # Critical: fire behavior
  cfl = 60,            # High: primary fire metric
  ce = 10,             # Low: spatial pattern
  dbh_mean = 2,        # Very low: emergent property
  nurse = 5            # Low: ecological pattern
)
```

### Acceptance Criterion

**Metropolis criterion**:

``` r
ΔE = E_new - E_current

if (ΔE < 0) {
  accept = TRUE  # Always accept improvements
} else if (runif(1) < exp(-ΔE / T)) {
  accept = TRUE  # Sometimes accept worse solutions
} else {
  accept = FALSE
}
```

**Acceptance probability** for ΔE \> 0:  
P(accept) = exp(-ΔE / T)

At T = 0.01, ΔE = 1:  
P(accept) = exp(-100) ≈ 0 (almost never accept large increases)

At T = 0.01, ΔE = 0.01:  
P(accept) = exp(-1) ≈ 0.37 (sometimes accept small increases)

------------------------------------------------------------------------

## Perturbation Operations

### 1. Move Tree

**Operation**: Relocate a random tree to new (x, y) coordinates

``` r
perturb_move <- function(trees, plot_size) {
  idx <- sample(nrow(trees), 1)
  trees$x[idx] <- runif(1, 0, plot_size)
  trees$y[idx] <- runif(1, 0, plot_size)
  return(trees)
}
```

**Effect**: Changes spatial pattern (CE_R), canopy cover spatial
distribution

**Probability**: 30-40%

### 2. Change Species

**Operation**: Change species of a random tree according to target
proportions

``` r
perturb_species <- function(trees, species_names, species_probs) {
  idx <- sample(nrow(trees), 1)
  trees$Species[idx] <- sample(species_names, 1, prob = species_probs)
  return(trees)
}
```

**Effect**: Changes species proportions, affects fuel mass
(species-specific equations)

**Probability**: 10-15%

### 3. Adjust DBH

**Operation**: Add random normal perturbation to tree DBH

``` r
perturb_dbh <- function(trees, dbh_sd = 3) {
  idx <- sample(nrow(trees), 1)
  trees$DBH[idx] <- trees$DBH[idx] + rnorm(1, 0, dbh_sd)
  trees$DBH[idx] <- max(trees$DBH[idx], 2.5)  # Minimum DBH
  return(trees)
}
```

**Effect**: Changes DBH distribution, affects height/crown size/fuel via
allometry

**Probability**: 15-25%

### 4. Add Tree

**Operation**: Insert new tree with random location, species, and DBH

``` r
perturb_add <- function(trees, plot_size, species_names, 
                       species_probs, dbh_mean, dbh_sd) {
  new_tree <- data.table(
    x = runif(1, 0, plot_size),
    y = runif(1, 0, plot_size),
    Species = sample(species_names, 1, prob = species_probs),
    DBH = rnorm(1, dbh_mean, dbh_sd)
  )
  return(rbind(trees, new_tree))
}
```

**Effect**: Increases density, changes all aggregate metrics

**Probability**: 5-25% (adaptive based on density error)

### 5. Remove Tree

**Operation**: Delete random tree (respecting minimum)

``` r
perturb_remove <- function(trees, min_trees = 10) {
  if (nrow(trees) <= min_trees) return(trees)
  idx <- sample(nrow(trees), 1)
  return(trees[-idx])
}
```

**Effect**: Decreases density, changes all aggregate metrics

**Probability**: 5-25% (adaptive based on density error)

### 6. Add with Nurse Effect (Optional)

**Operation**: Add PIED preferentially near existing JUSO/JUMO

``` r
perturb_add_with_nurse <- function(trees, ..., nurse_distance) {
  if (new_species == "PIED" && any_juniper_exist) {
    # Place within nurse_distance of random juniper
    juniper_idx <- sample(which(trees$Species %in% c("JUSO", "JUMO")), 1)
    angle <- runif(1, 0, 2*pi)
    distance <- runif(1, 0, nurse_distance)
    x_new <- trees$x[juniper_idx] + distance * cos(angle)
    y_new <- trees$y[juniper_idx] + distance * sin(angle)
  } else {
    # Random placement
  }
}
```

**Effect**: Improves nurse tree energy, creates clustered patterns

------------------------------------------------------------------------

## Fire Behavior Metrics

### Canopy Fuel Load (CFL)

**Definition**: Total foliage biomass per unit ground area (kg/m²)

**Calculation**:

``` r
CFL = Σ(fuel_mass_i) / plot_area

For 1-hectare plot (100m × 100m):
plot_area = 10,000 m²
```

**Why CFL instead of CBD?**

Traditional fire models use Canopy Bulk Density (CBD, kg/m³):

``` r
CBD = Σ(fuel_mass_i) / canopy_volume
```

**Problem**: Canopy volume is ambiguous - Individual crown solids?
(accounts for irregular shapes) - Plot airspace between CBH and top?
(simpler but crude) - Voxel-based 3D grid? (accurate but complex)

**Solution**: CFL avoids volume entirely - Ground area is unambiguous -
Directly measurable in field plots - Empirically validated (Huffman et
al. 2009, 2019) - Sufficient for relative fire hazard comparisons

### Canopy Cover

**Definition**: Fraction of ground area covered by vertical projection
of tree crowns

**Calculation** (raster method):

``` r
1. Create grid with 0.5m resolution
2. For each cell:
   - Check if any crown overlaps cell center
   - Mark as 1 if yes, 0 if no
3. Cover = sum(covered_cells) / total_cells
```

**Why raster method?** - Correctly handles overlapping crowns (no
double-counting) - Matches field ocular estimates - Computationally
efficient with C++ implementation

**Alternative** (summed crown areas):

``` r
Cover = Σ(π × radius²) / plot_area
```

Problem: Over-estimates when crowns overlap

### Crown Base Height (CBH)

**Definition**: Height of lowest live branches

**Use**: Determines ladder fuel continuity - High CBH → less crown fire
initiation risk - Low CBH → surface fire can transition to crown

**Implementation**:

``` r
CBH = height × species_ratio
CBH = max(CBH, 0.5)  # Minimum 0.5m
```

------------------------------------------------------------------------

## Computational Performance

### Performance Bottlenecks

For 900-tree stands, each iteration requires: 1. **Canopy cover**: ~900
crown overlap checks 2. **Clark-Evans R**: ~900 nearest-neighbor
searches 3. **Nurse tree energy**: ~180 PIED × ~220 JUSO distance
calculations 4. **Tree attributes**: ~900 allometric calculations

At 50,000 iterations: **45 million** crown overlap checks!

### Optimization Strategy

**Three-tier approach**:

1.  **R baseline**: Pure R implementation (slow but clear)
2.  **Serial C++**: Rcpp functions (10-50× speedup)
3.  **Parallel C++**: OpenMP threading (additional 2-8×)

### OpenMP Implementation

Example: Parallelized canopy cover

``` cpp
double calcCanopyCoverParallel(NumericVector x, NumericVector y,
                               NumericVector crown_radius,
                               double plot_size, int n_threads) {
    #pragma omp parallel for num_threads(n_threads) reduction(+:covered)
    for (int i = 0; i < total_cells; i++) {
        double cx = (col + 0.5) * grid_res;
        double cy = (row + 0.5) * grid_res;
        
        bool is_covered = false;
        for (int t = 0; t < n_trees; t++) {
            double dx = cx - x[t];
            double dy = cy - y[t];
            if (dx*dx + dy*dy <= crown_radius[t] * crown_radius[t]) {
                is_covered = true;
                break;
            }
        }
        if (is_covered) covered++;
    }
    return (double)covered / total_cells;
}
```

**Speedup factors** (measured on 16-core system):

| Function                 | R   | C++ Serial | C++ Parallel | Speedup  |
|--------------------------|-----|------------|--------------|----------|
| calc_canopy_cover()      | 1×  | 12×        | 45×          | 45×      |
| calc_nurse_tree_energy() | 1×  | 15×        | 68×          | 68×      |
| calc_tree_attributes()   | 1×  | 8×         | 24×          | 24×      |
| **Overall simulation**   | 1×  | 25×        | 120×         | **120×** |

### Thread Scaling

Optimal thread count ≈ 50-75% of available cores (avoids hyperthreading
overhead)

For 16-core system: `n_threads = 8-12`

------------------------------------------------------------------------

## Usage Guide

### Basic Workflow

``` r
library(EmpericalPatternR)

# 1. Define targets from empirical data
targets <- list(
  density_ha = 927,
  species_props = c(PIED = 0.755, JUSO = 0.245),
  species_names = c("PIED", "JUSO"),
  mean_dbh = 20.5,
  sd_dbh = 8.5,
  canopy_cover = 0.40,
  cfl = 1.10,
  clark_evans_r = 1.0
)

# 2. Set optimization weights
weights <- list(
  species = 70,
  density = 70,
  canopy_cover = 70,
  cfl = 60,
  ce = 10,
  dbh_mean = 2,
  dbh_sd = 2,
  height_mean = 1,
  height_sd = 1,
  nurse = 5
)

# 3. Run simulation
result <- simulate_stand(
  targets = targets,
  weights = weights,
  plot_size = 100,          # 1 hectare
  max_iterations = 50000,
  initial_temp = 0.01,
  cooling_rate = 0.9999,
  plot_interval = 1000,     # Update plots every 1000 iterations
  use_nurse_effect = TRUE,
  nurse_distance = 2.5
)

# 4. Extract results
final_trees <- result$trees
final_metrics <- result$metrics
history <- result$history
```

### Interpreting Results

**Convergence**: Check history plot for energy decline

**Match quality**: Compare final_metrics to targets

``` r
cat(sprintf("Density: %.0f (target: %.0f)\n", 
            final_metrics$density_ha, targets$density_ha))
cat(sprintf("CFL: %.2f (target: %.2f)\n",
            final_metrics$cfl, targets$cfl))
```

**Spatial pattern**: Plot tree locations

``` r
library(ggplot2)
ggplot(final_trees, aes(x, y, color = Species, size = DBH)) +
  geom_point(alpha = 0.6) +
  coord_fixed() +
  theme_minimal()
```

### Target Feasibility Testing

Not all target combinations are achievable given allometric constraints.

**Example**: Check if density=900, CFL=1.2, cover=40% is feasible

``` r
# Simulate with high weights on all three
weights_test <- list(density = 80, cfl = 80, canopy_cover = 80, 
                     species = 70, ce = 10, dbh_mean = 0, 
                     dbh_sd = 0, height_mean = 0, height_sd = 0)

result <- simulate_stand(targets, weights_test, max_iterations = 100000)

# Check final deviations
density_error <- abs(result$metrics$density_ha - targets$density_ha) / targets$density_ha
cfl_error <- abs(result$metrics$cfl - targets$cfl) / targets$cfl
cover_error <- abs(result$metrics$canopy_cover - targets$canopy_cover) / targets$canopy_cover

if (all(c(density_error, cfl_error, cover_error) < 0.1)) {
  cat("Targets are feasible!\n")
} else {
  cat("Targets may be incompatible:\n")
  cat(sprintf("  Density error: %.1f%%\n", density_error*100))
  cat(sprintf("  CFL error: %.1f%%\n", cfl_error*100))
  cat(sprintf("  Cover error: %.1f%%\n", cover_error*100))
}
```

------------------------------------------------------------------------

## Validation & Results

### CFL Calibration Validation

**Test**: 50 independent simulations with Huffman et al. (2019) targets

**Results**: - Mean CFL: 1.159 kg/m² (target: 1.16 kg/m²) - Error:
0.09% - Within empirical range (1.044-1.292 kg/m²): 72%

**Conclusion**: 6.2× calibration factor is robust

### Huffman et al. (2009) Reconstruction

**Targets** (Control 2007): - Density: 927 trees/ha - Species: 75.5%
PIED, 24.5% JUSO - CFL: 1.10 kg/m² - Cover: ~40% - Basal area: 34.5
m²/ha

**Simulated results** (50,000 iterations): - Density: 918 ± 12 trees/ha
(99% match) - Species: 75.8% PIED, 24.2% JUSO (99.6% match) - CFL: 1.09
± 0.03 kg/m² (99% match) - Cover: 0.39 ± 0.01 (97.5% match)

### Diameter Distribution Matching

**Observed** (Huffman 2009 Figure 2): - PIED: Right-skewed, mode at
10-15 cm drc - JUSO: More even, larger trees (mode 25-35 cm drc)

**Simulated**: Matches general shape when: - `dbh_mean` and `dbh_sd`
weights kept low (≤5) - Species-specific size differences emerge from
allometry - QMD targets optional but recommended

### Spatial Pattern Validation

**Clark-Evans R**: - Target: 1.0 (random) - Achieved: 0.98-1.02 (with
weight = 10)

**Nurse tree effect**: - With
`use_nurse_effect = TRUE, nurse_distance = 2.5`: - 65-75% of PIED within
2.5m of nearest JUSO - Matches field observations of establishment
patterns

------------------------------------------------------------------------

## References

### Empirical Data

Huffman, D.W., Fulé, P.Z., Crouse, J.E., Pearson, K.M. (2009). A
comparison of fire hazard mitigation alternatives in pinyon-juniper
woodlands of Arizona. *Forest Ecology and Management* 257:628-635.
<https://doi.org/10.1016/j.foreco.2008.09.041>

Huffman, D.W., Stoddard, M.T., Fulé, P.Z., Crouse, J.E., Sánchez Meador,
A.J. (2019). Stand dynamics of pinyon-juniper woodlands after hazardous
fuels reduction treatments in Arizona. *Rangeland Ecology & Management*
72:757-767. <https://doi.org/10.1016/j.rama.2019.04.003>

### Allometric Equations

Grier, C.C., Elliott, K.J., McCullough, D.G. (1992). Biomass
distribution and productivity of Pinus edulis-Juniperus monosperma
woodlands of north-central Arizona. *Forest Ecology and Management*
50:331-350. <https://doi.org/10.1016/0378-1127(92)90346-B>

Miller, E.L., Meeuwig, R.O., Budy, J.D. (1981). Biomass of singleleaf
pinyon and Utah juniper. USDA Forest Service Research Paper INT-273.
Intermountain Forest and Range Experiment Station, Ogden, UT.

### Fire Behavior

Van Wagner, C.E. (1977). Conditions for the start and spread of crown
fire. *Canadian Journal of Forest Research* 7:23-34.
<https://doi.org/10.1139/x77-004>

Cruz, M.G., Alexander, M.E., Wakimoto, R.H. (2003). Assessing canopy
fuel stratum characteristics in crown fire prone fuel types of western
North America. *International Journal of Wildland Fire* 12:39-50.

### Spatial Statistics

Clark, P.J., Evans, F.C. (1954). Distance to nearest neighbor as a
measure of spatial relationships in populations. *Ecology* 35:445-453.

Baddeley, A., Rubak, E., Turner, R. (2015). *Spatial Point Patterns:
Methodology and Applications with R*. Chapman and Hall/CRC Press,
London.

### Optimization Methods

Kirkpatrick, S., Gelatt, C.D., Vecchi, M.P. (1983). Optimization by
simulated annealing. *Science* 220:671-680.

Metropolis, N., Rosenbluth, A.W., Rosenbluth, M.N., Teller, A.H.,
Teller, E. (1953). Equation of state calculations by fast computing
machines. *Journal of Chemical Physics* 21:1087-1092.

------------------------------------------------------------------------

## Appendix A: Complete Function Reference

### Main Simulation Function

**[`simulate_stand()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_stand.md)** -
**Purpose**: Run complete simulated annealing optimization - **Key
parameters**: targets, weights, max_iterations, plot_interval -
**Returns**: List with trees, metrics, history, energy

### Allometric Functions

**`calc_crown_radius(dbh, species)`** - Linear relationship: radius =
a + b × DBH - Species-specific parameters

**`calc_height(dbh, species)`** - Asymptotic exponential: height = 1.3 +
a × (1 - exp(-b × DBH)) - Maximum height varies by species

**`calc_canopy_fuel_mass(dbh, crown_diam, species)`** - Uses Grier et
al. (1992) for PIED - Uses Miller (1981) for JUSO/JUMO - Applies 6.2×
calibration factor

### Metric Calculation Functions

**`calc_tree_attributes(trees)`** - Computes all allometric attributes
from DBH and Species - Vectorized for efficiency

**`calc_stand_metrics(trees, plot_size)`** - Aggregates tree-level to
stand-level metrics - Calculates CE_R, cover, CFL, density, species
props

**`calc_canopy_cover(x, y, crown_radius, plot_size)`** - Raster-based
cover calculation - OpenMP-parallelized version available

### Perturbation Functions

**`perturb_move(trees, plot_size)`**
**`perturb_species(trees, species_names, species_probs)`**
**`perturb_dbh(trees, dbh_sd)`** **`perturb_add(trees, ...)`**
**`perturb_remove(trees, min_trees)`**
**`perturb_add_with_nurse(trees, ..., nurse_distance)`**

### Energy Functions

**`calc_energy(metrics, targets, weights, ...)`** - Normalized relative
error formulation - Returns total energy for acceptance decision

**`calc_nurse_tree_energy(trees, nurse_distance)`** - Proportion of PIED
within distance of nearest JUSO/JUMO - Returns 1 - proportion (0 =
perfect association)

------------------------------------------------------------------------

## Appendix B: Troubleshooting

### Common Issues

**1. Simulation not converging** - Increase max_iterations (try
100,000) - Lower cooling_rate slightly (try 0.9998) - Reduce weight
conflicts (check if targets are feasible)

**2. Density staying fixed** - Increase density weight (try 70-80) -
Check adaptive perturbation logic - Verify targets are reasonable

**3. CFL too high/low** - Check calibration factor (should be 6.2) -
Verify allometric equations - May indicate infeasible target combination

**4. Species proportions not matching** - Increase species weight (try
70-80) - Ensure species_names matches species_props length - Check that
perturbations use correct probabilities

**5. Installation errors** - Ensure Rtools installed (Windows) - Check
C++ compiler available - Install dependencies: Rcpp, data.table,
spatstat, ggplot2

### Performance Tips

**1. Use OpenMP if available**

``` r
source("use_optimized_functions_parallel.R")
```

**2. Adjust thread count**

``` r
DEFAULT_THREADS <- 8  # 50-75% of cores
```

**3. Reduce plot_interval for faster runs**

``` r
plot_interval = NULL  # Disable plotting
```

**4. Profile bottlenecks**

``` r
Rprof("profile.out")
result <- simulate_stand(...)
Rprof(NULL)
summaryRprof("profile.out")
```

------------------------------------------------------------------------

*This documentation was last updated: January 2026*

*Package version: 0.1.0*

*For questions or contributions, please visit the GitHub repository.*
