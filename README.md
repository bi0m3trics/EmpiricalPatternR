# EmpericalPatternR

## Overview

EmpericalPatternR is an R package for reconstructing spatial point patterns with specified characteristics using simulated annealing optimization. This enhanced version includes:

- **Improved performance** through optimized C++ algorithms
- **Precise density control** (trees per hectare)
- **Diameter distribution matching** using 3-parameter Weibull distributions
- **Backward compatibility** with the original API

## Features

### Core Functionality
- Reconstruct spatial point patterns matching a target Clark-Evans (CE) index
- Control species composition proportions
- Match target height attributes (mean and standard deviation)
- **NEW**: Explicit control of tree density (trees per hectare)
- **NEW**: Match diameter distributions using 3-parameter Weibull

### Performance Improvements
- Optimized C++ nearest neighbor search using priority queues
- Reduced memory allocation overhead
- Better algorithmic complexity for distance calculations
- Faster convergence through improved energy functions

## Installation

```R
# Required libraries
install.packages(c("Rcpp", "data.table", "spatstat", "ggplot2", "gridExtra"))

# Source the files
library(Rcpp)
library(data.table)
library(spatstat)
library(ggplot2)
library(gridExtra)

sourceCpp("NumericUtilities.cpp")
source("myReconstruction.R")
```

## Usage

### Basic Usage (Backward Compatible)

```R
# Define target parameters
CEtarget <- 1.60                                    # Clark-Evans index
SPPtarget <- c(Species1 = 0.4, Species2 = 0.3, Species3 = 0.3)  # Species proportions
HtAttrs <- list(mean = 15, sd = 5)                 # Height attributes
Density <- 250                                      # Trees per hectare

# Run reconstruction
result <- reconstruct_pattern(
  CEtarget = CEtarget,
  SPPtarget = SPPtarget,
  HtAttrs = HtAttrs,
  Density = Density,
  xmax = 100,           # Plot width in meters
  ymax = 100,           # Plot height in meters
  plotUpdateInterval = 500,
  maxSimSteps = 10000
)

# Access results
result$pattern   # spatstat ppp object
result$data      # data.table with tree attributes (x, y, Species, Height, DBH)
result$plotData  # convergence metrics over iterations
```

### Advanced Usage with Diameter Distribution

```R
# Define Weibull parameters for diameter distribution
# The 3-parameter Weibull distribution: f(x) = (k/λ) * ((x-θ)/λ)^(k-1) * exp(-((x-θ)/λ)^k)
DBHWeibull <- list(
  shape = 2.5,      # k: Shape parameter (controls distribution shape)
  scale = 15.0,     # λ: Scale parameter (controls spread)
  location = 5.0    # θ: Location parameter (minimum diameter in cm)
)

# Run advanced reconstruction
result <- reconstruct_pattern(
  CEtarget = CEtarget,
  SPPtarget = SPPtarget,
  HtAttrs = HtAttrs,
  Density = Density,
  DBHWeibull = DBHWeibull,      # Add diameter distribution
  xmax = 100,
  ymax = 100,
  plotUpdateInterval = 500,
  maxSimSteps = 10000,
  densityWeight = 2.0,           # Weight for density matching (default: 1.0)
  dbhWeight = 1.5                # Weight for DBH distribution matching (default: 1.0)
)
```

## Parameters

### Required Parameters
- **CEtarget**: Target Clark-Evans index (numeric)
- **SPPtarget**: Named vector of species proportions (must sum to 1.0)
- **HtAttrs**: List with `mean` and `sd` for tree heights
- **Density**: Target density in trees per hectare (numeric)

### Optional Parameters
- **DBHWeibull**: List with 3-parameter Weibull parameters (`shape`, `scale`, `location`) for diameter distribution (default: NULL)
- **xmax**: Plot width in meters (default: 100)
- **ymax**: Plot height in meters (default: 100)
- **maxSimSteps**: Maximum number of simulated annealing iterations (default: 200000)
- **coolingFactor**: Temperature reduction factor (default: 0.9)
- **energyAim**: Target energy for convergence (default: 5E-15)
- **plotUpdateInterval**: Iterations between plot updates (default: 100)
- **densityWeight**: Weight for density matching in energy function (default: 1.0)
- **dbhWeight**: Weight for DBH distribution matching (default: 1.0)
- **minPoints**: Minimum number of points to maintain during optimization (default: 10)

## Output

The function returns a list with three components:

1. **pattern**: A `spatstat` point pattern object (ppp) with spatial coordinates and marks
2. **data**: A `data.table` with columns:
   - `Number`: Tree ID
   - `x`, `y`: Spatial coordinates
   - `Species`: Species identifier
   - `Height`: Tree height
   - `DBH`: Diameter at breast height
3. **plotData**: A `data.table` tracking convergence metrics over iterations

## Performance Notes

### Improvements Over Original Version

1. **Nearest Neighbor Search**: O(n²) complexity remains but with:
   - Priority queue-based tracking (more cache-friendly)
   - Reduced memory allocations
   - Better locality of reference

2. **Memory Management**: 
   - Replaced variable-length arrays with std::vector
   - More efficient distance tracking

3. **Density Control**:
   - Direct trees-per-hectare specification
   - Explicit optimization target (no Poisson variation)
   - Better convergence to exact density

4. **Distribution Matching**:
   - Fast Weibull parameter estimation
   - KS-statistic based distribution comparison
   - Flexible weight control

### Typical Performance
- For 100×100m plots with 250 trees/ha: ~10-30 seconds for 10000 iterations
- Convergence typically achieved in 5000-20000 iterations depending on target complexity
- Adding DBH distribution increases runtime by ~20-30%

## Algorithm Details

The reconstruction uses simulated annealing with three types of moves:
1. **Remove** a point (with minimum count protection)
2. **Add** a new point
3. **Modify** an existing point's attributes

Energy function combines:
- Clark-Evans index deviation
- Species proportion deviations
- Height statistics deviations  
- Density deviation (NEW)
- Weibull distribution parameter deviations (NEW)

Weights allow prioritization of different objectives.

## Citation

If you use this code in your research, please cite the original repository and mention the enhancements:

```
EmpericalPatternR: Enhanced spatial point pattern reconstruction with 
diameter distribution support and improved performance.
https://github.com/bi0m3trics/EmpericalPatternR
```

## References

- Illian, J., Penttinen, A., Stoyan, H., & Stoyan, D. (2008). Statistical Analysis and Modelling of Spatial Point Patterns. John Wiley & Sons.
- Clark, P. J., & Evans, F. C. (1954). Distance to nearest neighbor as a measure of spatial relationships in populations. Ecology, 35(4), 445-453.

## License

See LICENSE file for details.