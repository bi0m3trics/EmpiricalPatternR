# Pinyon-Juniper Forest Simulation Model

## Overview

This R package simulates pinyon-juniper woodland spatial patterns using simulated annealing optimization. The model reconstructs realistic forest stands that match empirical data from Huffman et al. (2019), including spatial patterns, tree size distributions, species composition, and canopy fuel metrics.

## Key Features

- **Simulated annealing optimization** to match multiple ecological objectives simultaneously
- **Canopy Fuel Load (CFL)** calibration based on empirical data
- **Species-specific allometries** for PIED (pinyon pine), JUMO/JUSO (juniper species)
- **Real-time visualization** showing convergence and spatial patterns
- **C++ optimization** with optional OpenMP parallelization (10-300x speedup)
- **Nurse tree effects** modeling facilitation between species

---

## Target Parameters (Huffman et al. 2019)

Empirical values from Kaibab National Forest, Arizona (Table 1, Control 2004):

| Parameter | Value | Units |
|-----------|-------|-------|
| Stand Density | 960 | trees/ha |
| Canopy Cover | 40% | - |
| Canopy Fuel Load (CFL) | 1.16 | kg/m² |
| Mean DBH | ~18 | cm |
| Species Mix | 55% PIED, 45% JUSO | - |
| Spatial Pattern | 0.9 | Clark-Evans R |

---

## Canopy Fuel Load (CFL) Calibration

### Why CFL Instead of CBD?

**Canopy Fuel Load (CFL)** is used as the primary fire metric instead of Canopy Bulk Density (CBD) because:

1. **Simpler calculation**: CFL = Total foliage biomass / Ground area (no volume needed)
2. **Direct empirical validation**: Huffman et al. provides CFL measurements
3. **No volume ambiguity**: Avoids confusion between crown volume vs. plot airspace
4. **Standard metric**: Widely used in fire behavior modeling

### Calibration Results

The fuel allometric equations were calibrated with a **6.2x multiplier** to match empirical CFL targets:

```
n = 50 simulations
Mean CFL:   1.159 kg/m² (0% error from target!)
SD:         0.115 kg/m²
Range:      0.887 - 1.390 kg/m²
Success:    72% of simulations within target range (1.044-1.292 kg/m²)
```

### Implementation

```r
# Base allometric equations (Grier et al. 1992, Miller 1981)
fuel_mass <- switch(species,
  PIED = 10^(a_pied + b_pied * log10(rcd)),
  JUMO = 10^(a_jumo + b_jumo * log10(rcd)),
  JUSO = exp(m0 + m_dbh * log(dbh) + m_c * log(crown_diam))
)

# Apply calibration factor
CALIBRATION_FACTOR <- 6.2
return(fuel_mass * CALIBRATION_FACTOR)
```

---

## Usage

### Basic Simulation

```r
library(data.table)
source("forest_simulation.R")

# Define targets
targets <- list(
  density_ha = 960,
  canopy_cover = 0.40,
  cfl = 1.16,
  clark_evans_r = 0.9,
  mean_dbh = 18,
  sd_dbh = 8,
  mean_height = 6.5,
  sd_height = 2.5,
  species_props = c(PIED = 0.55, JUSO = 0.45)
)

# Define optimization weights
weights <- list(
  ce = 2.0,              # Spatial pattern
  dbh_mean = 0.02,       # Mean DBH
  dbh_sd = 0.02,         # SD DBH
  height_mean = 0.01,    # Mean height
  height_sd = 0.01,      # SD height
  species = 15.0,        # Species composition (high priority)
  canopy_cover = 8.0,    # Canopy cover (high priority)
  cfl = 12.0,            # Canopy fuel load (high priority)
  density = 0.0001,      # Stand density (low - emergent property)
  nurse = 3.0            # Nurse tree effect (optional)
)

# Run simulation
result <- simulate_forest_stand(
  targets = targets,
  weights = weights,
  plot_size = 100,              # 100m × 100m = 1 ha
  max_iterations = 50000,
  initial_temp = 0.01,
  cooling_rate = 0.9999,
  verbose = TRUE,
  plot_interval = 100
)

# Access results
trees <- result$trees          # Final tree locations and attributes
metrics <- result$metrics      # Stand-level metrics
history <- result$history      # Optimization history
```

### Running the Example

```r
source("example_pjwoodland_simulation.R")
```

This runs a complete simulation with Huffman et al. parameters, including 20% mortality simulation.

---

## File Structure

### Core Files

- **`forest_simulation.R`** - Main simulation engine with annealing algorithm
- **`example_pjwoodland_simulation.R`** - Complete working example
- **`NumericUtilities.cpp`** - C++ functions for performance
- **`use_optimized_functions_parallel.R`** - OpenMP parallelization setup

### Validation Files

- **`validate_cfl_comprehensive.R`** - CFL calibration validation (50 simulations)
- **`test_cfl_validation.R`** - Quick CFL test
- **`check_feasibility.R`** - Check if target combinations are achievable
- **`find_compatible_density.R`** - Find compatible density for given CFL/cover

---

## Performance Optimization

### C++ Acceleration

The package includes C++ implementations of computationally expensive functions:

- **Serial C++**: 10-50x faster than pure R
- **OpenMP parallel**: 50-300x faster (with multi-core)

To use OpenMP (if available):
```r
source("use_optimized_functions_parallel.R")
```

Falls back to serial C++ if OpenMP is unavailable.

### Optimization Tips

For large simulations (100+ ha):
1. Reduce `plot_interval` (update plots less frequently)
2. Increase `cooling_rate` closer to 1.0 (slower cooling = better convergence)
3. Use C++ functions (automatically enabled when sourcing files)
4. Consider reducing `max_iterations` for initial exploration

---

## Real-Time Visualization

During optimization, a 5-panel display updates every `plot_interval` iterations:

**Left Column (time series):**
1. Clark-Evans R (spatial pattern)
2. Canopy Cover
3. Canopy Fuel Load (CFL)
4. Species Composition

**Right Panel:**
- Large spatial view showing:
  - Semi-transparent crown polygons (colored by species)
  - Stem locations (sized by DBH, colored by species)
  - Iteration info overlay

**Bottom (full width):**
- Energy convergence plot (log scale)

---

## Target Feasibility

Not all combinations of density, CFL, and canopy cover are achievable given tree allometries. Use the feasibility checker:

```r
source("check_feasibility.R")  # Check if targets are compatible
```

**Example incompatible targets:**
- Density = 900 trees/ha, CFL = 1.2 kg/m², Cover = 40%
- At 900 trees/ha, even small trees produce CFL ≈ 1.9 kg/m²

**Why?** The allometric equations link DBH → crown size → fuel mass. You can't independently set all three variables; one must emerge from the others.

**Solution:** Use empirically validated combinations (like Huffman values) or relax one constraint.

---

## Key Functions

### `simulate_forest_stand()`
Main simulation function using simulated annealing.

**Parameters:**
- `targets` - List of target metrics
- `weights` - List of optimization weights  
- `plot_size` - Plot dimension (m)
- `max_iterations` - Maximum annealing iterations
- `initial_temp` - Starting temperature
- `cooling_rate` - Temperature decay (closer to 1 = slower)
- `verbose` - Print progress
- `plot_interval` - Update plots every N iterations
- `use_nurse_effect` - Include nurse tree facilitation

**Returns:**
- `trees` - Final tree data.table
- `metrics` - Stand metrics
- `energy` - Final energy value
- `history` - Optimization history

### `calc_tree_attributes()`
Calculates tree-level attributes from DBH using species-specific allometries:
- Height
- Crown length, base height, radius
- Canopy fuel mass (calibrated)

### `calc_stand_metrics()`
Computes stand-level metrics:
- Density, canopy cover
- CFL, CBD (reference)
- Size distributions (mean/SD)
- Species proportions
- Spatial pattern (Clark-Evans R)

---

## Optimization Weights Guide

Weights control relative importance in the energy function: `E = Σ weight_i × (metric_i - target_i)²`

**Guidelines:**
- `0` - Ignore this metric
- `< 0.1` - Very low priority (size distributions have large natural scale)
- `1-5` - Moderate priority (spatial patterns)
- `5-15` - High priority (composition, canopy, fire metrics)
- `> 20` - Probably excessive

**Scale normalization:** Small weights on DBH/height compensate for large squared deviations (cm² units).

**Typical weights:**
```r
weights <- list(
  ce = 2.0,              # Spatial pattern
  dbh_mean = 0.02,       # Tree sizes (low - large numeric range)
  dbh_sd = 0.02,
  height_mean = 0.01,
  height_sd = 0.01,
  species = 15.0,        # Species mix (high priority)
  canopy_cover = 8.0,    # Canopy cover (high)
  cfl = 12.0,            # Fire metric (high)
  density = 0.0001,      # Usually emergent from other targets
  nurse = 3.0            # Ecological relationship
)
```

---

## Nurse Tree Effect

Pinyon pines often establish near junipers in nurse plant relationships. This can be included in optimization:

```r
result <- simulate_forest_stand(
  ...,
  use_nurse_effect = TRUE,
  nurse_distance = 2.5  # PIED should be ~2.5m from nearest JUSO
)
```

The nurse tree energy penalizes PIED trees that are far from JUSO trees, promoting realistic spatial associations.

---

## Mortality Simulation

After optimization converges, mortality can be applied:

```r
result <- simulate_forest_stand(
  ...,
  mortality_prop = 0.2  # 20% mortality
)
```

Mortality is size-selective (smaller trees more likely to die) and applied after stand structure converges.

---

## References

**Huffman, D.W., et al. (2019).** Stand Dynamics of Pinyon-Juniper Woodlands After Hazardous Fuels Reduction Treatments in Arizona. *Rangeland Ecology & Management* 72:757-767.

**Grier, C.C., et al. (1992).** Biomass distribution and above- and below-ground production in young and mature Abies amabilis zone ecosystems. *Canadian Journal of Forest Research* 22:1360-1370.

**Miller, R.F. (1981).** Nutritive value of Utah juniper biomass. *Journal of Range Management* 34:247-250.

---

## License & Citation

When using this model, please cite:
- Original empirical data: Huffman et al. (2019)
- Model framework: EmpericalPatternR package

---

## Version History

- **v2.0** (Jan 2026) - Switched to CFL-based optimization, removed CBD ambiguity
- **v1.5** - Added C++ optimization, OpenMP support
- **v1.0** - Initial release with CBD-based approach
