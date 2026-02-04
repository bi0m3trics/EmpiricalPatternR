# ==============================================================================
# Configuration System for Forest Simulations
# ==============================================================================
#
# This file provides pre-built configurations and helper functions for creating
# custom simulation parameters. Users can:
#   1. Use pre-built configs (e.g., pj_huffman_2009())
#   2. Modify existing configs
#   3. Create custom configs from scratch
#
# ==============================================================================

#' Create Pinyon-Juniper Configuration (Huffman et al. 2009)
#' 
#' Pre-configured simulation parameters for pinyon-juniper woodland based on
#' Huffman et al. (2009) Control Treatment data from Fishlake National Forest, Utah.
#' 
#' @param density_ha Total tree density (trees/ha). Default: 927
#' @param canopy_cover Target canopy cover proportion (0-1). Default: 0.40
#' @param cfl Target canopy fuel load (kg/m^2). Default: 1.10
#' @param mean_dbh Target mean DBH (cm). Default: 20.5
#' @param max_iterations Maximum optimization iterations. Default: 10000
#' @param plot_interval Status update interval. Default: 1000
#' @param enable_plotting Show progress plots. Default: TRUE
#' 
#' @return List with components:
#' \describe{
#'   \item{targets}{Stand structure targets}
#'   \item{weights}{Optimization weights}
#'   \item{simulation}{Simulation control parameters}
#'   \item{allometric_params}{Allometric equation parameters}
#' }
#' 
#' @references
#'   Huffman, D.W., et al. (2009). Herbaceous vegetation control after thinning
#'   in southwestern ponderosa pine forests. Forest Ecology and Management.
#' 
#' @export
#' @examples
#' \donttest{
#' # Use default configuration
#' config <- pj_huffman_2009()
#' 
#' # Run simulation with extracted parameters
#' result <- simulate_stand(
#'   targets = config$targets,
#'   weights = config$weights,
#'   plot_size = config$simulation$plot_size,
#'   max_iterations = config$simulation$max_iterations,
#'   cooling_rate = config$simulation$cooling_rate
#' )
#' }
#' 
#' \dontrun{
#' # Modify specific parameters
#' config <- pj_huffman_2009(density_ha = 1000, cfl = 1.5)
#' 
#' # Access components
#' config$targets$density_ha
#' config$weights$canopy_cover
#' }
pj_huffman_2009 <- function(density_ha = 927,
                             canopy_cover = 0.40,
                             cfl = 1.10,
                             mean_dbh = 20.5,
                             max_iterations = 50000,
                             plot_interval = 1000,
                             enable_plotting = TRUE) {
  
  list(
    # Target stand structure from field data
    targets = list(
      density_ha = density_ha,
      species_props = c(PIED = 0.755, JUSO = 0.245),
      species_names = c("PIED", "JUSO"),
      mean_dbh = mean_dbh,
      sd_dbh = 8.5,
      mean_height = 6.5,
      sd_height = 2.5,
      canopy_cover = canopy_cover,
      cfl = cfl,
      clark_evans_r = 1.0
    ),
    
    # Optimization weights (0-100 scale)
    weights = list(
      ce = 10,              # Spatial pattern (emergent)
      dbh_mean = 2,         # Size metrics (emergent)
      dbh_sd = 2,
      height_mean = 1,
      height_sd = 1,
      species = 70,         # Species composition (HIGH)
      density = 70,         # Stand density (HIGH)
      canopy_cover = 70,    # Canopy cover (HIGH)
      cfl = 60,             # Fuel load (HIGH)
      nurse_effect = 5      # Spatial association (LOW)
    ),
    
    # Simulation control parameters
    simulation = list(
      plot_size = 20,                    # Plot size (m)
      max_iterations = max_iterations,
      temp_initial = 100,
      temp_final = 0.01,
      cooling_rate = 0.99995,
      plot_interval = plot_interval,
      verbose = TRUE,
      enable_plotting = enable_plotting,
      nurse_distance = 3.0,
      use_nurse_effect = TRUE,
      mortality_prop = 0.20
    ),
    
    # Allometric parameters (uses Reese + Miller equations)
    allometric_params = get_default_allometric_params()
  )
}

#' Create Custom Simulation Configuration
#' 
#' Build a custom simulation configuration with full control over all parameters.
#' This is a template function showing all available options.
#' 
#' @param name Configuration name for reference
#' @param targets List of target stand metrics
#' @param weights List of optimization weights
#' @param simulation List of simulation control parameters
#' @param allometric_params Allometric equation parameters
#' 
#' @return Configuration list
#' @export
#' @examples
#' # Create custom high-density pinyon woodland
#' my_config <- create_config(
#'   name = "High Density PJ",
#'   targets = list(
#'     density_ha = 1500,
#'     species_props = c(PIED = 0.90, JUSO = 0.10),
#'     species_names = c("PIED", "JUSO"),
#'     mean_dbh = 15.0,
#'     sd_dbh = 6.0,
#'     canopy_cover = 0.60,
#'     cfl = 1.5,
#'     clark_evans_r = 0.8
#'   )
#' )
create_config <- function(name = "Custom",
                          targets = NULL,
                          weights = NULL,
                          simulation = NULL,
                          allometric_params = NULL) {
  
  # Default targets (if not provided)
  if (is.null(targets)) {
    targets <- list(
      density_ha = 1000,
      species_props = c(PIED = 0.75, JUSO = 0.25),
      species_names = c("PIED", "JUSO"),
      mean_dbh = 20.0,
      sd_dbh = 8.0,
      mean_height = 6.0,
      sd_height = 2.0,
      canopy_cover = 0.40,
      cfl = 1.0,
      clark_evans_r = 1.0
    )
  }
  
  # Default weights (if not provided)
  if (is.null(weights)) {
    weights <- list(
      ce = 10,
      dbh_mean = 2,
      dbh_sd = 2,
      height_mean = 1,
      height_sd = 1,
      species = 70,
      density = 70,
      canopy_cover = 70,
      cfl = 60,
      nurse_effect = 5
    )
  }
  
  # Default simulation parameters (if not provided)
  if (is.null(simulation)) {
    simulation <- list(
      plot_size = 20,
      max_iterations = 10000,
      temp_initial = 100,
      temp_final = 0.01,
      cooling_rate = 0.9999,
      plot_interval = 1000,
      verbose = TRUE,
      enable_plotting = TRUE,
      nurse_distance = 3.0,
      use_nurse_effect = TRUE,
      mortality_prop = 0.20
    )
  }
  
  # Default allometric parameters (if not provided)
  if (is.null(allometric_params)) {
    allometric_params <- get_default_allometric_params()
  }
  
  list(
    name = name,
    targets = targets,
    weights = weights,
    simulation = simulation,
    allometric_params = allometric_params
  )
}

#' Print Configuration Summary
#' 
#' Display a formatted summary of simulation configuration.
#' 
#' @param config Configuration list from pj_huffman_2009() or create_config()
#' @export
#' @examples
#' config <- pj_huffman_2009()
#' print_config(config)
print_config <- function(config) {
  
  message(
    sprintf(
      paste0(
        "\n%s\n",
        "SIMULATION CONFIGURATION: %s\n",
        "%s\n"
      ),
      paste(rep("=", 72), collapse = ""),
      ifelse(is.null(config$name), "Default", config$name),
      paste(rep("=", 72), collapse = "")
    )
  )
  
  t <- config$targets
  message(
    sprintf(
      paste0(
        "TARGET METRICS:\n",
        "  Density:        %d trees/ha\n",
        "  Species:        %s\n",
        "  Mean DBH:       %.1f cm (SD = %.1f cm)\n",
        "  Canopy Cover:   %.1f%%\n",
        "  CFL:            %.2f kg/m^2\n",
        "  Spatial R:      %.2f\n"
      ),
      t$density_ha,
      paste(sprintf("%.1f%% %s", t$species_props * 100, names(t$species_props)), collapse = ", "),
      t$mean_dbh, t$sd_dbh,
      t$canopy_cover * 100,
      t$cfl,
      t$clark_evans_r
    )
  )
  
  w <- config$weights
  message(
    sprintf(
      paste0(
        "\nOPTIMIZATION WEIGHTS (0-100 scale):\n",
        "  Density:        %d (HIGH)\n",
        "  Species:        %d (HIGH)\n",
        "  Canopy Cover:   %d (HIGH)\n",
        "  CFL:            %d (HIGH)\n",
        "  Spatial R:      %d (emergent)\n"
      ),
      w$density, w$species, w$canopy_cover, w$cfl, w$ce
    )
  )
  
  s <- config$simulation
  message(
    sprintf(
      paste0(
        "\nSIMULATION SETTINGS:\n",
        "  Max Iterations: %d\n",
        "  Plot Size:      %.1f m\n",
        "  Plotting:       %s\n",
        "  Mortality:      %.1f%%\n"
      ),
      s$max_iterations,
      s$plot_size,
      ifelse(s$enable_plotting, "ENABLED", "DISABLED"),
      s$mortality_prop * 100
    )
  )
  
  message(
    sprintf(
      "%s\n",
      paste(rep("=", 72), collapse = "")
    )
  )
  
  invisible(config)
}

#' Validate Configuration
#' 
#' Check that configuration has all required components and valid values.
#' 
#' @param config Configuration list
#' @return TRUE if valid, otherwise stops with error message
#' @export
validate_config <- function(config) {
  
  # Check required components
  required <- c("targets", "weights", "simulation")
  missing <- setdiff(required, names(config))
  if (length(missing) > 0) {
    stop("Configuration missing required components: ", paste(missing, collapse = ", "))
  }
  
  # Check targets
  required_targets <- c("density_ha", "species_props", "species_names", 
                        "canopy_cover", "cfl")
  missing_targets <- setdiff(required_targets, names(config$targets))
  if (length(missing_targets) > 0) {
    stop("Targets missing required fields: ", paste(missing_targets, collapse = ", "))
  }
  
  # Validate ranges
  if (config$targets$density_ha <= 0) {
    stop("density_ha must be positive")
  }
  if (config$targets$canopy_cover < 0 || config$targets$canopy_cover > 1) {
    stop("canopy_cover must be between 0 and 1")
  }
  if (sum(config$targets$species_props) != 1.0) {
    warning("species_props do not sum to 1.0, normalizing...")
    config$targets$species_props <- config$targets$species_props / sum(config$targets$species_props)
  }
  
  # Check simulation parameters
  if (config$simulation$max_iterations <= 0) {
    stop("max_iterations must be positive")
  }
  if (config$simulation$plot_size <= 0) {
    stop("plot_size must be positive")
  }
  
  message("Configuration validated successfully")
  return(TRUE)
}

#' Export Configuration to File
#' 
#' Save configuration as R script for reproducibility.
#' 
#' @param config Configuration list
#' @param file Output file path (default: "simulation_config.R")
#' @export
#' @examples
#' config <- pj_huffman_2009(density_ha = 1000)
#' save_config(config, "my_simulation.R")
save_config <- function(config, file = "simulation_config.R") {
  
  # Create R script
  script <- paste0(
    "# Auto-generated simulation configuration\n",
    "# Created: ", Sys.time(), "\n\n",
    "library(EmpiricalPatternR)\n\n",
    "config <- ", deparse(config, width.cutoff = 70), "\n"
  )
  
  writeLines(script, file)
  message("Configuration saved to: ", file)
  
  invisible(config)
}

#' Generate Template Configuration File
#'
#' Creates an R script template with a custom simulation configuration that users
#' can edit. The template includes all required parameters with descriptions and
#' example values. This is useful for creating custom simulations.
#'
#' @param file Character, path to save the template file (default: "my_simulation_config.R")
#' @param config_name Character, name for the config function (default: "my_custom_config")
#' @param base_config Character, which config to use as starting point:
#'   "pj" for pinyon-juniper (default), or "custom" for blank template
#'
#' @return Invisibly returns the file path
#' @export
#'
#' @examples
#' \donttest{
#' # Generate a template based on P-J config
#' generate_config_template("my_pj_config.R", "my_pj_simulation")
#' 
#' # Generate a blank custom template
#' generate_config_template("custom_sim.R", "custom_simulation", base_config = "custom")
#' }
generate_config_template <- function(file = "my_simulation_config.R",
                                     config_name = "my_custom_config",
                                     base_config = c("pj", "custom")) {
  
  base_config <- match.arg(base_config)
  
  if (base_config == "pj") {
    # Template based on pinyon-juniper
    template <- sprintf('# ==============================================================================
# Custom Simulation Configuration: %s
# ==============================================================================
# This configuration was generated as a template. Edit the values below to
# customize your simulation parameters.
#
# Generated: %s
# ==============================================================================

library(EmpiricalPatternR)

# Custom Simulation Configuration
# @param density_ha Target tree density (trees per hectare)
# @param cfl Target canopy fuel load (kg/m²)
# @param canopy_cover Target canopy cover (proportion 0-1)
# @param max_iterations Maximum optimization iterations
# @param cooling_rate Cooling rate for simulated annealing (0-1)
# @return List containing targets, weights, and simulation parameters
%s <- function(density_ha = 927,
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
  
  list(name = "%s", targets = targets, weights = weights, simulation = simulation)
}

# Usage:
# config <- %s()
# result <- simulate_stand(config$targets, config$weights,
#                          plot_size = 100, max_iterations = 1000)
',
      config_name,
      format(Sys.time(), "%%Y-%%m-%%d %%H:%%M:%%S"),
      config_name, config_name, config_name
    )
  } else {
    # Blank custom template
    template <- sprintf('# Custom Simulation: %s
# Generated: %s

library(EmpiricalPatternR)

%s <- function() {
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
  list(name = "%s", targets = targets, weights = weights, simulation = simulation)
}

# config <- %s()
',
      config_name, format(Sys.time(), "%%Y-%%m-%%d %%H:%%M:%%S"),
      config_name, config_name, config_name
    )
  }
  
  writeLines(template, file)
  message(sprintf("Template created: %s\nEdit the file, then: source(\"%s\"); config <- %s()",
                  file, file, config_name))
  invisible(file)
}
