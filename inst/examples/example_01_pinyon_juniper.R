# ==============================================================================
# Example 1: Pinyon-Juniper Woodland Simulation
# Based on Huffman et al. (2009) Control Treatment Data
# ==============================================================================
#
# This example demonstrates the config system and simulation capabilities:
#   - Using pre-built configuration (pj_huffman_2009)
#   - Tree density and spatial pattern optimization
#   - Species composition (Pinyon pine vs. Utah juniper)
#   - Size structure (DBH and height distributions)
#   - Canopy cover and fuel load (CFL) for fire behavior modeling
#   - Nurse tree associations (pinyons near junipers)
#   - Post-disturbance mortality
#
# ==============================================================================

library(EmpiricalPatternR)

message(
  sprintf(
    "\n%s\n  EXAMPLE 1: Pinyon-Juniper Woodland Simulation\n  Based on Huffman et al. (2009) - Control Treatment 2007\n%s\n",
    paste(rep("=", 72), collapse = ""),
    paste(rep("=", 72), collapse = "")
  )
)

# ==============================================================================
# STEP 1: Use Pre-Built Configuration
# ==============================================================================
# The config system provides validated, ready-to-use configurations.
# This example uses the Huffman et al. (2009) pinyon-juniper data.

config <- pj_huffman_2009(
  density_ha = 927,
  cfl = 1.10,
  canopy_cover = 0.40,
  max_iterations = 10000
)

# Display configuration summary
print(config)

message(
  sprintf(
    paste0(
      "\nConfiguration Details:\n",
      "  Target Density:     %d trees/ha\n",
      "  Species:            %.1f%% PIED, %.1f%% JUSO\n",
      "  Canopy Cover:       %.1f%%\n",
      "  CFL:                %.2f kg/m²\n",
      "  Max Iterations:     %d\n",
      "  Nurse Effect:       %s (target: %.1f m)\n"
    ),
    config$targets$density_ha,
    config$targets$species_props[1] * 100,
    config$targets$species_props[2] * 100,
    config$targets$canopy_cover * 100,
    config$targets$cfl,
    config$simulation$max_iterations,
    ifelse(config$simulation$use_nurse_effect, "ENABLED", "DISABLED"),
    config$simulation$nurse_distance
  )
)

# ==============================================================================
# STEP 2: Run Simulation with Configuration
# ==============================================================================
# The config object contains all parameters needed for the simulation.

message("\nStarting simulation...")
message(sprintf("  Plot interval: %d iterations", 1000))

set.seed(123)  # For reproducibility
start_time <- Sys.time()

result <- simulate_stand(
  targets = config$targets,
  weights = config$weights,
  plot_size = config$simulation$plot_size,
  max_iterations = config$simulation$max_iterations,
  initial_temp = config$simulation$temp_initial,
  cooling_rate = config$simulation$cooling_rate,
  verbose = TRUE,
  plot_interval = 1000,
  save_plots = FALSE,
  nurse_distance = config$simulation$nurse_distance,
  use_nurse_effect = config$simulation$use_nurse_effect,
  mortality_prop = config$simulation$mortality_prop
)

end_time <- Sys.time()
runtime <- as.numeric(difftime(end_time, start_time, units = "mins"))

message(sprintf("Simulation complete! (%.1f minutes)\n", runtime))

# ==============================================================================
# STEP 3: Analyze and Display Results
# ==============================================================================

# Use comprehensive analysis function
analyze_simulation_results(
  result = result,
  targets = config$targets,
  prefix = "pj_example",
  save_plots = TRUE,
  nurse_distance_target = config$simulation$nurse_distance,
  target_mortality = config$simulation$mortality_prop * 100
)

# ==============================================================================
# STEP 4: Accessing Results
# ==============================================================================

message(
  paste0(
    "\nACCESSING RESULTS:\n\n",
    "The result object contains:\n",
    "  result$trees      - Final tree list with all attributes\n",
    "  result$history    - Optimization history (energy over time)\n",
    "  result$energy     - Final energy value\n\n",
    "Files saved:\n",
    "  pj_example_all_trees.csv     - All trees (live + dead)\n",
    "  pj_example_live_trees.csv    - Live trees only\n",
    "  pj_example_history.csv       - Convergence history\n",
    "  pj_example_summary.csv       - Summary statistics\n",
    "  pj_example_plots.pdf         - Spatial and size distributions\n\n",
    "See ?pj_huffman_2009, ?simulate_stand, and ?analyze_simulation_results\n"
  )
)
