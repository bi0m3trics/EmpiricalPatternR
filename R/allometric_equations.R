#' Allometric Equations for Forest Simulation
#'
#' This file contains user-modifiable allometric equations for calculating
#' tree attributes from diameter at breast height (DBH). Users can customize
#' these equations for different species and forest types.
#'
#' @name allometric_equations
#' @keywords internal
NULL

# ==============================================================================
# DEFAULT ALLOMETRIC PARAMETERS
# ==============================================================================

#' Get default allometric parameters for pinyon-juniper woodland
#' 
#' Returns a list of allometric parameters for common pinyon-juniper species.
#' Users can modify these parameters or create new parameter sets for different
#' forest types.
#' 
#' @param use_reese_cbh Logical. If TRUE, uses Reese's quadratic CBH equations
#'   (more realistic crown shapes). If FALSE, uses simple linear CBH = 0.4*H.
#'   Default is TRUE.
#' @param use_miller_foliage Logical. If TRUE, uses Miller et al. (1981) 
#'   published foliage biomass equations. If FALSE, uses generic crown volume
#'   approach. Default is TRUE.
#' 
#' @return List containing species-specific parameters:
#' \describe{
#'   \item{crown_radius}{Parameters for crown radius (m) = a + b * DBH}
#'   \item{height}{Parameters for height (m) = 1.3 + a * (1 - exp(-b * DBH))}
#'   \item{crown_ratio}{Parameters for crown ratio = a - b * log(DBH)}
#'   \item{crown_mass}{Parameters for crown mass (kg) = a * DBH^b}
#'   \item{cbh_method}{Method for crown base height calculation}
#'   \item{cbh_reese}{Reese quadratic coefficients (if use_reese_cbh = TRUE)}
#'   \item{foliage_method}{Method for foliage biomass calculation}
#'   \item{foliage_miller}{Miller et al. coefficients (if use_miller_foliage = TRUE)}
#' }
#' @references
#'   Reese et al. Crown base height equations for pinyon-juniper species.
#'   Miller, Meeuwig & Budy (1981). USDA Forest Service INT-273.
#' @export
#' @examples
#' # Get default parameters with improved equations
#' params <- get_default_allometric_params()
#' 
#' # Use simple equations instead
#' params_simple <- get_default_allometric_params(
#'   use_reese_cbh = FALSE,
#'   use_miller_foliage = FALSE
#' )
#' 
#' # Modify for your own species
#' custom_params <- params
#' custom_params$crown_radius$PIPO <- list(a = 0.5, b = 0.10)
get_default_allometric_params <- function(use_reese_cbh = TRUE,
                                          use_miller_foliage = TRUE) {
  params <- list(
    # Reese crown diameter equations: ln(CD) = a + b*ln(DBH) + c*ln(H)
    # CD in meters, DBH in cm, H in meters. Radius = CD/2.
    crown_diameter = list(
      PIED = list(a = -0.0915, b = 0.2484, c = 0.3177, n = 1658, rmse = 0.94),
      JUMO = list(a = -0.2625, b = 0.2475, c = 0.5585, n = 2520, rmse = 1.44),
      JUSO = list(a = -0.4402, b = 0.2493, c = 0.5391, n = 941, rmse = 1.29),
      JUOS = list(a = -0.4402, b = 0.2493, c = 0.5391, n = 941, rmse = 1.29),
      default = list(a = -0.0915, b = 0.2484, c = 0.3177, n = 1658, rmse = 0.94)
    ),
    height = list(
      PIED = list(a = 12, b = 0.045),   # Max ~13m
      JUMO = list(a = 14, b = 0.040),   # Max ~15m
      JUSO = list(a = 10, b = 0.050),   # Max ~11m
      JUOS = list(a = 10, b = 0.050),   # Utah juniper (alternate code)
      default = list(a = 12, b = 0.045)
    ),
    crown_ratio = list(
      PIED = list(a = 0.75, b = 0.09),  # Fuller crowns
      JUMO = list(a = 0.70, b = 0.08),  
      JUSO = list(a = 0.72, b = 0.085),
      JUOS = list(a = 0.72, b = 0.085),
      default = list(a = 0.72, b = 0.085)
    ),
    crown_mass = list(
      PIED = list(a = 0.15, b = 2.2),   # kg = 0.15 * DBH^2.2
      JUMO = list(a = 0.12, b = 2.3),   
      JUSO = list(a = 0.13, b = 2.25),
      JUOS = list(a = 0.13, b = 2.25),
      default = list(a = 0.13, b = 2.2)
    )
  )
  
  # Add crown base height method and parameters
  if (use_reese_cbh) {
    params$cbh_method <- "reese_quadratic"
    # Reese equations: CBH = b0 + b1*H + b2*D + b3*H^2 + b4*D^2 + b5*(H*D)
    # Units: CBH and H in meters, D in cm
    params$cbh_reese <- list(
      PIED = list(b0 = -0.068753, b1 = 0.082146, b2 = -0.000171,
                  b3 = 0.024922, b4 = 0.000964, b5 = -0.009256),
      JUMO = list(b0 = -0.012301, b1 = 0.036959, b2 = 0.000603,
                  b3 = 0.005566, b4 = 0.000013, b5 = -0.000532),
      JUOS = list(b0 = 0.030417, b1 = 0.014673, b2 = 0.004576,
                  b3 = 0.010445, b4 = 0.000009, b5 = -0.000254),
      JUSO = list(b0 = 0.030417, b1 = 0.014673, b2 = 0.004576,
                  b3 = 0.010445, b4 = 0.000009, b5 = -0.000254),
      default = list(b0 = -0.068753, b1 = 0.082146, b2 = -0.000171,
                     b3 = 0.024922, b4 = 0.000964, b5 = -0.009256)
    )
  } else {
    params$cbh_method <- "simple_ratio"
    params$cbh_ratio <- 0.4  # CBH = 0.4 * height
  }
  
  # Add foliage biomass method and parameters
  if (use_miller_foliage) {
    params$foliage_method <- "miller_1981"
    # Miller et al. (1981) equations: ln(W_foliage) = a + b * ln(DBH)
    # Units: W_foliage in kg (ovendry), DBH in cm
    params$foliage_miller <- list(
      PIED = list(a = -1.593, b = 2.030),  # Singleleaf pinyon (similar to PIED)
      JUMO = list(a = -1.358, b = 1.841),  # Utah juniper coefficients
      JUOS = list(a = -1.358, b = 1.841),  # Utah juniper
      JUSO = list(a = -1.358, b = 1.841),  # Utah juniper
      default = list(a = -1.593, b = 2.030)
    )
  } else {
    params$foliage_method <- "crown_volume"
  }
  
  return(params)
}

#' Get default allometric parameters for ponderosa pine forest
#' 
#' Example parameter set for ponderosa pine dominated forests.
#' Demonstrates how to create custom allometric relationships.
#' 
#' @return List of allometric parameters for ponderosa pine
#' @export
#' @examples
#' # Use ponderosa pine parameters
#' params <- get_ponderosa_allometric_params()
get_ponderosa_allometric_params <- function() {
  list(
    # For ponderosa, use simplified log-log model (no Reese data available)
    # ln(CD) = a + b*ln(DBH) + c*ln(H)
    crown_diameter = list(
      PIPO = list(a = -0.5, b = 0.30, c = 0.40),   # Ponderosa pine - larger crowns
      PSME = list(a = -0.6, b = 0.28, c = 0.42),   # Douglas-fir
      ABCO = list(a = -0.4, b = 0.26, c = 0.38),   # White fir
      default = list(a = -0.5, b = 0.30, c = 0.40)
    ),
    height = list(
      PIPO = list(a = 35, b = 0.025),   # Max ~36m
      PSME = list(a = 40, b = 0.022),   # Max ~41m
      ABCO = list(a = 38, b = 0.023),   # Max ~39m
      default = list(a = 35, b = 0.025)
    ),
    crown_ratio = list(
      PIPO = list(a = 0.60, b = 0.10),  # More open crowns
      PSME = list(a = 0.55, b = 0.11),  
      ABCO = list(a = 0.65, b = 0.09),  # Fuller crowns
      default = list(a = 0.60, b = 0.10)
    ),
    crown_mass = list(
      PIPO = list(a = 0.25, b = 2.1),   # Larger trees
      PSME = list(a = 0.30, b = 2.0),   
      ABCO = list(a = 0.28, b = 2.05),
      default = list(a = 0.25, b = 2.1)
    ),
    # Ponderosa uses simple CBH (no Reese equations available)
    cbh_method = "simple_ratio",
    cbh_ratio = 0.4,
    # Ponderosa uses generic foliage (no Miller equations available)
    foliage_method = "crown_volume"
  )
}

# ==============================================================================
# ALLOMETRIC CALCULATION FUNCTIONS
# ==============================================================================
# These functions use the parameter sets defined above. To use custom
# allometric equations, modify the parameter lists or create new ones.
# ==============================================================================

#' Calculate crown radius from DBH and height using allometric equations
#' 
#' Calculates crown radius using Reese species-specific equations built from
#' measured pinyon-juniper crown data (n=5,119 trees).
#' 
#' **Model:** ln(CD) = a + b*ln(DBH) + c*ln(H)
#' 
#' Where CD = crown diameter (m), DBH = diameter (cm), H = height (m).
#' Crown radius returned as CD/2.
#' 
#' @param dbh Numeric vector. Tree diameter at breast height (cm)
#' @param height Numeric vector. Tree total height (m)
#' @param species Character vector. Species codes (e.g., "PIED", "JUMO", "JUOS")
#' @param allometric_params List. Allometric parameters from 
#'   \code{get_default_allometric_params()} or custom parameters
#' @return Numeric vector. Crown radius (m), minimum 0.3m
#' @references
#'   Reese et al. Crown diameter equations for pinyon-juniper species.
#'   Built from n=1,658 PIED, n=2,520 JUMO, n=941 JUOS trees.
#' @export
#' @examples
#' # Single tree - now requires height!
#' dbh <- 20
#' height <- calc_height(dbh, "PIED")
#' calc_crown_radius(dbh, height, "PIED")
#' 
#' # Multiple trees
#' dbh <- c(10, 20, 30)
#' species <- c("PIED", "JUMO", "JUOS")
#' height <- calc_height(dbh, species)
#' calc_crown_radius(dbh, height, species)
calc_crown_radius <- function(dbh, height, species, 
                               allometric_params = get_default_allometric_params()) {
  params <- allometric_params$crown_diameter
  
  # Vectorized calculation using Reese log-log equations
  crown_diam <- sapply(seq_along(dbh), function(i) {
    sp <- species[i]
    p <- if (sp %in% names(params)) params[[sp]] else params$default
    
    # ln(CD) = a + b*ln(DBH) + c*ln(H)
    # Back-transform: CD = exp(a + b*ln(DBH) + c*ln(H))
    log_cd <- p$a + p$b * log(pmax(dbh[i], 1)) + p$c * log(pmax(height[i], 1.3))
    exp(log_cd)
  })
  
  # Convert diameter to radius, apply minimum
  radius <- crown_diam / 2
  return(pmax(radius, 0.3))  # Minimum 0.3m radius
}

#' Calculate tree height from DBH using allometric equations
#' 
#' Calculates tree height using asymptotic exponential growth curves:
#' height (m) = 1.3 + a * (1 - exp(-b * DBH))
#' 
#' @param dbh Numeric vector. Tree diameter at breast height (cm)
#' @param species Character vector. Species codes
#' @param allometric_params List. Allometric parameters
#' @return Numeric vector. Tree height (m)
#' @export
#' @examples
#' # Single tree
#' calc_height(20, "PIED")
#' 
#' # Multiple trees with different species
#' calc_height(c(10, 20, 30), c("PIED", "JUSO", "JUMO"))
#' 
#' # Ponderosa pine
#' params <- get_ponderosa_allometric_params()
#' calc_height(40, "PIPO", params)
calc_height <- function(dbh, species,
                        allometric_params = get_default_allometric_params()) {
  params <- allometric_params$height
  
  height <- sapply(seq_along(dbh), function(i) {
    sp <- species[i]
    p <- if (sp %in% names(params)) params[[sp]] else params$default
    1.3 + p$a * (1 - exp(-p$b * dbh[i]))
  })
  
  return(height)
}

#' Calculate crown base height from DBH and total height
#' 
#' Calculates the height at which the live crown begins. Two methods available:
#' 
#' **Reese quadratic method** (default, more realistic):
#' CBH = b0 + b1*H + b2*D + b3*H^2 + b4*D^2 + b5*(H*D)
#' 
#' **Simple ratio method**:
#' crown_ratio = a - b * log(DBH)
#' crown_base_height = height * (1 - crown_ratio)
#' 
#' Method is determined by allometric_params$cbh_method.
#' 
#' @param dbh Numeric vector. Tree diameter at breast height (cm)
#' @param height Numeric vector. Total tree height (m)
#' @param species Character vector. Species codes
#' @param allometric_params List. Allometric parameters (from get_default_allometric_params)
#' @return Numeric vector. Crown base height (m)
#' @references
#'   Reese et al. Species-specific crown base height equations for
#'   pinyon-juniper woodlands (PIED, JUMO, JUOS).
#' @export
#' @examples
#' dbh <- c(10, 20, 30)
#' height <- calc_height(dbh, c("PIED", "PIED", "PIED"))
#' 
#' # Using Reese quadratic equations (default)
#' calc_crown_base_height(dbh, height, c("PIED", "PIED", "PIED"))
#' 
#' # Using simple ratio method
#' params <- get_default_allometric_params(use_reese_cbh = FALSE)
#' calc_crown_base_height(dbh, height, c("PIED", "PIED", "PIED"), params)
calc_crown_base_height <- function(dbh, height, species,
                                    allometric_params = get_default_allometric_params()) {
  
  method <- allometric_params$cbh_method
  
  if (method == "reese_quadratic") {
    # Reese quadratic equations: CBH = b0 + b1*H + b2*D + b3*H^2 + b4*D^2 + b5*(H*D)
    params <- allometric_params$cbh_reese
    
    cbh <- sapply(seq_along(dbh), function(i) {
      sp <- species[i]
      p <- if (sp %in% names(params)) params[[sp]] else params$default
      
      H <- height[i]
      D <- dbh[i]
      
      # Apply quadratic equation
      p$b0 + p$b1 * H + p$b2 * D + p$b3 * H^2 + p$b4 * D^2 + p$b5 * (H * D)
    })
    
    # Constrain: CBH must be >= 1.3m (breast height) and < 0.9*height
    cbh <- pmax(cbh, 1.3)
    cbh <- pmin(cbh, 0.9 * height)
    
  } else {
    # Simple crown ratio method
    params <- allometric_params$crown_ratio
    
    crown_ratio <- sapply(seq_along(dbh), function(i) {
      sp <- species[i]
      p <- if (sp %in% names(params)) params[[sp]] else params$default
      ratio <- p$a - p$b * log(pmax(dbh[i], 1))
      pmin(pmax(ratio, 0.3), 0.9)  # Constrain between 30% and 90%
    })
    
    cbh <- height * (1 - crown_ratio)
    cbh <- pmax(cbh, 1.3)  # Cannot be below breast height
  }
  
  return(cbh)
}

#' Calculate canopy fuel mass from DBH
#' 
#' Calculates total foliage and fine twig mass. Two methods available:
#' 
#' **Miller (1981) method** (default, published equations):
#' ln(W_foliage) = a + b * ln(DBH)
#' Based on destructive sampling of pinyon-juniper trees.
#' 
#' **Crown volume method** (generic):
#' mass (kg) = a * DBH^b
#' 
#' Method is determined by allometric_params$foliage_method.
#' 
#' @param dbh Numeric vector. Tree diameter at breast height (cm)
#' @param species Character vector. Species codes
#' @param allometric_params List. Allometric parameters (from get_default_allometric_params)
#' @return Numeric vector. Canopy fuel mass (kg, ovendry weight)
#' @references
#'   Miller, Meeuwig & Budy (1981). USDA Forest Service INT-273.
#'   Biomass of Singleleaf Pinyon and Utah Juniper.
#' @export
#' @examples
#' # Using Miller (1981) equations (default)
#' calc_canopy_fuel_mass(20, "PIED")
#' 
#' # Multiple trees
#' calc_canopy_fuel_mass(c(10, 20, 30), c("PIED", "JUSO", "JUMO"))
#' 
#' # Using generic crown volume method
#' params <- get_default_allometric_params(use_miller_foliage = FALSE)
#' calc_canopy_fuel_mass(20, "PIED", params)
calc_canopy_fuel_mass <- function(dbh, species,
                                   allometric_params = get_default_allometric_params()) {
  
  method <- allometric_params$foliage_method
  
  if (method == "miller_1981") {
    # Miller et al. (1981) published foliage biomass equations
    # ln(W_foliage) = a + b * ln(DBH)
    params <- allometric_params$foliage_miller
    
    mass <- sapply(seq_along(dbh), function(i) {
      sp <- species[i]
      p <- if (sp %in% names(params)) params[[sp]] else params$default
      
      # Apply logarithmic equation and back-transform
      log_mass <- p$a + p$b * log(pmax(dbh[i], 1))
      exp(log_mass)
    })
    
  } else {
    # Generic crown volume method
    params <- allometric_params$crown_mass
    
    mass <- sapply(seq_along(dbh), function(i) {
      sp <- species[i]
      p <- if (sp %in% names(params)) params[[sp]] else params$default
      p$a * dbh[i]^p$b
    })
  }
  
  return(mass)
}
