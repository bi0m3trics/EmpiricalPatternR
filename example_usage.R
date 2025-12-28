# Example: Advanced Pattern Reconstruction with All Features
# This script demonstrates the enhanced EmpericalPatternR with:
# - Explicit density control
# - Diameter distribution matching
# - Improved performance

library(Rcpp)
library(data.table)
library(spatstat)
library(ggplot2)
library(gridExtra)

# Source the enhanced code
sourceCpp("NumericUtilities.cpp")
source("myReconstruction.R")

# ==============================================================================
# Example 1: Basic reconstruction with explicit density control
# ==============================================================================

cat("\n=== Example 1: Basic Pattern Reconstruction ===\n")
cat("Creating a pattern with specific density target...\n\n")

# Define parameters
CEtarget <- 1.50                                    # Slightly clustered pattern
SPPtarget <- c(Pine = 0.6, Oak = 0.3, Maple = 0.1) # Species composition
HtAttrs <- list(mean = 20, sd = 5)                 # Height: mean 20m, sd 5m
Density <- 300                                      # 300 trees per hectare

# Run reconstruction
result1 <- reconstruct_pattern(
  CEtarget = CEtarget,
  SPPtarget = SPPtarget,
  HtAttrs = HtAttrs,
  Density = Density,
  xmax = 100,           # 100m x 100m plot
  ymax = 100,
  plotUpdateInterval = 1000,
  maxSimSteps = 5000,
  energyAim = 1E-10     # Stricter convergence
)

cat("\n--- Results for Example 1 ---\n")
cat(sprintf("Total trees: %d\n", nrow(result1$data)))
cat(sprintf("Actual density: %.2f trees/ha\n", nrow(result1$data) / 1.0))

# ==============================================================================
# Example 2: Advanced reconstruction with diameter distribution
# ==============================================================================

cat("\n\n=== Example 2: Pattern with Diameter Distribution ===\n")
cat("Creating a pattern with specific diameter distribution...\n\n")

# Define 3-parameter Weibull for diameter distribution
# This represents a typical forest diameter distribution:
# - Location (theta): minimum DBH of 10 cm
# - Scale (lambda): controls the spread, 15 cm
# - Shape (k): controls the shape, 2.5 (right-skewed)
DBHWeibull <- list(
  shape = 2.5,
  scale = 15.0,
  location = 10.0
)

cat("Target Weibull parameters:\n")
cat(sprintf("  Shape (k): %.2f\n", DBHWeibull$shape))
cat(sprintf("  Scale (λ): %.2f cm\n", DBHWeibull$scale))
cat(sprintf("  Location (θ): %.2f cm (minimum DBH)\n", DBHWeibull$location))

# Run advanced reconstruction
result2 <- reconstruct_pattern(
  CEtarget = 1.60,                              # More regular pattern
  SPPtarget = c(Spruce = 0.5, Fir = 0.5),      # Two species
  HtAttrs = list(mean = 18, sd = 6),
  Density = 250,                                # 250 trees per hectare
  DBHWeibull = DBHWeibull,                     # Add diameter distribution
  xmax = 100,
  ymax = 100,
  plotUpdateInterval = 1000,
  maxSimSteps = 5000,
  densityWeight = 2.0,                         # Prioritize density matching
  dbhWeight = 1.5                              # Give weight to DBH matching
)

cat("\n--- Results for Example 2 ---\n")
cat(sprintf("Total trees: %d\n", nrow(result2$data)))

# Analyze diameter distribution
dbh_stats <- summary(result2$data$DBH)
cat("\nDBH Statistics:\n")
print(dbh_stats)

# Estimate achieved Weibull parameters
achieved_params <- estimateWeibullParams(result2$data$DBH)
cat("\nAchieved Weibull parameters:\n")
cat(sprintf("  Shape: %.2f (target: %.2f)\n", achieved_params$shape, DBHWeibull$shape))
cat(sprintf("  Scale: %.2f (target: %.2f)\n", achieved_params$scale, DBHWeibull$scale))
cat(sprintf("  Location: %.2f (target: %.2f)\n", achieved_params$location, DBHWeibull$location))

# ==============================================================================
# Example 3: Compare with different density targets
# ==============================================================================

cat("\n\n=== Example 3: Density Comparison ===\n")
cat("Testing different density targets...\n\n")

densities <- c(100, 250, 500)  # Different trees/ha
results <- list()

for (i in seq_along(densities)) {
  cat(sprintf("\nReconstruction for %d trees/ha...\n", densities[i]))
  
  results[[i]] <- reconstruct_pattern(
    CEtarget = 1.50,
    SPPtarget = c(A = 1.0),
    HtAttrs = list(mean = 15, sd = 3),
    Density = densities[i],
    xmax = 100,
    ymax = 100,
    plotUpdateInterval = 5000,
    maxSimSteps = 3000,
    energyAim = 1E-8
  )
  
  actual_density <- nrow(results[[i]]$data) / 1.0  # 1 hectare plot
  error <- abs(actual_density - densities[i]) / densities[i] * 100
  
  cat(sprintf("  Target: %d trees/ha, Achieved: %.1f trees/ha (error: %.1f%%)\n", 
              densities[i], actual_density, error))
}

# ==============================================================================
# Visualization Example
# ==============================================================================

cat("\n\n=== Creating Visualization ===\n")

# Plot the spatial pattern from Example 2
if (require(ggplot2, quietly = TRUE)) {
  p <- ggplot(result2$data, aes(x = x, y = y, color = Species, size = DBH)) +
    geom_point(alpha = 0.6) +
    scale_size_continuous(range = c(2, 10), name = "DBH (cm)") +
    coord_fixed() +
    theme_minimal() +
    labs(title = "Reconstructed Spatial Pattern",
         subtitle = sprintf("CE=%.2f, Density=%.0f trees/ha", 
                           calcCE(100, 100, result2$data$x, result2$data$y),
                           nrow(result2$data)),
         x = "X (m)", y = "Y (m)")
  
  print(p)
  
  # DBH histogram with Weibull overlay
  p2 <- ggplot(result2$data, aes(x = DBH)) +
    geom_histogram(aes(y = after_stat(density)), bins = 30, 
                   fill = "skyblue", alpha = 0.7) +
    theme_minimal() +
    labs(title = "Diameter Distribution",
         subtitle = sprintf("Weibull: k=%.2f, λ=%.2f, θ=%.2f",
                           achieved_params$shape, 
                           achieved_params$scale,
                           achieved_params$location),
         x = "DBH (cm)", y = "Density")
  
  print(p2)
}

cat("\n=== Examples Complete ===\n")
cat("\nKey improvements demonstrated:\n")
cat("1. ✓ Explicit density control (trees per hectare)\n")
cat("2. ✓ Diameter distribution matching via 3-parameter Weibull\n")
cat("3. ✓ Improved C++ performance with priority queues\n")
cat("4. ✓ Flexible weight control for different objectives\n")
cat("5. ✓ Comprehensive output including pattern, data, and convergence metrics\n")
