# ==============================================================================
# Custom Simulation Configuration: my_pj_simulation
# ==============================================================================
# This configuration was generated as a template. Edit the values below to
# customize your simulation parameters.
#
# Generated: %Y-%m-%d %H:%M:%S
# ==============================================================================

library(EmpericalPatternR)

# Custom Simulation Configuration
# @param density_ha Target tree density (trees per hectare)
# @param cfl Target canopy fuel load (kg/m²)
# @param canopy_cover Target canopy cover (proportion 0-1)
# @param max_iterations Maximum optimization iterations
# @param cooling_rate Cooling rate for simulated annealing (0-1)
# @return List containing targets, weights, and simulation parameters
my_pj_simulation <- function(density_ha = 927,
                           cfl = 1.10,
                           canopy_cover = 0.40,
                           max_iterations = 50000,
                           cooling_rate = 0.99995) {
  
  # Target parameters
  targets <- list(
    density_ha = density_ha,
    species_props = c(PIED = 0.755, JUSO = 0.245),
    species_names = c("PIED", "JUSO"),
    mean_dbh = 20.5, sd_dbh = 8.5,
    mean_height = 6.5, sd_height = 2.5,
    canopy_cover = canopy_cover,
    cfl = cfl,
    clark_evans_r = 1.0
  )
  
  # Optimization weights (0-100 scale)
  weights <- list(
    ce = 10, dbh_mean = 2, dbh_sd = 2,
    height_mean = 1, height_sd = 1,
    species = 70, canopy_cover = 70,
    cfl = 60, density = 70, nurse = 5
  )
  
  # Simulation parameters
  simulation <- list(
    plot_size = 100,
    max_iterations = max_iterations,
    temp_initial = 0.01,
    cooling_rate = cooling_rate,
    nurse_distance = 2.5,
    use_nurse_effect = TRUE,
    mortality_prop = 0.2
  )
  
  list(name = "my_pj_simulation", targets = targets, weights = weights, simulation = simulation)
}

# Usage:
# config <- my_pj_simulation()
# result <- simulate_stand(config$targets, config$weights,
#                          plot_size = 100, max_iterations = 1000)

