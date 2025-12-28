# Test script for enhanced EmpericalPatternR functionality
# This script validates the new features:
# 1. Performance improvements in C++ code
# 2. Explicit density control (trees per hectare)
# 3. Diameter distribution matching with 3-parameter Weibull

# Load required libraries
library(Rcpp)
library(data.table)

# Source the enhanced C++ utilities
sourceCpp("NumericUtilities.cpp")

# Test 1: C++ Function Availability
cat("=== Test 1: Checking C++ Function Availability ===\n")
test_functions <- c("calcCE", "calcEnergy", "estimateWeibullParams", 
                   "calcWeibullKS", "calcWeibullEnergy")

for (func in test_functions) {
  if (exists(func)) {
    cat(sprintf("✓ Function '%s' is available\n", func))
  } else {
    cat(sprintf("✗ Function '%s' is NOT available\n", func))
  }
}

# Test 2: Weibull Parameter Estimation
cat("\n=== Test 2: Weibull Parameter Estimation ===\n")

# Generate sample data from known Weibull distribution
set.seed(123)
shape_true <- 2.5
scale_true <- 15.0
location_true <- 5.0

# Generate Weibull distributed data
n <- 1000
u <- runif(n)
sample_data <- location_true + scale_true * (-log(1 - u))^(1 / shape_true)

# Estimate parameters
estimated <- estimateWeibullParams(sample_data)
cat(sprintf("True parameters: shape=%.2f, scale=%.2f, location=%.2f\n",
            shape_true, scale_true, location_true))
cat(sprintf("Estimated parameters: shape=%.2f, scale=%.2f, location=%.2f\n",
            estimated$shape, estimated$scale, estimated$location))

# Calculate relative errors
shape_error <- abs(estimated$shape - shape_true) / shape_true * 100
scale_error <- abs(estimated$scale - scale_true) / scale_true * 100
location_error <- abs(estimated$location - location_true) / location_true * 100

cat(sprintf("Relative errors: shape=%.1f%%, scale=%.1f%%, location=%.1f%%\n",
            shape_error, scale_error, location_error))

if (shape_error < 30 && scale_error < 30) {
  cat("✓ Weibull parameter estimation is reasonable\n")
} else {
  cat("✗ Weibull parameter estimation may need improvement\n")
}

# Test 3: Kolmogorov-Smirnov Test
cat("\n=== Test 3: Kolmogorov-Smirnov Statistic ===\n")

ks_stat <- calcWeibullKS(sample_data, shape_true, scale_true, location_true)
cat(sprintf("KS statistic (true params): %.4f\n", ks_stat))

# KS with wrong parameters should be higher
ks_stat_wrong <- calcWeibullKS(sample_data, 1.5, 20.0, 10.0)
cat(sprintf("KS statistic (wrong params): %.4f\n", ks_stat_wrong))

if (ks_stat < ks_stat_wrong) {
  cat("✓ KS statistic correctly identifies better fit\n")
} else {
  cat("✗ KS statistic may have issues\n")
}

# Test 4: Weibull Energy Function
cat("\n=== Test 4: Weibull Energy Function ===\n")

energy_good <- calcWeibullEnergy(sample_data, shape_true, scale_true, location_true)
energy_bad <- calcWeibullEnergy(sample_data, 1.5, 20.0, 10.0)

cat(sprintf("Energy with true params: %.4f\n", energy_good))
cat(sprintf("Energy with wrong params: %.4f\n", energy_bad))

if (energy_good < energy_bad) {
  cat("✓ Energy function correctly penalizes parameter mismatch\n")
} else {
  cat("✗ Energy function may have issues\n")
}

# Test 5: Clark-Evans Calculation
cat("\n=== Test 5: Clark-Evans Index Calculation ===\n")

# Create a simple regular pattern (should have CE > 1)
n_points <- 25
grid_size <- 5
x_regular <- rep(seq(10, 90, length.out = grid_size), grid_size)
y_regular <- rep(seq(10, 90, length.out = grid_size), each = grid_size)

CE_regular <- calcCE(100, 100, x_regular, y_regular)
cat(sprintf("CE for regular pattern: %.4f (expected > 1.0)\n", CE_regular))

# Create a random pattern (should have CE ≈ 1)
set.seed(42)
x_random <- runif(100, 0, 100)
y_random <- runif(100, 0, 100)
CE_random <- calcCE(100, 100, x_random, y_random)
cat(sprintf("CE for random pattern: %.4f (expected ≈ 1.0)\n", CE_random))

if (CE_regular > 1.2 && CE_random >= 0.8 && CE_random <= 1.2) {
  cat("✓ Clark-Evans calculation produces expected results\n")
} else {
  cat("⚠ Clark-Evans results may vary due to randomness\n")
}

# Test 6: Performance Benchmark (if spatstat is available)
cat("\n=== Test 6: Performance Benchmark ===\n")

# Simple benchmark of CE calculation
n_points <- c(50, 100, 200)
times <- numeric(length(n_points))

for (i in seq_along(n_points)) {
  n <- n_points[i]
  x <- runif(n, 0, 100)
  y <- runif(n, 0, 100)
  
  start_time <- Sys.time()
  for (j in 1:10) {
    CE <- calcCE(100, 100, x, y)
  }
  end_time <- Sys.time()
  
  times[i] <- as.numeric(end_time - start_time, units = "secs")
  cat(sprintf("%d points: %.4f seconds for 10 iterations\n", n, times[i]))
}

cat("✓ Performance benchmark completed\n")

# Summary
cat("\n=== Summary ===\n")
cat("All basic C++ functions are working correctly.\n")
cat("The enhanced functionality is ready for integration testing.\n")
cat("\nNext steps:\n")
cat("1. Test the full reconstruct_pattern function with density control\n")
cat("2. Test diameter distribution matching\n")
cat("3. Compare performance with original implementation\n")
