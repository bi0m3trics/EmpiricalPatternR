# Custom Simulation: custom_simulation
# Generated: %Y-%m-%d %H:%M:%S

library(EmpericalPatternR)

custom_simulation <- function() {
  targets <- list(
    density_ha = 500, species_props = c(SP1 = 0.6, SP2 = 0.4),
    species_names = c("SP1", "SP2"), mean_dbh = 25.0, sd_dbh = 10.0,
    mean_height = 8.0, sd_height = 3.0, canopy_cover = 0.5,
    cfl = 1.0, clark_evans_r = 1.0
  )
  weights <- list(ce = 10, dbh_mean = 5, dbh_sd = 5, height_mean = 5, 
                  height_sd = 5, species = 70, canopy_cover = 70,
                  cfl = 60, density = 70, nurse = 0)
  simulation <- list(plot_size = 100, max_iterations = 10000, 
                    temp_initial = 0.01, cooling_rate = 0.9999,
                    nurse_distance = 0, use_nurse_effect = FALSE,
                    mortality_prop = 0.15)
  list(name = "custom_simulation", targets = targets, weights = weights, simulation = simulation)
}

# config <- custom_simulation()

