# EmpiricalPatternR Examples

This folder contains example scripts demonstrating how to use the EmpiricalPatternR package to simulate forest stands matching empirical data.

## Available Examples

### Example 1: Pinyon-Juniper Woodland (`example_01_pinyon_juniper.R`)

Simulates a pinyon-juniper woodland stand based on Huffman et al. (2009) field data from Fishlake National Forest, Utah.

**Features demonstrated:**
- Matching empirical density and species composition
- Optimizing canopy fuel load (CFL) for fire behavior modeling
- Nurse tree associations (pinyons near junipers)
- Post-disturbance mortality simulation
- Complete workflow from targets to results

**Runtime:** ~5-10 minutes for 10,000 iterations

**Key targets:**
- Density: 927 trees/ha
- Species: 75.5% PIED, 24.5% JUSO
- CFL: 1.10 kg/m²
- Canopy cover: 40%

### Example 2: Ponderosa Pine Forest (`example_02_ponderosa_pine.R`)

Demonstrates simulating a ponderosa pine dominated mixed-conifer forest with custom allometric equations.

**Features demonstrated:**
- Custom allometric parameters for larger trees
- Different forest type with multiple species
- Managed forest spacing patterns
- Lower mortality rates
- Using alternative allometric functions

**Runtime:** ~3-5 minutes for 5,000 iterations

**Key targets:**
- Density: 450 trees/ha (managed stand)
- Species: 70% PIPO, 20% PSME, 10% ABCO  
- Mean DBH: 35 cm (larger trees)
- Regular spacing (Clark-Evans R = 1.4)

## How to Run Examples

### From R Console

```r
# Run Example 1
source("inst/examples/example_01_pinyon_juniper.R")

# Run Example 2
source("inst/examples/example_02_ponderosa_pine.R")
```

### From Command Line

```powershell
# Example 1
Rscript inst/examples/example_01_pinyon_juniper.R

# Example 2
Rscript inst/examples/example_02_ponderosa_pine.R
```

## Modifying Examples for Your Own Data

### 1. Change Target Parameters

Edit the `targets` list to match your field data:

```r
targets <- list(
  density_ha = YOUR_DENSITY,        # Trees per hectare
  species_props = c(SP1 = 0.6, SP2 = 0.4),  # Species proportions
  species_names = c("SP1", "SP2"),
  mean_dbh = YOUR_MEAN_DBH,         # cm
  sd_dbh = YOUR_SD_DBH,
  canopy_cover = YOUR_COVER,        # 0-1
  cfl = YOUR_CFL,                   # kg/m²
  clark_evans_r = 1.0               # Spatial pattern
)
```

### 2. Adjust Optimization Weights

Modify the `weights` list to prioritize different metrics:

```r
weights <- list(
  density = 80,        # High priority (very important)
  species = 60,        # High priority
  canopy_cover = 50,   # Moderate priority
  cfl = 50,
  ce = 10,             # Low priority (emergent)
  dbh_mean = 5,
  nurse = 0            # Disabled
)
```

**Weight guidelines:**
- 0: Ignore this metric
- 1-20: Low priority (let it emerge from other constraints)
- 20-50: Moderate priority
- 50-80: High priority (actively optimize)
- 80-100: Critical (dominates optimization)

### 3. Use Custom Allometric Equations

Create your own allometric parameter set:

```r
# Define custom parameters
my_allometric_params <- list(
  crown_radius = list(
    MYSP = list(a = 0.5, b = 0.10),  # radius = a + b * DBH
    default = list(a = 0.4, b = 0.09)
  ),
  height = list(
    MYSP = list(a = 20, b = 0.03),   # height = 1.3 + a*(1-exp(-b*DBH))
    default = list(a = 15, b = 0.04)
  ),
  crown_ratio = list(
    MYSP = list(a = 0.70, b = 0.10), # ratio = a - b*log(DBH)
    default = list(a = 0.65, b = 0.09)
  ),
  crown_mass = list(
    MYSP = list(a = 0.20, b = 2.1),  # mass = a * DBH^b
    default = list(a = 0.15, b = 2.2)
  )
)

# Use custom equations
height <- calc_height(dbh_values, species_codes, my_allometric_params)
radius <- calc_crown_radius(dbh_values, species_codes, my_allometric_params)
```

**Note:** Full integration of custom allometric equations into `simulate_stand()` 
requires passing the `allometric_params` argument through to `calc_tree_attributes()`. 
This is a planned enhancement.

### 4. Adjust Iteration Count

Balance runtime vs. optimization quality:

```r
result <- simulate_stand(
  targets = targets,
  weights = weights,
  max_iterations = 1000,   # Quick test: 1,000
                          # Standard: 5,000-10,000
                          # Publication: 50,000+
  ...
)
```

**Iteration guidelines:**
- 100-500: Quick testing, rough approximation
- 1,000-5,000: Development and exploration
- 5,000-10,000: Standard analysis (examples use this)
- 10,000-50,000: High-quality results for publication
- 50,000+: Very high convergence, diminishing returns

## Output and Visualization

All examples produce a result object with:

```r
result$trees       # Final tree list with all attributes
result$metrics     # Stand-level summary metrics
result$history     # Optimization history (energy over time)
result$energy      # Final energy value (objective function)
```

### Example Visualizations

```r
# Tree map colored by species
plot(result$trees$x, result$trees$y, 
     col = as.factor(result$trees$Species),
     pch = 19, cex = result$trees$CrownRadius/2,
     main = "Simulated Stand", xlab = "X (m)", ylab = "Y (m)")
legend("topright", legend = levels(as.factor(result$trees$Species)),
       col = 1:length(levels(as.factor(result$trees$Species))), pch = 19)

# Size distribution
hist(result$trees$DBH, breaks = 20, 
     main = "DBH Distribution", xlab = "DBH (cm)")

# Optimization convergence
plot(result$history$Iteration, result$history$Energy,
     type = "l", main = "Optimization Progress",
     xlab = "Iteration", ylab = "Energy")

# Live vs dead trees
live <- result$trees[result$trees$Status == "live", ]
dead <- result$trees[result$trees$Status == "dead", ]
plot(live$x, live$y, col = "darkgreen", pch = 19, cex = 1.5,
     xlim = c(0, 100), ylim = c(0, 100),
     main = "Live and Dead Trees", xlab = "X (m)", ylab = "Y (m)")
points(dead$x, dead$y, col = "gray50", pch = 19, cex = 1.5)
legend("topright", c("Live", "Dead"), col = c("darkgreen", "gray50"), pch = 19)
```

## References

Huffman, D.W., Fulé, P.Z., Crouse, J.E., & Pearson, K.M. (2009). A comparison of fire hazard mitigation alternatives in pinyon-juniper woodlands of Arizona. *Forest Ecology and Management*, 257, 628-635.

## Getting Help

For detailed function documentation:

```r
?simulate_stand
?calc_crown_radius
?calc_height
?calc_stand_metrics
?simulate_mortality
```

For package overview:

```r
?EmpiricalPatternR
```
