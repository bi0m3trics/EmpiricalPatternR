# ==============================================================================
# Example 2: Ponderosa Pine Forest with Custom Allometric Equations
# ==============================================================================
#
# This example demonstrates how to create custom configurations with:
#   1. Custom allometric parameters for different species
#   2. Different forest type targets (montane vs. woodland)
#   3. Larger trees with different crown structures
#   4. The create_config() function for flexible setup
#
# ==============================================================================

library(EmpiricalPatternR)

message(
  sprintf(
    "\n%s\n  EXAMPLE 2: Ponderosa Pine Forest Simulation\n  Demonstrating Custom Configuration & Allometric Equations\n%s\n",
    paste(rep("=", 72), collapse = ""),
    paste(rep("=", 72), collapse = "")
  )
)

# ==============================================================================
# STEP 1: Define Custom Allometric Parameters
# ==============================================================================
# For ponderosa pine, we use different allometric relationships than the
# default pinyon-juniper equations.

# Get ponderosa pine allometric parameters
ponderosa_params <- get_ponderosa_allometric_params()

message(
  sprintf(
    paste0(
      "Custom Allometric Parameters for Ponderosa Pine:\n\n",
      "Crown Radius (Reese equations):\n",
      "  PIPO: ln(CD) = %.3f + %.3f*ln(DBH) + %.3f*ln(H)\n",
      "  (Crown Diameter from DBH and Height)\n\n",
      "Height (Chapman-Richards):\n",
      "  PIPO: H = 1.3 + %.1f × (1 - exp(-%.4f × DBH))\n",
      "  (Maximum height: ~%.1f m)\n\n",
      "Foliage Mass (Miller equations):\n",
      "  PIPO: ln(Wf) = %.3f + %.3f*ln(DBH)\n"
    ),
    ponderosa_params$crown_radius$PIPO$a,
    ponderosa_params$crown_radius$PIPO$b,
    ponderosa_params$crown_radius$PIPO$c,
    ponderosa_params$height$PIPO$a,
    ponderosa_params$height$PIPO$b,
    1.3 + ponderosa_params$height$PIPO$a,
    ponderosa_params$foliage$PIPO$a,
    ponderosa_params$foliage$PIPO$b
  )
)

# ==============================================================================
# STEP 2: Create Custom Configuration for Ponderosa Pine
# ==============================================================================
# Use create_config() to build a custom configuration with ponderosa parameters

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
  
  # Optimization weights (higher for managed stands)
  weight_ce = 30,              # Moderate - managed spacing
  weight_dbh_mean = 15,
  weight_dbh_sd = 10,
  weight_height_mean = 10,
  weight_height_sd = 5,
  weight_species = 60,         # High - maintain species mix
  weight_canopy_cover = 60,
  weight_cfl = 50,
  weight_density = 80,         # Very high - target density critical
  weight_nurse = 0,            # No nurse effect for ponderosa
  
  # No nurse tree effect
  nurse_distance = 0,
  use_nurse_effect = FALSE,
  mortality_prop = 0.10        # 10% mortality
)

message(
  sprintf(
    paste0(
      "\nCustom Ponderosa Pine Configuration:\n",
      "  Density:        %d trees/ha (managed stand)\n",
      "  Species:        %.0f%% PIPO, %.0f%% PSME, %.0f%% ABCO\n",
      "  Mean DBH:       %.1f cm (larger trees)\n",
      "  Mean Height:    %.1f m (montane forest)\n",
      "  Canopy Cover:   %.0f%%\n",
      "  CFL:            %.2f kg/m²\n",
      "  Spatial R:      %.2f (regular spacing)\n",
      "  Iterations:     %d\n"
    ),
    config$targets$density_ha,
    config$targets$species_props[1] * 100,
    config$targets$species_props[2] * 100,
    config$targets$species_props[3] * 100,
    config$targets$mean_dbh,
    config$targets$mean_height,
    config$targets$canopy_cover * 100,
    config$targets$cfl,
    config$targets$clark_evans_r,
    config$simulation$max_iterations
  )
)

# ==============================================================================
# STEP 4: Run Simulation with Custom Allometrics
# ==============================================================================
# NOTE: The current version uses built-in allometric equations.
# To use custom equations, we would need to modify calc_tree_attributes()
# to accept an allometric_params argument. For now, this example demonstrates
# the workflow - the actual implementation would need that enhancement.

# ==============================================================================
# OPTIONAL: Enable/Disable Plotting
# ==============================================================================
# Set to TRUE to see optimization progress plots (default)
# Set to FALSE for faster execution without graphics

enable_plotting <- TRUE

message(
  sprintf(
    paste0(
      "Running simulation (5000 iterations)...\n",
      "Note: This uses default allometric equations.\n",
      "      Future versions will support custom allometric parameters.\n",
      "      %s\n"
    ),
    if (enable_plotting) "Live plotting ENABLED - progress plots will be displayed."
    else "Live plotting DISABLED - faster execution."
  )
)

# ==============================================================================
# STEP 3: Run Simulation
# ==============================================================================

message("\nStarting ponderosa pine simulation...")
message("  Note: Using default allometric equations")
message("  (Custom equation integration is a planned enhancement)\n")

set.seed(456)  # Different seed than Example 1
start_time <- Sys.time()

result <- simulate_stand(
  targets = config$targets,
  weights = config$weights,
  plot_size = config$simulation$plot_size,
  max_iterations = config$simulation$max_iterations,
  initial_temp = config$simulation$temp_initial,
  cooling_rate = config$simulation$cooling_rate,
  verbose = TRUE,
  plot_interval = 500,
  save_plots = FALSE,
  nurse_distance = config$simulation$nurse_distance,
  use_nurse_effect = config$simulation$use_nurse_effect,
  mortality_prop = config$simulation$mortality_prop
)

end_time <- Sys.time()
runtime <- as.numeric(difftime(end_time, start_time, units = "mins"))

message(
  sprintf(
    "Simulation complete! (%.1f minutes)\n",
    runtime
  )
)

# ==============================================================================
# STEP 4: Analyze and Display Results
# ==============================================================================

analyze_simulation_results(
  result = result,
  targets = config$targets,
  prefix = "ponderosa_example",
  save_plots = TRUE,
  nurse_distance_target = 0,
  target_mortality = config$simulation$mortality_prop * 100
)

# ==============================================================================
# STEP 5: Demonstrating Custom Allometric Calculations
# ==============================================================================

message("\nDEMONSTRATING CUSTOM ALLOMETRIC EQUATIONS:\n")

# Example: Calculate crown radius for a 40cm DBH ponderosa pine
test_dbh <- 40
test_species <- "PIPO"

# Calculate height first (required for crown radius)
default_params <- get_default_allometric_params()
default_height <- calc_height(test_dbh, test_species, default_params)
default_radius <- calc_crown_radius(test_dbh, default_height, test_species, default_params)

# Using ponderosa pine equations
ponderosa_height <- calc_height(test_dbh, test_species, ponderosa_params)
ponderosa_radius <- calc_crown_radius(test_dbh, ponderosa_height, test_species, ponderosa_params)

message(
  sprintf(
    paste0(
      "For a %.0f cm DBH %s tree:\n",
      "  Default (P-J) equations:  Crown radius = %.2f m\n",
      "  Ponderosa equations:      Crown radius = %.2f m\n",
      "  Difference:               %.2f m (%.1f%% larger)\n"
    ),
    test_dbh, test_species,
    default_radius,
    ponderosa_radius,
    ponderosa_radius - default_radius,
    (ponderosa_radius / default_radius - 1) * 100
  )
)

# Height comparison
ponderosa_height <- calc_height(test_dbh, test_species, ponderosa_params)

message(
  sprintf(
    paste0(
      "  Default (P-J) height:     %.1f m\n",
      "  Ponderosa height:         %.1f m\n",
      "  Difference:               %.1f m (%.1f%% taller)\n\n",
      "NOTE: To fully integrate custom allometric equations into the simulation,\n",
      "      calc_tree_attributes() would need to accept an allometric_params\n",
      "      argument. This is a planned enhancement for future versions.\n\n",
      "      Current simulation uses default equations, but this example shows\n",
      "      how custom equations can be applied post-hoc or in custom workflows.\n"
    ),
    default_height, ponderosa_height,
    ponderosa_height - default_height,
    (ponderosa_height / default_height - 1) * 100
  )
)

message(
  paste0(
    "\nFILES SAVED:\n",
    "  ponderosa_example_all_trees.csv     - All trees\n",
    "  ponderosa_example_live_trees.csv    - Live trees\n",
    "  ponderosa_example_history.csv       - Convergence\n",
    "  ponderosa_example_summary.csv       - Summary stats\n",
    "  ponderosa_example_plots.pdf         - Plots\n\n",
    "See ?create_config, ?get_ponderosa_allometric_params,\n",
    "    ?simulate_stand, and ?analyze_simulation_results\n"
  )
)
