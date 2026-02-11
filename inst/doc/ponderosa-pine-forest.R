## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----load---------------------------------------------------------------------
library(EmpiricalPatternR)

## ----allometric---------------------------------------------------------------
ponderosa_params <- get_ponderosa_allometric_params()

# Crown diameter model: ln(CD) = a + b*ln(DBH) + c*ln(H)
ponderosa_params$crown_diameter$PIPO

# Height model: H = 1.3 + a*(1 - exp(-b * DBH))
ponderosa_params$height$PIPO

# CBH method
ponderosa_params$cbh_method

## ----compare-allometry--------------------------------------------------------
test_dbh <- 40
test_sp  <- "PIPO"

# Default (P-J) parameters
pj_params <- get_default_allometric_params()
pj_h  <- calc_height(test_dbh, test_sp, pj_params)
pj_cr <- calc_crown_radius(test_dbh, pj_h, test_sp, pj_params)

# Ponderosa parameters
pp_h  <- calc_height(test_dbh, test_sp, ponderosa_params)
pp_cr <- calc_crown_radius(test_dbh, pp_h, test_sp, ponderosa_params)

cat(sprintf(
  "40 cm DBH Ponderosa Pine:\n  P-J equations:   Height = %.1f m, Crown radius = %.2f m\n  PP equations:    Height = %.1f m, Crown radius = %.2f m\n",
  pj_h, pj_cr, pp_h, pp_cr
))

## ----create-config------------------------------------------------------------
config <- create_config(
  name = "Ponderosa Pine Mixed-Conifer",
  targets = list(
    density_ha    = 450,
    species_props = c(PIPO = 0.70, PSME = 0.20, ABCO = 0.10),
    species_names = c("PIPO", "PSME", "ABCO"),
    mean_dbh      = 35.0,
    sd_dbh        = 12.0,
    mean_height   = 18.0,
    sd_height     = 6.0,
    canopy_cover  = 0.45,
    cfl           = 0.85,
    clark_evans_r = 1.4
  ),
  weights = list(
    ce           = 30,
    dbh_mean     = 15,
    dbh_sd       = 10,
    height_mean  = 10,
    height_sd    = 5,
    species      = 60,
    canopy_cover = 60,
    cfl          = 50,
    density      = 80,
    nurse_effect = 0
  ),
  simulation = list(
    plot_size       = 100,
    max_iterations  = 5000,
    temp_initial    = 0.01,
    temp_final      = 0.0001,
    cooling_rate    = 0.9999,
    plot_interval   = 500,
    verbose         = TRUE,
    enable_plotting = TRUE,
    nurse_distance  = 0,
    use_nurse_effect = FALSE,
    mortality_prop  = 0.10
  ),
  allometric_params = ponderosa_params
)

print_config(config)

## ----run-sim, eval = FALSE----------------------------------------------------
# set.seed(456)
# 
# result <- simulate_stand(
#   targets         = config$targets,
#   weights         = config$weights,
#   plot_size       = config$simulation$plot_size,
#   max_iterations  = config$simulation$max_iterations,
#   initial_temp    = config$simulation$temp_initial,
#   cooling_rate    = config$simulation$cooling_rate,
#   verbose         = TRUE,
#   plot_interval   = 500,
#   save_plots      = FALSE,
#   nurse_distance  = config$simulation$nurse_distance,
#   use_nurse_effect = config$simulation$use_nurse_effect,
#   mortality_prop  = config$simulation$mortality_prop
# )

## ----analyze, eval = FALSE----------------------------------------------------
# # Console summary
# print_simulation_summary(result)
# 
# # Comprehensive analysis with CSV and PDF output
# analyze_simulation_results(
#   result              = result,
#   targets             = config$targets,
#   prefix              = "ponderosa_forest",
#   save_plots          = TRUE,
#   nurse_distance_target = 0,
#   target_mortality    = config$simulation$mortality_prop * 100
# )

## ----young, eval = FALSE------------------------------------------------------
# config_young <- create_config(
#   name = "Dense Young Ponderosa",
#   targets = list(
#     density_ha    = 800,
#     species_props = c(PIPO = 1.0),
#     species_names = c("PIPO"),
#     mean_dbh      = 15.0, sd_dbh  = 5.0,
#     mean_height   = 8.0,  sd_height = 3.0,
#     canopy_cover  = 0.50,
#     cfl           = 0.60,
#     clark_evans_r = 1.0
#   )
# )

## ----old-growth, eval = FALSE-------------------------------------------------
# config_og <- create_config(
#   name = "Old-Growth Ponderosa",
#   targets = list(
#     density_ha    = 200,
#     species_props = c(PIPO = 0.60, PSME = 0.30, ABCO = 0.10),
#     species_names = c("PIPO", "PSME", "ABCO"),
#     mean_dbh      = 60.0, sd_dbh  = 25.0,
#     mean_height   = 28.0, sd_height = 10.0,
#     canopy_cover  = 0.40,
#     cfl           = 1.20,
#     clark_evans_r = 1.6
#   )
# )

