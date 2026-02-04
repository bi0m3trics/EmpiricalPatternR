#' EmpiricalPatternR: Forest Stand Pattern Simulation
#'
#' Simulates realistic forest stand patterns using simulated annealing
#' optimization to match empirical targets for spatial patterns, canopy
#' structure, species composition, and fire behavior metrics.
#'
#' @section Main Functions:
#' 
#' **Simulation:**
#' \itemize{
#'   \item \code{\link{simulate_stand}}: Run complete stand simulation
#'   \item \code{\link{simulate_mortality}}: Add post-disturbance mortality
#' }
#' 
#' **Stand Metrics:**
#' \itemize{
#'   \item \code{\link{calc_stand_metrics}}: Compute all stand-level metrics
#'   \item \code{\link{calc_tree_attributes}}: Calculate tree attributes from DBH
#'   \item \code{\link{calc_canopy_cover}}: Canopy cover with overlap handling

#' }
#' 
#' **Allometric Equations:**
#' \itemize{
#'   \item \code{\link{calc_crown_radius}}: Crown radius from DBH
#'   \item \code{\link{calc_height}}: Tree height from DBH
#'   \item \code{\link{calc_crown_base_height}}: Crown base height
#'   \item \code{\link{calc_canopy_fuel_mass}}: Foliage biomass
#'   \item \code{\link{get_default_allometric_params}}: Default pinyon-juniper parameters
#'   \item \code{\link{get_ponderosa_allometric_params}}: Ponderosa pine parameters
#' }
#' 
#' **Perturbation Operations:**
#' \itemize{
#'   \item \code{\link{perturb_move}}: Move tree to new location
#'   \item \code{\link{perturb_species}}: Change tree species
#'   \item \code{\link{perturb_dbh}}: Adjust tree diameter
#'   \item \code{\link{perturb_add}}: Add new tree
#'   \item \code{\link{perturb_remove}}: Remove tree
#'   \item \code{\link{perturb_add_with_nurse}}: Add tree with nurse effect
#' }
#'
#' @section Optimization Weight Guidelines:
#' All optimization weights range from 0-100:
#' \describe{
#'   \item{0}{Ignore this metric completely}
#'   \item{1-20}{Low priority - let it emerge from other constraints}
#'   \item{20-50}{Moderate priority - balance with other metrics}
#'   \item{50-80}{High priority - actively optimize toward target}
#'   \item{80-100}{Critical - dominates optimization}
#' }
#'
#' @section Customization:
#' 
#' **Allometric Equations:**
#' 
#' Create custom allometric parameters for your forest type:
#' \preformatted{
#' my_params <- list(
#'   crown_radius = list(SPECIES = list(a = 0.5, b = 0.10)),
#'   height = list(SPECIES = list(a = 20, b = 0.03)),
#'   crown_ratio = list(SPECIES = list(a = 0.70, b = 0.10)),
#'   crown_mass = list(SPECIES = list(a = 0.20, b = 2.1))
#' )
#' }
#' 
#' **Target Parameters:**
#' 
#' Modify targets to match your field data:
#' \preformatted{
#' targets <- list(
#'   density_ha = YOUR_DENSITY,
#'   species_props = c(SP1 = 0.6, SP2 = 0.4),
#'   mean_dbh = YOUR_MEAN,
#'   canopy_cover = YOUR_COVER,
#'   cfl = YOUR_CFL
#' )
#' }
#'
#' @section Examples:
#' Complete working examples in \code{inst/examples/}:
#' \itemize{
#'   \item \code{example_01_pinyon_juniper.R} - P-J woodland (Huffman 2009)
#'   \item \code{example_02_ponderosa_pine.R} - Ponderosa pine forest
#' }
#' 
#' @section References:
#' 
#' **Empirical Data:**
#' 
#' Huffman et al. (2009). A comparison of fire hazard mitigation alternatives 
#' in pinyon-juniper woodlands of Arizona. Forest Ecology and Management 257:628-635.
#' 
#' **Allometric Equations:**
#' 
#' Grier et al. (1992). Biomass distribution and productivity of 
#' Pinus edulis-Juniperus monosperma woodlands. Forest Ecology and Management 50:331-350.
#' 
#' Miller et al. (1981). Biomass of singleleaf pinyon and Utah juniper.
#' USDA Forest Service Research Paper INT-273.
#' 
#' **Crown Fire Methods:**
#' 
#' Van Wagner (1977). Conditions for the start and spread of crown fire.
#' Canadian Journal of Forest Research 7:23-34.
#' 
#' Scott & Reinhardt (2001). Assessing crown fire potential by linking models
#' of surface and crown fire behavior. USDA Forest Service Research Paper RMRS-RP-29.
#'
#' @docType package
#' @name EmpiricalPatternR-package
#' @aliases EmpiricalPatternR
#' @import data.table
#' @import ggplot2
#' @import spatstat
#' @importFrom Rcpp sourceCpp
#' @importFrom data.table :=
#' @importFrom ggplot2 ggplot aes geom_point geom_line geom_histogram geom_vline coord_fixed theme_minimal labs scale_size_continuous scale_y_log10
#' @importFrom stats rnorm runif sd
#' @importFrom utils head tail flush.console
#' @importFrom grDevices dev.copy dev.cur dev.new dev.off dev.prev dev.set png
#' @importFrom graphics abline barplot grid layout legend mtext par plot.new points polygon rect text
#' @useDynLib EmpiricalPatternR, .registration = TRUE
"_PACKAGE"

# Suppress R CMD check notes about data.table column names
utils::globalVariables(c(
  ".", "DBH", "Height", "Species", "CrownRadius", "CrownDiameter",
  "CrownArea", "CrownBaseHeight", "CrownLength", "CanopyFuelMass",
  "RCD", "MortalityProbability", "Status", "TreeID", "Number",
  "x", "y", "iteration", "energy"
))
