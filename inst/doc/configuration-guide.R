## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----load---------------------------------------------------------------------
library(EmpiricalPatternR)

## ----prebuilt-----------------------------------------------------------------
config <- pj_huffman_2009()
print_config(config)

## ----prebuilt-custom----------------------------------------------------------
config <- pj_huffman_2009(
  density_ha     = 600,
  canopy_cover   = 0.30,
  cfl            = 0.80,
  max_iterations = 5000
)

## ----custom-config------------------------------------------------------------
my_config <- create_config(
  name = "My Custom Stand",
  targets = list(
    density_ha    = 500,
    species_props = c(SP1 = 0.60, SP2 = 0.40),
    species_names = c("SP1", "SP2"),
    mean_dbh      = 25.0,
    sd_dbh        = 10.0,
    mean_height   = 8.0,
    sd_height     = 3.0,
    canopy_cover  = 0.50,
    cfl           = 1.0,
    clark_evans_r = 1.0
  ),
  weights = list(
    ce           = 10,
    dbh_mean     = 5,
    dbh_sd       = 5,
    height_mean  = 5,
    height_sd    = 5,
    species      = 70,
    canopy_cover = 70,
    cfl          = 60,
    density      = 70,
    nurse_effect = 0
  ),
  simulation = list(
    plot_size        = 100,
    max_iterations   = 10000,
    temp_initial     = 100,
    temp_final       = 0.01,
    cooling_rate     = 0.9999,
    plot_interval    = 1000,
    verbose          = TRUE,
    enable_plotting  = TRUE,
    nurse_distance   = 0,
    use_nurse_effect = FALSE,
    mortality_prop   = 0.15
  )
)

## ----template, eval = FALSE---------------------------------------------------
# generate_config_template(
#   file        = "my_sim_config.R",
#   config_name = "my_custom_sim",
#   base_config = "pj"          # or "custom" for a blank slate
# )
# 
# # Then edit the file and:
# source("my_sim_config.R")
# config <- my_custom_sim()

## ----density-example----------------------------------------------------------
# 927 trees/ha on a 20 m × 20 m plot ≈ 37 trees
927 * (20^2) / 10000

## ----species-props------------------------------------------------------------
# Two species
c(PIED = 0.755, JUSO = 0.245)

# Three species
c(PIPO = 0.70, PSME = 0.20, ABCO = 0.10)

## ----weight-example-----------------------------------------------------------
# Weights for a managed ponderosa stand
list(
  ce = 30, dbh_mean = 15, dbh_sd = 10,
  height_mean = 10, height_sd = 5,
  species = 60, canopy_cover = 60,
  cfl = 50, density = 80,
  nurse_effect = 0
)

## ----cd-params----------------------------------------------------------------
params <- get_default_allometric_params()
params$crown_diameter$PIED

## ----ht-params----------------------------------------------------------------
params$height$PIED

## ----cbh-params---------------------------------------------------------------
params$cbh_method
params$cbh_reese$PIED

## ----foliage-params-----------------------------------------------------------
params$foliage_method
params$foliage_miller$PIED

## ----custom-species-----------------------------------------------------------
my_params <- get_default_allometric_params()

# Add a new species
my_params$crown_diameter$QUGA <- list(a = -0.3, b = 0.25, c = 0.40)
my_params$height$QUGA          <- list(a = 15, b = 0.035)
my_params$crown_ratio$QUGA     <- list(a = 0.70, b = 0.09)
my_params$crown_mass$QUGA      <- list(a = 0.18, b = 2.15)

# Use in a config
config <- create_config(
  name = "Gambel Oak Mix",
  targets = list(
    density_ha    = 800,
    species_props = c(PIED = 0.50, QUGA = 0.50),
    species_names = c("PIED", "QUGA"),
    mean_dbh = 18, sd_dbh = 7,
    mean_height = 6, sd_height = 2,
    canopy_cover = 0.55, cfl = 0.90,
    clark_evans_r = 0.9
  ),
  allometric_params = my_params
)

## ----validate-----------------------------------------------------------------
config <- pj_huffman_2009()
validate_config(config)

## ----save-rds, eval = FALSE---------------------------------------------------
# save_config(config, "my_config.R")

## ----gen-template, eval = FALSE-----------------------------------------------
# generate_config_template("my_template.R", "my_sim", base_config = "pj")
# # Edit the file, then source it

## ----quick-ref, echo = FALSE--------------------------------------------------
cat("
config <- create_config(
  name              = 'My Stand',
  targets = list(
    density_ha      = 500,
    species_props   = c(SP1 = 0.6, SP2 = 0.4),
    species_names   = c('SP1', 'SP2'),
    mean_dbh        = 25, sd_dbh = 10,
    mean_height     = 8,  sd_height = 3,
    canopy_cover    = 0.50,
    cfl             = 1.0,
    clark_evans_r   = 1.0
  ),
  weights = list(
    ce = 10, dbh_mean = 5, dbh_sd = 5,
    height_mean = 5, height_sd = 5,
    species = 70, canopy_cover = 70, cfl = 60,
    density = 70, nurse_effect = 0
  ),
  simulation = list(
    plot_size = 100, max_iterations = 10000,
    temp_initial = 100, temp_final = 0.01,
    cooling_rate = 0.9999, plot_interval = 1000,
    verbose = TRUE, enable_plotting = TRUE,
    nurse_distance = 0, use_nurse_effect = FALSE,
    mortality_prop = 0.15
  )
)
")

