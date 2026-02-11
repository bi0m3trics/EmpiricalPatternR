## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----load-package-------------------------------------------------------------
library(EmpiricalPatternR)

## ----config-------------------------------------------------------------------
config <- pj_huffman_2009(
  density_ha = 927,
  cfl = 1.10,
  canopy_cover = 0.40,
  max_iterations = 10000
)

# Display configuration summary
print_config(config)

## ----show-targets-------------------------------------------------------------
cat(sprintf(
  "  Density:        %d trees/ha\n  Species:        %.1f%% PIED, %.1f%% JUSO\n  Mean DBH:       %.1f cm\n  Canopy Cover:   %.0f%%\n  CFL:            %.2f kg/m²\n  Nurse Effect:   %s (target: %.1f m)\n",
  config$targets$density_ha,
  config$targets$species_props["PIED"] * 100,
  config$targets$species_props["JUSO"] * 100,
  config$targets$mean_dbh,
  config$targets$canopy_cover * 100,
  config$targets$cfl,
  ifelse(config$simulation$use_nurse_effect, "ENABLED", "DISABLED"),
  config$simulation$nurse_distance
))

## ----run-sim, eval = FALSE----------------------------------------------------
# set.seed(123)  # For reproducibility
# 
# result <- simulate_stand(
#   targets         = config$targets,
#   weights         = config$weights,
#   plot_size       = config$simulation$plot_size,
#   max_iterations  = config$simulation$max_iterations,
#   initial_temp    = config$simulation$temp_initial,
#   cooling_rate    = config$simulation$cooling_rate,
#   verbose         = TRUE,
#   plot_interval   = 1000,
#   save_plots      = FALSE,
#   nurse_distance  = config$simulation$nurse_distance,
#   use_nurse_effect = config$simulation$use_nurse_effect,
#   mortality_prop  = config$simulation$mortality_prop
# )

## ----analyze, eval = FALSE----------------------------------------------------
# analyze_simulation_results(
#   result              = result,
#   targets             = config$targets,
#   prefix              = "pj_woodland",
#   save_plots          = TRUE,
#   nurse_distance_target = config$simulation$nurse_distance,
#   target_mortality    = config$simulation$mortality_prop * 100
# )

## ----quick-viz, eval = FALSE--------------------------------------------------
# # Print summary to console
# print_simulation_summary(result)
# 
# # ggplot-based diagnostic panels
# plot_simulation_results(result)

## ----access, eval = FALSE-----------------------------------------------------
# # Final tree list with all attributes
# head(result$trees)
# 
# # Stand-level metrics
# result$metrics
# 
# # Optimization convergence history
# tail(result$history)
# 
# # Final energy value
# result$energy

## ----thin, eval = FALSE-------------------------------------------------------
# config_thin <- pj_huffman_2009(
#   density_ha     = 500,
#   canopy_cover   = 0.25,
#   cfl            = 0.60,
#   max_iterations = 10000
# )

## ----drought, eval = FALSE----------------------------------------------------
# config_drought <- pj_huffman_2009(density_ha = 927)
# # Override mortality in the simulation call:
# result_drought <- simulate_stand(
#   targets        = config_drought$targets,
#   weights        = config_drought$weights,
#   plot_size      = config_drought$simulation$plot_size,
#   max_iterations = config_drought$simulation$max_iterations,
#   mortality_prop = 0.30
# )

