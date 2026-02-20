#' @useDynLib EmpiricalPatternR, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @import data.table
#' @importFrom data.table :=
#' @import spatstat
#' @import ggplot2
NULL

# Make this file data.table-aware when sourced
.datatable.aware <- TRUE

# ==============================================================================
# Forest Stand Simulation with Simulated Annealing
# ==============================================================================
# This package simulates a marked point pattern of trees matching target:
# - Clark-Evans R (spatial pattern)
# - Mean canopy cover
# - Tree size distribution (DBH, height)
# - Species composition
# - Total canopy bulk density
# - Individual tree crown attributes (base height, radius, bulk density)
# ==============================================================================

# NOTE: Allometric equations (calc_height, calc_crown_radius, calc_crown_base_height,
#       calc_canopy_fuel_mass) are now in R/allometric_equations.R
# ==============================================================================

# ==============================================================================
# CANOPY COVER CALCULATION (with overlap removal)
# ==============================================================================

#' Calculate total canopy cover accounting for overlap
#'
#' Uses a raster approach (0.5 m resolution) to account for crown overlap.
#'
#' @param x Vector of x coordinates (m)
#' @param y Vector of y coordinates (m)
#' @param crown_radius Vector of crown radii (m)
#' @param plot_size Size of plot (assumes square, m)
#' @return Proportion of plot covered by canopy (0-1)
#' @export
#' @examples
#' # Small stand on a 20 m plot
#' x <- c(5, 10, 15)
#' y <- c(5, 10, 15)
#' cr <- c(2, 3, 2.5)
#' calc_canopy_cover(x, y, cr, plot_size = 20)
calc_canopy_cover <- function(x, y, crown_radius, plot_size = 100) {
  # Use a raster approach to account for overlap
  # Create a grid with 0.5m resolution
  grid_res <- 0.5
  n_cells <- ceiling(plot_size / grid_res)

  # Create coverage grid
  grid <- matrix(0, nrow = n_cells, ncol = n_cells)

  # For each tree, mark cells covered by its crown
  for (i in seq_along(x)) {
    # Calculate grid cells within crown radius
    x_min <- max(1, floor((x[i] - crown_radius[i]) / grid_res) + 1)
    x_max <- min(n_cells, ceiling((x[i] + crown_radius[i]) / grid_res))
    y_min <- max(1, floor((y[i] - crown_radius[i]) / grid_res) + 1)
    y_max <- min(n_cells, ceiling((y[i] + crown_radius[i]) / grid_res))

    # Check each cell in the bounding box
    for (xi in x_min:x_max) {
      for (yi in y_min:y_max) {
        # Cell center coordinates
        cell_x <- (xi - 0.5) * grid_res
        cell_y <- (yi - 0.5) * grid_res

        # Check if cell center is within crown radius
        dist <- sqrt((cell_x - x[i])^2 + (cell_y - y[i])^2)
        if (dist <= crown_radius[i]) {
          grid[yi, xi] <- 1
        }
      }
    }
  }

  # Calculate proportion of covered cells
  canopy_cover <- sum(grid) / (n_cells^2)
  return(canopy_cover)
}

# ==============================================================================
# TREE ATTRIBUTES CALCULATION
# ==============================================================================

#' Calculate all tree attributes from basic measurements
#'
#' Adds Height, CrownRadius, CrownDiameter, CrownArea, CrownBaseHeight,
#' CrownLength, and CanopyFuelMass columns to a tree data table.
#'
#' @param trees Data table with x, y, Species, DBH columns
#' @return Data table with all attributes added
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(
#'   Number = 1:3, x = c(5, 10, 15), y = c(5, 10, 15),
#'   Species = c("PIED", "JUMO", "PIED"), DBH = c(15, 20, 25)
#' )
#' result <- calc_tree_attributes(trees)
#' names(result)
calc_tree_attributes <- function(trees) {
  trees <- copy(trees)

  # Calculate height
  trees[, Height := calc_height(DBH, Species), by = seq_len(nrow(trees))]

  # Calculate crown radius (now requires height)
  trees[, CrownRadius := calc_crown_radius(DBH, Height, Species), by = seq_len(nrow(trees))]

  # Calculate crown diameter (assuming circular, so diameter = 2 * radius)
  trees[, CrownDiameter := 2 * CrownRadius]

  # Calculate crown area
  trees[, CrownArea := pi * CrownRadius^2]

  # Calculate crown base height
  trees[, CrownBaseHeight := calc_crown_base_height(DBH, Height, Species), by = seq_len(nrow(trees))]

  # Calculate crown length
  trees[, CrownLength := Height - CrownBaseHeight]

  # Calculate canopy fuel mass using Miller (1981) equations
  trees[, CanopyFuelMass := calc_canopy_fuel_mass(DBH, Species),
        by = seq_len(nrow(trees))]

  return(trees)
}

# ==============================================================================
# STAND-LEVEL METRICS
# ==============================================================================

#' Calculate all stand-level metrics
#'
#' Computes density, Clark-Evans R, DBH/height summaries, species composition,
#' canopy cover, canopy bulk density, crown fuel load, and canopy depth.
#'
#' @param trees Data table with all tree attributes (from \code{calc_tree_attributes})
#' @param plot_size Plot size (m)
#' @return List of metrics
#' @export
#' @examples
#' library(data.table)
#' set.seed(1)
#' trees <- data.table(
#'   Number = 1:10, x = runif(10, 0, 20), y = runif(10, 0, 20),
#'   Species = sample(c("PIED", "JUMO"), 10, replace = TRUE),
#'   DBH = pmax(rnorm(10, 20, 5), 5)
#' )
#' trees <- calc_tree_attributes(trees)
#' metrics <- calc_stand_metrics(trees, plot_size = 20)
#' metrics$density_ha
#' metrics$canopy_cover
calc_stand_metrics <- function(trees, plot_size = 100) {
  n_trees <- nrow(trees)
  plot_area_ha <- (plot_size^2) / 10000

  # Calculate canopy bulk density (kg/m^3)
  # CBD = total canopy fuel / canopy volume
  canopy_volume <- sum(trees$CrownArea * trees$CrownLength, na.rm = TRUE)
  cbd <- if (canopy_volume > 0) {
    sum(trees$CanopyFuelMass, na.rm = TRUE) / canopy_volume
  } else {
    0
  }

  # Crown fuel load (kg/m^2) = total fuel / plot area
  plot_area_m2 <- plot_size * plot_size
  cfl <- sum(trees$CanopyFuelMass, na.rm = TRUE) / plot_area_m2

  # Canopy depth
  canopy_depth <- if (n_trees > 0) {
    mean(trees$CrownLength, na.rm = TRUE)
  } else {
    0
  }

  metrics <- list(
    # Spatial pattern
    clark_evans_r = calcCE(plot_size, plot_size, trees$x, trees$y),

    # Tree size
    mean_dbh = mean(trees$DBH),
    sd_dbh = sd(trees$DBH),
    mean_height = mean(trees$Height),
    sd_height = sd(trees$Height),

    # Species composition
    species_props = as.vector(table(trees$Species) / n_trees),

    # Canopy cover
    canopy_cover = calc_canopy_cover(trees$x, trees$y, trees$CrownRadius, plot_size),

    # Crown fire metrics
    cbd = cbd,           # Canopy bulk density (kg/m^3)
    cbd_mean = cbd,      # Same as cbd for compatibility
    cfl = cfl,           # Crown fuel load (kg/m^2)
    canopy_depth = canopy_depth,  # Mean crown length (m)

    # Density
    density_ha = n_trees / plot_area_ha
  )

  return(metrics)
}

# ==============================================================================
# ENERGY FUNCTION (Objective Function)
# ==============================================================================

#' Calculate energy (deviation from targets)
#' @param metrics Current stand metrics
#' @param targets Target parameters
#' @param weights Weights for each component
#' @param trees Current trees (for nurse tree calc)
#' @param nurse_distance Target nurse tree distance
#' @param use_nurse_effect Whether to include nurse tree energy
#' @return Total energy (lower is better)
#'
#' All metrics are normalized to relative errors so weights range 0-100:
#'   0   = ignore this metric
#'   1-20  = low priority
#'   20-50 = moderate priority
#'   50-80 = high priority
#'   80-100 = critical (will dominate optimization)
calc_energy <- function(metrics, targets, weights, trees = NULL,
                        nurse_distance = 3.0, use_nurse_effect = TRUE) {
  energy <- 0

  # Clark-Evans R (normalized by target)
  ce_rel_error <- (metrics$clark_evans_r - targets$clark_evans_r) / targets$clark_evans_r
  energy <- energy + weights$ce * ce_rel_error^2

  # Mean DBH (normalized by target)
  dbh_mean_rel_error <- (metrics$mean_dbh - targets$mean_dbh) / targets$mean_dbh
  energy <- energy + weights$dbh_mean * dbh_mean_rel_error^2

  # SD DBH (normalized by mean DBH to avoid division by zero if target SD is zero)
  dbh_sd_rel_error <- (metrics$sd_dbh - targets$sd_dbh) / targets$mean_dbh
  energy <- energy + weights$dbh_sd * dbh_sd_rel_error^2

  # Mean Height (normalized by target)
  height_mean_rel_error <- (metrics$mean_height - targets$mean_height) / targets$mean_height
  energy <- energy + weights$height_mean * height_mean_rel_error^2

  # SD Height (normalized by mean height)
  height_sd_rel_error <- (metrics$sd_height - targets$sd_height) / targets$mean_height
  energy <- energy + weights$height_sd * height_sd_rel_error^2

  # Species composition (already 0-1 scale, sum of squared differences)
  spp_energy <- sum((metrics$species_props - targets$species_props)^2)
  energy <- energy + weights$species * spp_energy

  # Canopy cover (normalized by target, with floor to avoid div by zero)
  cover_rel_error <- (metrics$canopy_cover - targets$canopy_cover) / max(targets$canopy_cover, 0.1)
  energy <- energy + weights$canopy_cover * cover_rel_error^2

  # Canopy fuel load (normalized by target)
  cfl_rel_error <- (metrics$cfl - targets$cfl) / targets$cfl
  energy <- energy + weights$cfl * cfl_rel_error^2

  # Stand density (normalized by target to give relative error)
  if ("density" %in% names(weights)) {
    density_rel_error <- (metrics$density_ha - targets$density_ha) / targets$density_ha
    energy <- energy + weights$density * density_rel_error^2
  }

  # Nurse tree effect (already returns normalized 0-1 energy)
  if (use_nurse_effect && !is.null(trees) && "nurse" %in% names(weights)) {
    nurse_energy <- calc_nurse_tree_energy(trees, nurse_distance)
    energy <- energy + weights$nurse * nurse_energy
  }

  return(energy)
}

# ==============================================================================
# PERTURBATION OPERATIONS
# ==============================================================================

#' Move a random tree to a new location
#' @param trees data.table. Tree data
#' @param plot_size Numeric. Plot dimension (m)
#' @return data.table. Modified tree data
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(Number = 1:5, x = 1:5, y = 1:5,
#'                     Species = "PIED", DBH = rep(20, 5))
#' set.seed(1)
#' perturb_move(trees, plot_size = 20)
perturb_move <- function(trees, plot_size = 100) {
  idx <- sample(nrow(trees), 1)
  trees_new <- copy(trees)
  trees_new$x[idx] <- runif(1, 0, plot_size)
  trees_new$y[idx] <- runif(1, 0, plot_size)
  return(trees_new)
}

#' Change species of a random tree
#' @param trees data.table. Tree data
#' @param species_names Character vector. Available species codes
#' @param species_probs Numeric vector. Target species proportions
#' @return data.table. Modified tree data
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(Number = 1:5, x = 1:5, y = 1:5,
#'                     Species = "PIED", DBH = rep(20, 5))
#' set.seed(1)
#' perturb_species(trees, c("PIED", "JUSO"), c(0.7, 0.3))
perturb_species <- function(trees, species_names, species_probs) {
  idx <- sample(nrow(trees), 1)
  trees_new <- copy(trees)
  trees_new$Species[idx] <- sample(species_names, 1, prob = species_probs)
  return(trees_new)
}

#' Adjust DBH of a random tree
#' @param trees data.table. Tree data
#' @param dbh_sd_perturb Numeric. SD of DBH perturbation (cm)
#' @return data.table. Modified tree data
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(Number = 1:5, x = 1:5, y = 1:5,
#'                     Species = "PIED", DBH = rep(20, 5))
#' set.seed(1)
#' perturb_dbh(trees, dbh_sd_perturb = 3)
perturb_dbh <- function(trees, dbh_sd_perturb = 3) {
  idx <- sample(nrow(trees), 1)
  trees_new <- copy(trees)
  trees_new$DBH[idx] <- trees_new$DBH[idx] + rnorm(1, 0, dbh_sd_perturb)
  trees_new$DBH[idx] <- pmax(trees_new$DBH[idx], 5)  # Minimum 5cm
  return(trees_new)
}

#' Add a new tree
#' @param trees data.table. Tree data
#' @param plot_size Numeric. Plot dimension (m)
#' @param species_names Character vector. Available species
#' @param species_probs Numeric vector. Species proportions
#' @param dbh_mean Numeric. Mean DBH (cm)
#' @param dbh_sd Numeric. SD of DBH (cm)
#' @return data.table. Modified tree data
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(Number = 1:5, x = 1:5, y = 1:5,
#'                     Species = "PIED", DBH = rep(20, 5))
#' set.seed(1)
#' perturb_add(trees, 20, c("PIED", "JUSO"), c(0.7, 0.3), 20, 5)
perturb_add <- function(trees, plot_size, species_names, species_probs, dbh_mean, dbh_sd) {
  new_tree <- data.table(
    Number = max(trees$Number) + 1,
    x = runif(1, 0, plot_size),
    y = runif(1, 0, plot_size),
    Species = sample(species_names, 1, prob = species_probs),
    DBH = rnorm(1, dbh_mean, dbh_sd)
  )
  new_tree$DBH <- pmax(new_tree$DBH, 5)
  trees_new <- rbind(trees[, .(Number, x, y, Species, DBH)], new_tree)
  return(trees_new)
}

#' Remove a random tree
#' @param trees data.table. Tree data
#' @param min_trees Integer. Minimum trees to maintain
#' @return data.table. Modified tree data
#' @export
#' @examples
#' library(data.table)
#' trees <- data.table(Number = 1:10, x = runif(10), y = runif(10),
#'                     Species = "PIED", DBH = rep(20, 10))
#' set.seed(1)
#' nrow(perturb_remove(trees, min_trees = 5))  # 9
perturb_remove <- function(trees, min_trees = 10) {
  if (nrow(trees) <= min_trees) return(trees)
  idx <- sample(nrow(trees), 1)
  trees_new <- copy(trees)
  trees_new <- trees_new[-idx]
  return(trees_new)
}

# ==============================================================================
# NURSE TREE EFFECT FUNCTIONS
# ==============================================================================

#' Calculate Nurse Tree Association Energy
#'
#' Calculates deviation from target nurse tree associations. In pinyon-juniper
#' ecosystems, pinyon pines (PIED) often establish near junipers (JUMO/JUSO)
#' which act as "nurse trees" providing shade and protection. This function
#' quantifies how well the current tree pattern matches this association.
#'
#' @param trees Data.table with columns: x, y, Species
#' @param nurse_distance Numeric. Target mean distance from PIED to nearest
#'   juniper (m). Default 3.0m based on field observations.
#' @return Numeric. Energy value representing squared deviation from target
#'   distance. Lower values indicate better match to target association pattern.
#' @details
#' For each PIED tree, calculates distance to nearest JUMO or JUSO tree.
#' Returns squared deviation of mean distance from target. Returns 0 if
#' either species is absent.
#' @export
#' @examples
#' library(data.table)
#' set.seed(1)
#' trees <- data.table(x = runif(50, 0, 20), y = runif(50, 0, 20),
#'                     Species = sample(c("PIED", "JUSO"), 50, replace = TRUE))
#' calc_nurse_tree_energy(trees, nurse_distance = 3.0)
calc_nurse_tree_energy <- function(trees, nurse_distance = 3.0) {
  pied_trees <- trees[Species == "PIED"]
  juxx_trees <- trees[Species %in% c("JUMO", "JUSO")]

  if (nrow(pied_trees) == 0 || nrow(juxx_trees) == 0) {
    return(0)  # No energy if one species missing
  }

  # For each PIED, find distance to nearest juniper
  distances <- numeric(nrow(pied_trees))
  for (i in seq_len(nrow(pied_trees))) {
    dx <- juxx_trees$x - pied_trees$x[i]
    dy <- juxx_trees$y - pied_trees$y[i]
    dist_to_junipers <- sqrt(dx^2 + dy^2)
    distances[i] <- min(dist_to_junipers)
  }

  # Energy is deviation from target mean distance
  mean_dist <- mean(distances)
  energy <- (mean_dist - nurse_distance)^2

  return(energy)
}

#' Add Tree with Nurse Tree Effect
#'
#' Adds a new tree to the stand. If adding a pinyon pine (PIED), places it
#' near an existing juniper to reflect nurse tree facilitation. Other species
#' are placed randomly.
#'
#' @param trees Data.table. Current tree data
#' @param plot_size Numeric. Plot dimension in meters
#' @param species_names Character vector. Available species codes
#' @param species_probs Numeric vector. Target species proportions (must sum to 1)
#' @param dbh_mean Numeric. Mean DBH for new tree (cm)
#' @param dbh_sd Numeric. Standard deviation of DBH (cm)
#' @param nurse_distance Numeric. Target distance to place PIED near juniper (m).
#'   Actual distance is drawn from normal distribution with mean = nurse_distance
#'   and SD = 0.3 * nurse_distance.
#' @return Data.table. Updated tree data with new tree added
#' @details
#' New tree species is selected based on species_probs. If PIED is selected
#' and junipers exist, tree is placed at distance ~ N(nurse_distance, 0.3*nurse_distance)
#' from a randomly selected juniper. Position is constrained within plot bounds.
#' DBH is drawn from N(dbh_mean, dbh_sd) and constrained to minimum 5cm.
#' @export
#' @examples
#' library(data.table)
#' set.seed(1)
#' trees <- data.table(Number = 1:10, x = runif(10, 0, 20),
#'                     y = runif(10, 0, 20),
#'                     Species = sample(c("PIED", "JUSO"), 10, replace = TRUE),
#'                     DBH = pmax(rnorm(10, 20, 5), 5))
#' trees_new <- perturb_add_with_nurse(trees, 20, c("PIED", "JUSO"),
#'                                     c(0.7, 0.3), 20, 5, 2.5)
#' nrow(trees_new)  # nrow(trees) + 1
perturb_add_with_nurse <- function(trees, plot_size, species_names, species_probs,
                                   dbh_mean, dbh_sd, nurse_distance = 3.0) {
  # Decide which species to add
  new_species <- sample(species_names, 1, prob = species_probs)

  # If adding PIED and junipers exist, place near a juniper
  if (new_species == "PIED") {
    juxx_trees <- trees[Species %in% c("JUMO", "JUSO")]
    if (nrow(juxx_trees) > 0) {
      # Pick a random juniper
      nurse_idx <- sample(nrow(juxx_trees), 1)
      nurse_x <- juxx_trees$x[nurse_idx]
      nurse_y <- juxx_trees$y[nurse_idx]

      # Place new PIED nearby (random angle, distance ~ nurse_distance)
      angle <- runif(1, 0, 2 * pi)
      dist <- rnorm(1, nurse_distance, nurse_distance * 0.3)
      dist <- pmax(dist, 0.5)  # Minimum 0.5m away

      new_x <- nurse_x + dist * cos(angle)
      new_y <- nurse_y + dist * sin(angle)

      # Keep within plot bounds
      new_x <- pmax(0, pmin(plot_size, new_x))
      new_y <- pmax(0, pmin(plot_size, new_y))
    } else {
      # No junipers, place randomly
      new_x <- runif(1, 0, plot_size)
      new_y <- runif(1, 0, plot_size)
    }
  } else {
    # Juniper - place randomly
    new_x <- runif(1, 0, plot_size)
    new_y <- runif(1, 0, plot_size)
  }

  new_tree <- data.table(
    Number = max(trees$Number) + 1,
    x = new_x,
    y = new_y,
    Species = new_species,
    DBH = rnorm(1, dbh_mean, dbh_sd)
  )
  new_tree$DBH <- pmax(new_tree$DBH, 5)
  trees_new <- rbind(trees[, .(Number, x, y, Species, DBH)], new_tree)
  return(trees_new)
}

# ==============================================================================
# MORTALITY SIMULATION
# ==============================================================================

#' Calculate Size-Dependent Mortality Probability
#'
#' Calculates mortality probability for each tree based on size (DBH) using
#' negative exponential relationships. Smaller trees have higher mortality.
#'
#' @param trees Data.table with columns: DBH (cm), Species
#' @param mort_params List. Species-specific mortality parameters with structure:
#'   list(SPECIES = list(base = ..., size_effect = ..., dbh_coef = ...))
#'   Default parameters favor mortality of small trees:
#'   - PIED: base=0.05, size_effect=0.45, dbh_coef=0.08
#'   - JUMO: base=0.04, size_effect=0.40, dbh_coef=0.07
#'   - JUSO: base=0.04, size_effect=0.40, dbh_coef=0.07
#' @return Numeric vector. Mortality probability for each tree (0-1)
#' @details
#' Mortality probability calculated as:
#' P(mortality) = base + size_effect * exp(-dbh_coef * DBH)
#'
#' This creates decreasing mortality with increasing DBH:
#' - Small trees (DBH < 10cm): High probability (0.3-0.5)
#' - Medium trees (DBH 10-30cm): Moderate probability (0.1-0.3)
#' - Large trees (DBH > 30cm): Low probability (0.05-0.15)
#'
#' Probabilities are constrained to [0, 1].
#' @export
#' @examples
#' trees <- data.frame(DBH = c(5, 15, 25, 35),
#'                     Species = c("PIED", "PIED", "JUSO", "JUSO"))
#' calc_mortality_probability(trees)
calc_mortality_probability <- function(trees, mort_params = NULL) {
  if (is.null(mort_params)) {
    # Default parameters: smaller trees more likely to die
    # Probability = base + size_effect * exp(-dbh_coef * DBH)
    mort_params <- list(
      PIED = list(base = 0.05, size_effect = 0.45, dbh_coef = 0.08),
      JUMO = list(base = 0.04, size_effect = 0.40, dbh_coef = 0.07),
      JUSO = list(base = 0.04, size_effect = 0.40, dbh_coef = 0.07)
    )
  }

  prob <- numeric(nrow(trees))
  for (i in seq_len(nrow(trees))) {
    spp <- trees$Species[i]
    dbh <- trees$DBH[i]

    if (spp %in% names(mort_params)) {
      p <- mort_params[[spp]]
      prob[i] <- p$base + p$size_effect * exp(-p$dbh_coef * dbh)
    } else {
      prob[i] <- 0.1  # Default 10% if species unknown
    }
  }

  # Constrain to [0, 1]
  prob <- pmax(0, pmin(1, prob))
  return(prob)
}

#' Simulate Post-Disturbance Mortality
#'
#' Simulates a mortality event (fire, drought, insects, disease) by assigning
#' mortality status to trees based on size-dependent probabilities. Achieves
#' a target proportion of dead trees by preferentially killing trees with
#' higher mortality risk.
#'
#' @param trees Data.table. Tree data with all attributes
#' @param target_mortality_prop Numeric. Proportion of trees to kill (0-1).
#'   Default 0.15 (15% mortality). Common values:
#'   - 0.05-0.15: Low intensity disturbance
#'   - 0.15-0.30: Moderate intensity disturbance
#'   - 0.30-0.60: High intensity disturbance
#'   - 0.60-0.90: Stand-replacing disturbance
#' @param mort_params List. Species-specific mortality parameters passed to
#'   \code{\link{calc_mortality_probability}}. NULL uses defaults.
#' @return Data.table. Input trees with added columns:
#'   \describe{
#'     \item{MortalityProbability}{Numeric. Calculated probability (0-1)}
#'     \item{Status}{Character. "live" or "dead"}
#'   }
#' @details
#' Process:
#' 1. Calculate mortality probability for each tree using size-dependent model
#' 2. Sort trees by probability (highest risk first)
#' 3. Mark top N trees as dead where N = target_mortality_prop * total_trees
#' 4. Mark remaining trees as live
#'
#' This approach ensures:
#' - Exact target mortality proportion is achieved
#' - Smaller trees preferentially killed (realistic)
#' - Deterministic given the same input (reproducible)
#' @export
#' @seealso \code{\link{calc_mortality_probability}}
#' @examples
#' library(data.table)
#' set.seed(1)
#' trees <- data.table(
#'   Number = 1:20, x = runif(20, 0, 20), y = runif(20, 0, 20),
#'   Species = sample(c("PIED", "JUMO"), 20, replace = TRUE),
#'   DBH = pmax(rnorm(20, 20, 5), 5)
#' )
#' trees <- calc_tree_attributes(trees)
#' result <- simulate_mortality(trees, target_mortality_prop = 0.20)
#' table(result$Status)
simulate_mortality <- function(trees, target_mortality_prop = 0.15, mort_params = NULL) {
  trees <- copy(trees)

  # Calculate mortality probability for each tree
  mort_prob <- calc_mortality_probability(trees[, .(DBH, Species)], mort_params)
  trees[, MortalityProbability := mort_prob]

  # Determine number of trees to kill
  n_dead <- round(nrow(trees) * target_mortality_prop)

  if (n_dead == 0) {
    trees[, Status := "live"]
    return(trees)
  }

  # Sort trees by mortality probability (highest first)
  trees[, TreeID := seq_len(.N)]
  setorder(trees, -MortalityProbability)

  # Mark top n_dead trees as dead
  trees[, Status := "live"]
  trees[1:n_dead, Status := "dead"]

  # Restore original order
  setorder(trees, TreeID)
  trees[, TreeID := NULL]

  return(trees)
}

# ==============================================================================
# SIMULATED ANNEALING MAIN FUNCTION
# ==============================================================================

#' Simulate Forest Stand with Simulated Annealing
#'
#' Run complete stand simulation to match empirical targets using simulated
#' annealing optimization. Optimizes spatial pattern, species composition,
#' size structure, and fire behavior metrics.
#'
#' @param targets List of target values (density_ha, species_props, mean_dbh, etc.)
#' @param weights List of optimization weights (0-100 scale)
#' @param plot_size Plot dimension (m), creates plot_size x plot_size area
#' @param max_iterations Maximum annealing iterations
#' @param initial_temp Initial temperature for annealing
#' @param cooling_rate Temperature cooling rate per iteration
#' @param energy_threshold Stop if energy below this threshold
#' @param verbose Print progress messages
#' @param print_every Print status every N iterations
#' @param plot_interval Update plots every N iterations (NULL = no plotting)
#' @param save_plots Save intermediate plot images to files
#' @param nurse_distance Target distance for PIED trees to nearest juniper (m)
#' @param use_nurse_effect Include nurse tree effect in optimization
#' @param mortality_prop Simulate this proportion of dead trees after optimization (0-1)
#'
#' @return List containing trees, metrics, history, and final energy
#' @export
#' @examples
#' \donttest{
#' config <- pj_huffman_2009(max_iterations = 500)
#' set.seed(42)
#' result <- simulate_stand(
#'   targets        = config$targets,
#'   weights        = config$weights,
#'   plot_size      = 20,
#'   max_iterations = 500,
#'   verbose        = FALSE,
#'   plot_interval  = NULL
#' )
#' result$energy
#' nrow(result$trees)
#' }
simulate_stand <- function(targets,
                          weights = NULL,
                          plot_size = 100,
                          max_iterations = 100000,
                          initial_temp = 0.01,
                          cooling_rate = 0.9999,
                          energy_threshold = 1e-6,
                          verbose = TRUE,
                          print_every = 1000,
                          plot_interval = 1000,
                          save_plots = FALSE,
                          nurse_distance = 3.0,
                          use_nurse_effect = TRUE,
                          mortality_prop = 0.0) {

  # Default weights if not provided
  if (is.null(weights)) {
    weights <- list(
      ce = 1.0,
      dbh_mean = 0.01,
      dbh_sd = 0.01,
      height_mean = 0.01,
      height_sd = 0.01,
      species = 10.0,
      canopy_cover = 5.0,
      cbd = 1.0,
      nurse = 2.0  # Weight for nurse tree effect
    )
  }
  # check mortality_prop
  if(!inherits(mortality_prop,"numeric")) stop("`mortality_prop` must be numeric")
  if(mortality_prop<0 || mortality_prop>=1){
    stop("`mortality_prop` must be numeric in the range [0,1)")
  }

  # Initialize trees
  n_initial <- round(targets$density_ha * (plot_size^2 / 10000))
  species_names <- names(targets$species_props)

  trees <- data.table(
    Number = seq_len(n_initial),
    x = runif(n_initial, 0, plot_size),
    y = runif(n_initial, 0, plot_size),
    Species = sample(species_names, n_initial, replace = TRUE, prob = targets$species_props),
    DBH = rnorm(n_initial, targets$mean_dbh, targets$sd_dbh)
  )
  trees$DBH <- pmax(trees$DBH, 5)

  # Calculate initial attributes and metrics
  trees <- calc_tree_attributes(trees)
  metrics <- calc_stand_metrics(trees, plot_size)
  energy <- calc_energy(metrics, targets, weights, trees, nurse_distance, use_nurse_effect)

  # Store history
  history <- data.table(
    iteration = integer(),
    energy = numeric(),
    clark_evans_r = numeric(),
    canopy_cover = numeric(),
    cbd = numeric(),
    cbd_mean = numeric(),
    cfl = numeric(),
    canopy_depth = numeric(),
    n_trees = integer(),
    accepted = logical()
  )

  # Annealing parameters
  temperature <- initial_temp
  best_energy <- energy
  best_trees <- copy(trees)
  best_metrics <- metrics

  # Setup for plotting
  if (!is.null(plot_interval)) {
    # Create a plotting device if not already open
    if (dev.cur() == 1) {
      dev.new(width = 12, height = 8)
    }
  }

  # Main loop
  for (iter in 1:max_iterations) {
    # Adaptive perturbation probabilities based on current deviations
    density_error <- abs(metrics$density_ha - targets$density_ha) / targets$density_ha

    # Base probabilities
    p_move <- 0.40
    p_species <- 0.15
    p_dbh <- 0.25
    p_add <- 0.10
    p_remove <- 0.10

    # If density is important and we're off target, boost add/remove
    if ("density" %in% names(weights) && weights$density > 0 && density_error > 0.05) {
      if (metrics$density_ha < targets$density_ha) {
        # Need more trees - boost add
        p_add <- 0.25
        p_remove <- 0.05
      } else {
        # Need fewer trees - boost remove
        p_add <- 0.05
        p_remove <- 0.25
      }
      # Reduce other operations proportionally
      p_move <- 0.30
      p_species <- 0.10
      p_dbh <- 0.15
    }

    # Select perturbation type
    perturb_type <- sample(1:5, 1, prob = c(p_move, p_species, p_dbh, p_add, p_remove))
    if (use_nurse_effect && perturb_type == 4) {
      # Use nurse-aware add
      trees_new <- perturb_add_with_nurse(trees, plot_size, species_names,
                                          targets$species_props, targets$mean_dbh,
                                          targets$sd_dbh, nurse_distance)
    } else {
      trees_new <- switch(perturb_type,
        perturb_move(trees, plot_size),
        perturb_species(trees, species_names, targets$species_props),
        perturb_dbh(trees, dbh_sd_perturb = targets$sd_dbh * 0.2),
        perturb_add(trees, plot_size, species_names, targets$species_props,
                    targets$mean_dbh, targets$sd_dbh),
        perturb_remove(trees, min_trees = 10)
      )
    }

    # Recalculate attributes and metrics
    trees_new <- calc_tree_attributes(trees_new)
    metrics_new <- calc_stand_metrics(trees_new, plot_size)
    energy_new <- calc_energy(metrics_new, targets, weights, trees_new,
                              nurse_distance, use_nurse_effect)

    # Accept or reject
    delta_energy <- energy_new - energy
    accept <- FALSE

    if (delta_energy < 0) {
      accept <- TRUE
    } else if (runif(1) < exp(-delta_energy / temperature)) {
      accept <- TRUE
    }

    if (accept) {
      trees <- trees_new
      metrics <- metrics_new
      energy <- energy_new

      # Update best
      if (energy < best_energy) {
        best_energy <- energy
        best_trees <- copy(trees)
        best_metrics <- metrics
      }
    }

    # Cool down
    temperature <- temperature * cooling_rate

    # Record history
    if (iter %% 100 == 0) {
      history <- rbind(history, data.table(
        iteration = iter,
        energy = energy,
        clark_evans_r = metrics$clark_evans_r,
        canopy_cover = metrics$canopy_cover,
        cbd = metrics$cbd,
        cbd_mean = metrics$cbd_mean,
        cfl = metrics$cfl,
        canopy_depth = metrics$canopy_depth,
        n_trees = nrow(trees),
        accepted = accept
      ))
    }

    # Print progress
    if (verbose && iter %% print_every == 0) {
      cat(sprintf("Iter %d: Energy=%.6f, CE=%.3f, Cover=%.3f, CFL=%.3f, N=%d, Temp=%.6f\n",
                  iter, energy, metrics$clark_evans_r, metrics$canopy_cover,
                  metrics$cfl, nrow(trees), temperature))
    }

    # Update plots
    if (!is.null(plot_interval) && iter %% plot_interval == 0) {
      plot_progress(trees, metrics, targets, history, iter, energy, temperature, plot_size, save_plots)
    }

    # Check convergence
    if (energy < energy_threshold) {
      if (verbose) {
        cat(sprintf("Converged at iteration %d with energy %.6e\n", iter, energy))
      }
      break
    }
  }

  # Apply mortality simulation if requested
  if (mortality_prop > 0) {
    if (verbose) {
      cat(sprintf("\nSimulating mortality (target: %.1f%% dead)...\n", mortality_prop * 100))
    }
    best_trees <- simulate_mortality(best_trees, mortality_prop)

    if (verbose) {
      n_dead <- sum(best_trees$Status == "dead")
      cat(sprintf("Mortality applied: %d trees dead (%.1f%%)\n",
                  n_dead, 100 * n_dead / nrow(best_trees)))
    }
  }else{
    # fill columns to match result of simulate_mortality()
    best_trees$MortalityProbability <- 0
    best_trees$Status <- "live"
  }

  # Return results
  return(list(
    trees = best_trees,
    metrics = best_metrics,
    energy = best_energy,
    history = history,
    targets = targets,
    mortality_applied = mortality_prop > 0
  ))
}

# ==============================================================================
# VISUALIZATION FUNCTIONS
# ==============================================================================

#' Plot progress during simulation - showing objective progress
#' @param trees Current trees data
#' @param metrics Current metrics
#' @param targets Target parameters
#' @param history History data table
#' @param iter Current iteration
#' @param energy Current energy
#' @param temperature Current temperature
#' @param plot_size Size of the plot area
#' @param save_plot Whether to save plot to file
plot_progress <- function(trees, metrics, targets, history, iter, energy, temperature, plot_size, save_plot = FALSE) {
  # Set up layout: 5 rows x 5 cols
  # Rows 1-4, Left (cols 1-2): C-E, Canopy Cover, CFL, Species
  # Rows 1-4, Right (cols 3-5): Spatial view (4 rows x 3 cols)
  # Row 5 (all cols): Convergence (1 row x 5 cols)
  layout(matrix(c(1,1,5,5,5,
                  2,2,5,5,5,
                  3,3,5,5,5,
                  4,4,5,5,5,
                  6,6,6,6,6), nrow=5, byrow=TRUE))
  par(oma = c(0, 0, 2, 0))

  # 1. Clark-Evans R progress
  par(mar = c(4, 4, 2, 1))
  if (nrow(history) > 0) {
    plot(history$iteration, history$clark_evans_r,
         type = "l", col = "steelblue", lwd = 2,
         xlab = "Iteration", ylab = "Clark-Evans R",
         main = "Spatial Pattern",
         ylim = range(c(history$clark_evans_r, targets$clark_evans_r)))
    abline(h = targets$clark_evans_r, col = "red", lwd = 2, lty = 2)
    legend("topright", legend = c("Current", "Target"),
           col = c("steelblue", "red"), lty = c(1, 2), lwd = 2, cex = 0.7)
    grid()
  } else {
    plot.new()
    text(0.5, 0.5, "Building history...", cex = 1.5)
  }

  # 2. Canopy Cover progress
  par(mar = c(4, 4, 2, 1))
  if (nrow(history) > 0) {
    plot(history$iteration, history$canopy_cover * 100,
         type = "l", col = "forestgreen", lwd = 2,
         xlab = "Iteration", ylab = "Canopy Cover (%)",
         main = "Canopy Cover",
         ylim = range(c(history$canopy_cover * 100, targets$canopy_cover * 100)))
    abline(h = targets$canopy_cover * 100, col = "red", lwd = 2, lty = 2)
    legend("topright", legend = c("Current", "Target"),
           col = c("forestgreen", "red"), lty = c(1, 2), lwd = 2, cex = 0.7)
    grid()
  } else {
    plot.new()
    text(0.5, 0.5, "Building history...", cex = 1.5)
  }

  # 3. Canopy Fuel Load progress
  par(mar = c(4, 4, 2, 1))
  if (nrow(history) > 0) {
    plot(history$iteration, history$cfl,
         type = "l", col = "darkorange", lwd = 2,
         xlab = "Iteration", ylab = "CFL (kg/m^2)",
         main = "Canopy Fuel Load",
         ylim = range(c(history$cfl, targets$cfl)))
    abline(h = targets$cfl, col = "red", lwd = 2, lty = 2)
    legend("topright", legend = c("Current", "Target"),
           col = c("darkorange", "red"), lty = c(1, 2), lwd = 2, cex = 0.7)
    grid()
  } else {
    plot.new()
    text(0.5, 0.5, "Building history...", cex = 1.5)
  }

  # 4. Species composition
  par(mar = c(4, 4, 2, 1))
  spp_actual <- as.vector(table(trees$Species) / nrow(trees))
  spp_target <- targets$species_props
  spp_names <- names(targets$species_props)

  barplot(rbind(spp_target, spp_actual),
          beside = TRUE,
          names.arg = spp_names,
          col = c("gray70", "steelblue"),
          legend.text = c("Target", "Actual"),
          args.legend = list(x = "topright", cex = 0.7),
          main = "Species Composition",
          ylab = "Proportion",
          las = 2)

  # 5. Spatial view - Crown polygons with stem locations
  par(mar = c(3, 3, 2, 1))
  plot(trees$x, trees$y, type = "n", asp = 1,
       xlim = c(0, plot_size), ylim = c(0, plot_size),
       xlab = "X (m)", ylab = "Y (m)", main = "Crown Cover & Stems")

  # Draw plot boundary
  rect(0, 0, plot_size, plot_size, border = "gray30", lwd = 2)

  # Define colors for species - expand to include common species
  all_species_colors <- c(
    PIED = "#2E8B57",  # Pinyon - sea green
    JUMO = "#8B4513",  # Juniper - saddle brown
    JUSO = "#D2691E",  # Utah juniper - chocolate
    PIPO = "#228B22",  # Ponderosa pine - forest green
    PSME = "#006400",  # Douglas-fir - dark green
    ABCO = "#556B2F"   # White fir - dark olive green
  )

  present_species <- unique(trees$Species)
  species_colors <- all_species_colors[present_species]

  # Handle any species not in predefined list
  missing_species <- present_species[!present_species %in% names(all_species_colors)]
  if (length(missing_species) > 0) {
    # Assign default colors for unknown species
    default_colors <- rainbow(length(missing_species))
    names(default_colors) <- missing_species
    species_colors <- c(species_colors, default_colors)
  }

  # Make crown colors semi-transparent for dissolved look
  crown_colors <- paste0(species_colors, "60")  # Add transparency
  names(crown_colors) <- names(species_colors)

  # Draw crown circles (filled, semi-transparent for dissolved effect)
  for (i in 1:nrow(trees)) {
    crown_col <- crown_colors[trees$Species[i]]
    if (is.na(crown_col)) crown_col <- "#88888860"

    # Draw crown circle with subtle border for dissolved look
    theta <- seq(0, 2*pi, length.out = 50)
    cx <- trees$x[i] + trees$CrownRadius[i] * cos(theta)
    cy <- trees$y[i] + trees$CrownRadius[i] * sin(theta)

    # Clip to plot boundaries
    cx <- pmax(0, pmin(plot_size, cx))
    cy <- pmax(0, pmin(plot_size, cy))

    polygon(cx, cy, col = crown_col, border = crown_col, lwd = 0.5)
  }

  # Overlay stem points colored by species and sized by DBH
  tree_colors <- species_colors[trees$Species]
  tree_colors[is.na(tree_colors)] <- "#888888"

  # Scale point size by DBH (normalize to reasonable range)
  point_sizes <- 0.3 + (trees$DBH / max(trees$DBH)) * 1.5

  points(trees$x, trees$y, pch = 19, col = tree_colors, cex = point_sizes)

  # Add legend - only show species actually present
  legend("topright",
         legend = names(species_colors),
         fill = crown_colors,
         border = NA,
         cex = 0.7,
         title = "Species")

  # Add iteration info
  text(plot_size * 0.02, plot_size * 0.98,
       sprintf("Iter: %d | N=%d | CFL=%.2f", iter, nrow(trees), metrics$cfl),
       adj = c(0, 1), cex = 0.9, font = 2)

  # 6. Energy convergence (bottom, full width)
  par(mar = c(4, 4, 2, 1))
  if (nrow(history) > 0) {
    plot(history$iteration, history$energy,
         type = "l", log = "y",
         xlab = "Iteration", ylab = "Energy (log scale)",
         main = sprintf("Convergence (Energy=%.2e, Temperature=%.2e)", energy, temperature),
         col = "blue", lwd = 2)
    grid()
  } else {
    plot.new()
    text(0.5, 0.5, "Building history...", cex = 1.5)
  }

  # Overall title
  mtext(sprintf("Simulation Progress - Iteration %d", iter),
        outer = TRUE, cex = 1.3, font = 2)

  # Save if requested
  if (save_plot) {
    filename <- sprintf("simulation_progress_%06d.png", iter)
    dev.copy(png, filename = filename, width = 1200, height = 800)
    dev.off()
    dev.set(dev.prev())
  }

  # Force display update
  flush.console()
}

#' Plot Simulation Results
#'
#' Creates a four-panel ggplot2 diagnostic display: spatial pattern,
#' crown coverage, DBH distribution, and convergence history.
#'
#' @param result Result object from \code{\link{simulate_stand}}
#' @export
#' @examples
#' \donttest{
#' config <- pj_huffman_2009(max_iterations = 200)
#' set.seed(42)
#' result <- simulate_stand(
#'   targets = config$targets, weights = config$weights,
#'   plot_size = 20, max_iterations = 200,
#'   verbose = FALSE, plot_interval = NULL
#' )
#' plot_simulation_results(result)
#' }
plot_simulation_results <- function(result) {
  trees <- result$trees
  metrics <- result$metrics
  targets <- result$targets

  # Spatial pattern plot
  p1 <- ggplot(trees, aes(x = x, y = y, color = Species, size = DBH)) +
    geom_point(alpha = 0.7) +
    coord_fixed() +
    theme_minimal() +
    labs(title = "Spatial Pattern",
         subtitle = sprintf("CE=%.3f (target=%.3f)",
                           metrics$clark_evans_r, targets$clark_evans_r)) +
    scale_size_continuous(range = c(1, 10))

  # Crown coverage plot
  p2 <- ggplot(trees, aes(x = x, y = y)) +
    geom_point(aes(size = CrownRadius, color = Species), alpha = 0.3) +
    coord_fixed() +
    theme_minimal() +
    labs(title = "Crown Coverage",
         subtitle = sprintf("Cover=%.3f (target=%.3f)",
                           metrics$canopy_cover, targets$canopy_cover)) +
    scale_size_continuous(range = c(1, 20))

  # DBH distribution
  p3 <- ggplot(trees, aes(x = DBH, fill = Species)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    geom_vline(xintercept = targets$mean_dbh, linetype = "dashed", color = "red") +
    theme_minimal() +
    labs(title = "DBH Distribution",
         subtitle = sprintf("Mean=%.1f (target=%.1f), SD=%.1f (target=%.1f)",
                           metrics$mean_dbh, targets$mean_dbh,
                           metrics$sd_dbh, targets$sd_dbh))

  # Energy history
  p4 <- ggplot(result$history, aes(x = iteration, y = energy)) +
    geom_line() +
    scale_y_log10() +
    theme_minimal() +
    labs(title = "Convergence", y = "Energy (log scale)")

  gridExtra::grid.arrange(p1, p2, p3, p4, ncol = 2)
}

#' Print Simulation Summary
#'
#' Prints a formatted comparison of simulated vs. target stand metrics.
#'
#' @param result Result object from \code{\link{simulate_stand}}
#' @export
#' @examples
#' \donttest{
#' config <- pj_huffman_2009(max_iterations = 200)
#' set.seed(42)
#' result <- simulate_stand(
#'   targets = config$targets, weights = config$weights,
#'   plot_size = 20, max_iterations = 200,
#'   verbose = FALSE, plot_interval = NULL
#' )
#' print_simulation_summary(result)
#' }
print_simulation_summary <- function(result) {
  metrics <- result$metrics
  targets <- result$targets
  trees <- result$trees

  cat("\n==================== SIMULATION SUMMARY ====================\n\n")

  cat("SPATIAL PATTERN:\n")
  cat(sprintf("  Clark-Evans R: %.3f (target: %.3f)\n",
              metrics$clark_evans_r, targets$clark_evans_r))
  cat(sprintf("  Deviation: %.3f\n\n",
              abs(metrics$clark_evans_r - targets$clark_evans_r)))

  cat("TREE SIZE:\n")
  cat(sprintf("  Mean DBH: %.2f cm (target: %.2f cm)\n",
              metrics$mean_dbh, targets$mean_dbh))
  cat(sprintf("  SD DBH: %.2f cm (target: %.2f cm)\n",
              metrics$sd_dbh, targets$sd_dbh))
  cat(sprintf("  Mean Height: %.2f m (target: %.2f m)\n",
              metrics$mean_height, targets$mean_height))
  cat(sprintf("  SD Height: %.2f m (target: %.2f m)\n\n",
              metrics$sd_height, targets$sd_height))

  cat("SPECIES COMPOSITION:\n")
  species_names <- names(targets$species_props)
  for (i in seq_along(species_names)) {
    cat(sprintf("  %s: %.3f (target: %.3f)\n",
                species_names[i], metrics$species_props[i], targets$species_props[i]))
  }
  cat("\n")

  cat("CANOPY ATTRIBUTES:\n")
  cat(sprintf("  Canopy Cover: %.3f (target: %.3f)\n",
              metrics$canopy_cover, targets$canopy_cover))
  cat(sprintf("  Canopy Fuel Load (CFL): %.3f kg/m^2 (target: %.3f kg/m^2)\n",
              metrics$cfl, targets$cfl))
  cat(sprintf("  CBD (reference): %.3f kg/m^3\n\n", metrics$cbd))

  cat("STAND DENSITY:\n")
  cat(sprintf("  Number of trees: %d\n", nrow(trees)))
  cat(sprintf("  Density: %.1f trees/ha (target: %.1f trees/ha)\n\n",
              metrics$density_ha, targets$density_ha))

  cat(sprintf("FINAL ENERGY: %.6e\n", result$energy))
  cat("\n============================================================\n")
}

#' Analyze and Report Simulation Results
#'
#' Comprehensive analysis and reporting function that compares simulation results
#' to targets, calculates mortality statistics, analyzes nurse tree effects,
#' generates summary tables, and saves outputs to CSV files and PDF plots.
#'
#' @param result Result object from simulate_stand()
#' @param targets List of target parameters used in simulation
#' @param prefix Character prefix for output filenames (default: "simulation")
#' @param save_plots Logical, whether to save PDF plots (default: TRUE)
#' @param plot_width Width of PDF plots in inches (default: 12)
#' @param plot_height Height of PDF plots in inches (default: 8)
#' @param nurse_distance_target Target distance for nurse tree effect (default: 2.5m)
#' @param target_mortality Target mortality percentage (default: 15.0)
#'
#' @return Invisibly returns a list containing all calculated statistics
#' @export
#'
#' @examples
#' \donttest{
#' config <- pj_huffman_2009(max_iterations = 200)
#' set.seed(42)
#' result <- simulate_stand(
#'   targets = config$targets, weights = config$weights,
#'   plot_size = 20, max_iterations = 200,
#'   verbose = FALSE, plot_interval = NULL,
#'   mortality_prop = 0.15
#' )
#' analyze_simulation_results(result, config$targets,
#'                            prefix = file.path(tempdir(), "demo"),
#'                            save_plots = FALSE)
#' }
analyze_simulation_results <- function(result, targets,
                                      prefix = "simulation",
                                      save_plots = TRUE,
                                      plot_width = 12,
                                      plot_height = 8,
                                      nurse_distance_target = 2.5,
                                      target_mortality = 15.0) {

  # Extract trees data
  if ("data.table" %in% class(result$trees)) {
    trees_dt <- result$trees
  } else {
    trees_dt <- data.table::as.data.table(result$trees)
  }

  # Header
  message(paste0(
    "\n\n",
    "===============================================================================\n",
    "                         SIMULATION RESULTS SUMMARY                            \n",
    "===============================================================================\n"
  ))

  # Get metrics for live trees only
  live_trees <- trees_dt[Status == "live"]
  live_metrics <- calc_stand_metrics(live_trees, 100)

  # Calculate mortality statistics
  n_total <- nrow(trees_dt)
  n_live <- nrow(live_trees)
  n_dead <- n_total - n_live
  pct_live <- 100 * n_live / n_total
  pct_dead <- 100 * n_dead / n_total

  # ============================================================================
  # STAND STRUCTURE
  # ============================================================================

  message(sprintf(
    paste0(
      "\nSTAND STRUCTURE (Live Trees Only)\n",
      "-------------------------------------------------------------------------------\n",
      "%-30s %12s %12s %12s\n",
      "-------------------------------------------------------------------------------\n",
      "%-30s %12.1f %12.1f %12.1f\n",
      "%-30s %12.1f %12.1f %12.1f\n",
      "%-30s %12.3f %12.3f %12.3f\n",
      "%-30s %12.2f %12.2f %12.2f\n"
    ),
    "Parameter", "Target", "Simulated", "Difference",
    "Density (trees/ha)", targets$density_ha * 0.85, live_metrics$density_ha,
      live_metrics$density_ha - targets$density_ha * 0.85,
    "Canopy Cover (%)", targets$canopy_cover * 100, live_metrics$canopy_cover * 100,
      (live_metrics$canopy_cover - targets$canopy_cover) * 100,
    "Canopy Fuel Load (kg/m²)", targets$cfl, live_metrics$cfl,
      live_metrics$cfl - targets$cfl,
    "Clark-Evans R", targets$clark_evans_r, live_metrics$clark_evans_r,
      live_metrics$clark_evans_r - targets$clark_evans_r
  ))

  # ============================================================================
  # TREE SIZE DISTRIBUTION
  # ============================================================================

  message(sprintf(
    paste0(
      "\nTREE SIZE DISTRIBUTION\n",
      "-------------------------------------------------------------------------------\n",
      "%-30s %12s %12s %12s\n",
      "-------------------------------------------------------------------------------\n",
      "%-30s %12.1f %12.1f %12.1f\n",
      "%-30s %12.1f %12.1f %12.1f\n",
      "%-30s %12.1f %12.1f %12.1f\n",
      "%-30s %12.1f %12.1f %12.1f\n"
    ),
    "Parameter", "Target", "Simulated", "Difference",
    "Mean DBH (cm)", targets$mean_dbh, live_metrics$mean_dbh,
      live_metrics$mean_dbh - targets$mean_dbh,
    "SD DBH (cm)", targets$sd_dbh, live_metrics$sd_dbh,
      live_metrics$sd_dbh - targets$sd_dbh,
    "Mean Height (m)", targets$mean_height, live_metrics$mean_height,
      live_metrics$mean_height - targets$mean_height,
    "SD Height (m)", targets$sd_height, live_metrics$sd_height,
      live_metrics$sd_height - targets$sd_height
  ))

  # ============================================================================
  # SPECIES COMPOSITION
  # ============================================================================

  message(sprintf(
    paste0(
      "\nSPECIES COMPOSITION\n",
      "-------------------------------------------------------------------------------\n",
      "%-30s %12s %12s %12s\n",
      "-------------------------------------------------------------------------------"
    ),
    "Species", "Target (%)", "Simulated (%)", "Difference (%)"
  ))

  species_names <- names(targets$species_props)
  for (i in seq_along(species_names)) {
    target_pct <- targets$species_props[i] * 100
    sim_pct <- live_metrics$species_props[i] * 100
    diff_pct <- sim_pct - target_pct
    message(sprintf("%-30s %12.1f %12.1f %12.1f",
                species_names[i], target_pct, sim_pct, diff_pct))
  }

  # ============================================================================
  # MORTALITY
  # ============================================================================

  message(sprintf(
    paste0(
      "\nMORTALITY\n",
      "-------------------------------------------------------------------------------\n",
      "Total trees simulated:        %d\n",
      "Live trees:                   %d (%.1f%%)\n",
      "Dead trees:                   %d (%.1f%%)\n",
      "Target mortality:             %.1f%%\n"
    ),
    n_total, n_live, pct_live, n_dead, pct_dead, target_mortality
  ))

  # Mortality by species
  mort_by_species <- trees_dt[, .(
    Total = .N,
    Live = sum(Status == "live"),
    Dead = sum(Status == "dead"),
    Mortality_Pct = 100 * sum(Status == "dead") / .N,
    Mean_DBH_Live = mean(DBH[Status == "live"]),
    Mean_DBH_Dead = mean(DBH[Status == "dead"])
  ), by = Species]

  message("\nMortality by Species:")
  print(mort_by_species)

  # ============================================================================
  # NURSE TREE EFFECT ANALYSIS
  # ============================================================================

  message(paste0(
    "\nNURSE TREE EFFECT (PIED proximity to JUSO)\n",
    "-------------------------------------------------------------------------------"
  ))

  pied_trees <- live_trees[Species == "PIED"]
  juso_trees <- live_trees[Species == "JUSO"]

  dist_to_nurse <- NULL
  if (nrow(pied_trees) > 0 && nrow(juso_trees) > 0) {
    dist_to_nurse <- numeric(nrow(pied_trees))
    for (i in seq_len(nrow(pied_trees))) {
      dx <- juso_trees$x - pied_trees$x[i]
      dy <- juso_trees$y - pied_trees$y[i]
      dist_to_nurse[i] <- min(sqrt(dx^2 + dy^2))
    }

    message(sprintf(
      paste0(
        "Target mean distance PIED to nearest JUSO:  %.2f m\n",
        "Simulated mean distance:                     %.2f m\n",
        "Median distance:                             %.2f m\n",
        "Range:                                       %.2f - %.2f m\n",
        "SD:                                          %.2f m"
      ),
      nurse_distance_target, mean(dist_to_nurse), median(dist_to_nurse),
      min(dist_to_nurse), max(dist_to_nurse), sd(dist_to_nurse)
    ))
  } else {
    message("Insufficient trees to calculate nurse tree distances")
  }

  # ============================================================================
  # CANOPY ATTRIBUTES
  # ============================================================================

  message(sprintf(
    paste0(
      "\nCANOPY ATTRIBUTES (Live Trees)\n",
      "-------------------------------------------------------------------------------\n",
      "Mean crown radius:            %.2f m\n",
      "Mean crown base height:       %.2f m\n",
      "Mean crown length:            %.2f m\n",
      "Crown ratio (length/height):  %.3f\n",
      "Total canopy fuel:            %.1f kg\n",
      "Stand-level CBD:              %.3f kg/m³\n"
    ),
    mean(live_trees$CrownRadius),
    mean(live_trees$CrownBaseHeight),
    mean(live_trees$CrownLength),
    mean(live_trees$CrownLength / live_trees$Height),
    sum(live_trees$CanopyFuelMass),
    live_metrics$cbd
  ))

  message("\nTree Attributes by Species (Live Trees):")
  species_stats <- live_trees[, .(
    N = .N,
    Mean_DBH = mean(DBH),
    SD_DBH = sd(DBH),
    Mean_Height = mean(Height),
    Mean_CrownRadius = mean(CrownRadius),
    Mean_CrownBaseHeight = mean(CrownBaseHeight),
    Mean_CrownLength = mean(CrownLength),
    Mean_CanopyFuel = mean(CanopyFuelMass)
  ), by = Species]
  print(species_stats)

  # ============================================================================
  # DIAMETER DISTRIBUTION
  # ============================================================================

  message(paste0(
    "\nDIAMETER DISTRIBUTION\n",
    "-------------------------------------------------------------------------------\n",
    "Size class distribution (live trees):"
  ))

  # Create diameter classes
  live_trees[, DBH_Class := cut(DBH,
                                 breaks = c(0, 15, 35, 100),
                                 labels = c("≤15 cm", "15-35 cm", ">35 cm"),
                                 include.lowest = TRUE)]

  diam_dist <- live_trees[, .(Count = .N), by = .(Species, DBH_Class)]
  diam_dist[, Proportion := Count / sum(Count), by = Species]

  print(diam_dist)

  # ============================================================================
  # CONVERGENCE ANALYSIS
  # ============================================================================

  total_iters <- if (nrow(result$history) > 0) {
    as.integer(max(result$history$iteration))
  } else {
    0L
  }

  message(sprintf(
    paste0(
      "\nOPTIMIZATION CONVERGENCE\n",
      "-------------------------------------------------------------------------------\n",
      "Final energy:                 %.6e\n",
      "Total iterations:             %d\n",
      "Energy threshold:             %.6e\n",
      "Status:                       %s"
    ),
    result$energy,
    total_iters,
    1e-5,
    ifelse(result$energy < 1e-5, "CONVERGED \u2713", "Did not fully converge")
  ))

  # ============================================================================
  # SAVE RESULTS TO CSV
  # ============================================================================

  message(paste0(
    "\nSAVING RESULTS\n",
    "-------------------------------------------------------------------------------"
  ))

  # Save all trees (live and dead)
  all_trees_file <- paste0(prefix, "_all_trees.csv")
  write.csv(trees_dt, all_trees_file, row.names = FALSE)

  # Save live trees only
  live_trees_file <- paste0(prefix, "_live_trees.csv")
  write.csv(live_trees, live_trees_file, row.names = FALSE)

  # Save history
  history_file <- paste0(prefix, "_history.csv")
  write.csv(result$history, history_file, row.names = FALSE)

  # Save summary statistics
  summary_stats <- data.frame(
    Parameter = c("Density_ha", "Canopy_Cover_pct", "CFL_kg_m2", "Clark_Evans_R",
                  "Mean_DBH_cm", "SD_DBH_cm", "Mean_Height_m", "SD_Height_m",
                  "PIED_pct", "JUSO_pct", "Total_Trees", "Live_Trees", "Dead_Trees",
                  "Mortality_pct"),
    Target = c(targets$density_ha * 0.85, targets$canopy_cover * 100, targets$cfl,
               targets$clark_evans_r, targets$mean_dbh, targets$sd_dbh,
               targets$mean_height, targets$sd_height,
               targets$species_props[1] * 100, targets$species_props[2] * 100,
               NA, NA, NA, target_mortality),
    Simulated = c(live_metrics$density_ha, live_metrics$canopy_cover * 100,
                  live_metrics$cfl, live_metrics$clark_evans_r,
                  live_metrics$mean_dbh, live_metrics$sd_dbh,
                  live_metrics$mean_height, live_metrics$sd_height,
                  live_metrics$species_props[1] * 100, live_metrics$species_props[2] * 100,
                  n_total, n_live, n_dead, pct_dead)
  )
  summary_file <- paste0(prefix, "_summary.csv")
  write.csv(summary_stats, summary_file, row.names = FALSE)

  message(paste0(
    "All trees saved to:           ", all_trees_file, "\n",
    "Live trees saved to:          ", live_trees_file, "\n",
    "Convergence history saved to: ", history_file, "\n",
    "Summary statistics saved to:  ", summary_file
  ))

  # ============================================================================
  # GENERATE PLOTS
  # ============================================================================

  if (save_plots) {
    message(paste0(
      "\nGENERATING PLOTS\n",
      "-------------------------------------------------------------------------------"
    ))

    # Additional custom plots
    pdf_file <- paste0(prefix, "_plots.pdf")
    pdf(pdf_file, width = plot_width, height = plot_height)

    # Plot 1: Spatial pattern with live/dead status
    par(mfrow = c(1, 2))
    plot(trees_dt$x, trees_dt$y,
         pch = ifelse(trees_dt$Status == "live", 19, 1),
         col = ifelse(trees_dt$Species == "PIED", "darkgreen", "brown"),
         cex = sqrt(trees_dt$DBH) / 4,
         xlab = "X (m)", ylab = "Y (m)",
         main = "Tree Locations (filled=live, open=dead)")
    legend("topright",
           legend = c("PIED live", "PIED dead", "JUSO live", "JUSO dead"),
           pch = c(19, 1, 19, 1),
           col = c("darkgreen", "darkgreen", "brown", "brown"))

    # Plot 2: Diameter distribution comparison
    hist(live_trees[Species == "PIED"]$DBH, breaks = 20,
         col = rgb(0, 0.5, 0, 0.5), border = "darkgreen",
         xlab = "DBH (cm)", main = "Diameter Distribution by Species",
         xlim = c(0, max(live_trees$DBH) + 5))
    hist(live_trees[Species == "JUSO"]$DBH, breaks = 20,
         col = rgb(0.6, 0.3, 0, 0.5), border = "brown", add = TRUE)
    legend("topright", legend = c("PIED", "JUSO"),
           fill = c(rgb(0, 0.5, 0, 0.5), rgb(0.6, 0.3, 0, 0.5)))

    dev.off()

    message(paste0("PDF plots saved to:           ", pdf_file))
  }

  # Footer
  message(paste0(
    "\n===============================================================================\n",
    "                      SIMULATION COMPLETE                                      \n",
    "==============================================================================="
  ))

  # Return statistics invisibly
  invisible(list(
    live_metrics = live_metrics,
    mortality = list(n_total = n_total, n_live = n_live, n_dead = n_dead,
                     pct_live = pct_live, pct_dead = pct_dead,
                     by_species = mort_by_species),
    nurse_distances = dist_to_nurse,
    species_stats = species_stats,
    diameter_dist = diam_dist,
    convergence = list(energy = result$energy, iterations = total_iters)
  ))
}
