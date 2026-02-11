# Tests for forest simulation functions
# Functions: calc_canopy_cover, calc_tree_attributes, calc_stand_metrics,
#   perturb_move, perturb_species, perturb_dbh, perturb_add, perturb_remove,
#   calc_nurse_tree_energy, perturb_add_with_nurse, calc_mortality_probability,
#   simulate_mortality, simulate_stand, plot_simulation_results,
#   print_simulation_summary, analyze_simulation_results

library(data.table)

# ==========================================================================
# Helper: create a small tree data.table used by many tests
# ==========================================================================
make_test_trees <- function(n = 20, plot_size = 20) {
  set.seed(42)
  trees <- data.table(
    Number  = seq_len(n),
    x       = runif(n, 0, plot_size),
    y       = runif(n, 0, plot_size),
    Species = sample(c("PIED", "JUSO"), n, replace = TRUE),
    DBH     = pmax(rnorm(n, 20, 5), 5)
  )
  trees
}

# ==========================================================================
# calc_canopy_cover
# ==========================================================================

test_that("calc_canopy_cover returns proportion in [0, 1]", {
  set.seed(1)
  cc <- calc_canopy_cover(
    x = runif(10, 0, 20), y = runif(10, 0, 20),
    crown_radius = rep(2, 10), plot_size = 20
  )
  expect_true(cc >= 0 && cc <= 1)
})

test_that("calc_canopy_cover is 0 for tiny crowns", {
  cc <- calc_canopy_cover(x = 10, y = 10, crown_radius = 0.001, plot_size = 20)
  expect_true(cc < 0.01)
})

test_that("calc_canopy_cover increases with crown size", {
  set.seed(1)
  x <- runif(5, 2, 18)
  y <- runif(5, 2, 18)
  cc_small <- calc_canopy_cover(x, y, rep(1, 5), 20)
  cc_big   <- calc_canopy_cover(x, y, rep(5, 5), 20)
  expect_true(cc_big > cc_small)
})

# ==========================================================================
# calc_tree_attributes
# ==========================================================================

test_that("calc_tree_attributes adds required columns", {
  trees <- make_test_trees(10)
  result <- calc_tree_attributes(trees)

  expected_cols <- c("Height", "CrownRadius", "CrownDiameter",
                     "CrownArea", "CrownBaseHeight", "CrownLength",
                     "CanopyFuelMass")
  for (col in expected_cols) {
    expect_true(col %in% names(result), info = paste("missing", col))
  }
})

test_that("calc_tree_attributes produces positive values", {
  trees <- make_test_trees(10)
  result <- calc_tree_attributes(trees)
  expect_true(all(result$Height > 0))
  expect_true(all(result$CrownRadius > 0))
  expect_true(all(result$CrownDiameter > 0))
  expect_true(all(result$CrownArea > 0))
  expect_true(all(result$CanopyFuelMass >= 0))
})

test_that("calc_tree_attributes does not modify input", {
  trees <- make_test_trees(5)
  orig <- copy(trees)
  calc_tree_attributes(trees)
  expect_identical(trees, orig)
})

# ==========================================================================
# calc_stand_metrics
# ==========================================================================

test_that("calc_stand_metrics returns all metric components", {
  trees <- calc_tree_attributes(make_test_trees(20))
  m <- calc_stand_metrics(trees, plot_size = 20)

  expect_type(m, "list")
  needed <- c("clark_evans_r", "mean_dbh", "sd_dbh", "mean_height",
              "sd_height", "species_props", "canopy_cover",
              "cbd", "cfl", "density_ha")
  for (k in needed) {
    expect_true(k %in% names(m), info = paste("missing", k))
  }
})

test_that("calc_stand_metrics density_ha is correct", {
  trees <- calc_tree_attributes(make_test_trees(20, plot_size = 20))
  m <- calc_stand_metrics(trees, plot_size = 20)
  expected <- 20 / (20^2 / 10000)
  expect_equal(m$density_ha, expected)
})

# ==========================================================================
# perturb_move
# ==========================================================================

test_that("perturb_move changes exactly one tree position", {
  trees <- make_test_trees(10)
  set.seed(1)
  new_trees <- perturb_move(trees, plot_size = 20)
  changes <- sum(trees$x != new_trees$x) + sum(trees$y != new_trees$y)
  expect_true(changes >= 1 && changes <= 2)
  expect_equal(nrow(new_trees), nrow(trees))
})

# ==========================================================================
# perturb_species
# ==========================================================================

test_that("perturb_species changes at most one species", {
  trees <- make_test_trees(10)
  set.seed(1)
  new_trees <- perturb_species(trees, c("PIED", "JUSO"), c(0.7, 0.3))
  n_changed <- sum(trees$Species != new_trees$Species)
  expect_true(n_changed <= 1)
  expect_equal(nrow(new_trees), nrow(trees))
})

# ==========================================================================
# perturb_dbh
# ==========================================================================

test_that("perturb_dbh changes at most one DBH value", {
  trees <- make_test_trees(10)
  set.seed(1)
  new_trees <- perturb_dbh(trees, dbh_sd_perturb = 3)
  n_changed <- sum(trees$DBH != new_trees$DBH)
  expect_true(n_changed <= 1)
  expect_equal(nrow(new_trees), nrow(trees))
})

test_that("perturb_dbh enforces minimum 5 cm", {
  trees <- data.table(Number = 1:3, x = 1:3, y = 1:3,
                      Species = "PIED", DBH = c(5.0, 5.0, 5.0))
  set.seed(1)
  for (i in 1:20) {
    new_trees <- perturb_dbh(trees, dbh_sd_perturb = 10)
    expect_true(all(new_trees$DBH >= 5))
  }
})

# ==========================================================================
# perturb_add
# ==========================================================================

test_that("perturb_add adds exactly one tree", {
  trees <- make_test_trees(10)
  new_trees <- perturb_add(trees, 20, c("PIED", "JUSO"), c(0.7, 0.3), 20, 5)
  expect_equal(nrow(new_trees), nrow(trees) + 1)
})

test_that("perturb_add tree is within plot", {
  trees <- make_test_trees(10)
  new_trees <- perturb_add(trees, 20, c("PIED", "JUSO"), c(0.7, 0.3), 20, 5)
  expect_true(all(new_trees$x >= 0 & new_trees$x <= 20))
  expect_true(all(new_trees$y >= 0 & new_trees$y <= 20))
})

# ==========================================================================
# perturb_remove
# ==========================================================================

test_that("perturb_remove removes one tree when above min", {
  trees <- make_test_trees(20)
  new_trees <- perturb_remove(trees, min_trees = 10)
  expect_equal(nrow(new_trees), nrow(trees) - 1)
})

test_that("perturb_remove does not remove below min_trees", {
  trees <- make_test_trees(5)
  new_trees <- perturb_remove(trees, min_trees = 5)
  expect_equal(nrow(new_trees), nrow(trees))
})

# ==========================================================================
# calc_nurse_tree_energy
# ==========================================================================

test_that("calc_nurse_tree_energy returns numeric >= 0", {
  trees <- make_test_trees(30)
  e <- calc_nurse_tree_energy(trees, nurse_distance = 3.0)
  expect_type(e, "double")
  expect_true(e >= 0)
})

test_that("calc_nurse_tree_energy returns 0 when no juniper", {
  trees <- data.table(x = 1:5, y = 1:5, Species = rep("PIED", 5))
  e <- calc_nurse_tree_energy(trees, nurse_distance = 3.0)
  expect_equal(e, 0)
})

test_that("calc_nurse_tree_energy returns 0 when no pinyon", {
  trees <- data.table(x = 1:5, y = 1:5, Species = rep("JUSO", 5))
  e <- calc_nurse_tree_energy(trees, nurse_distance = 3.0)
  expect_equal(e, 0)
})

# ==========================================================================
# perturb_add_with_nurse
# ==========================================================================

test_that("perturb_add_with_nurse adds exactly one tree", {
  trees <- make_test_trees(10)
  new_trees <- perturb_add_with_nurse(
    trees, 20, c("PIED", "JUSO"), c(0.7, 0.3), 20, 5, 2.5
  )
  expect_equal(nrow(new_trees), nrow(trees) + 1)
})

# ==========================================================================
# calc_mortality_probability
# ==========================================================================

test_that("calc_mortality_probability returns vector in [0,1]", {
  trees <- data.table(
    DBH = c(5, 10, 20, 40, 60),
    Species = c("PIED", "JUMO", "JUSO", "PIED", "JUMO")
  )
  p <- calc_mortality_probability(trees)
  expect_length(p, nrow(trees))
  expect_true(all(p >= 0 & p <= 1))
})

test_that("calc_mortality_probability: small DBH has higher probability", {
  trees <- data.table(
    DBH = c(5, 60),
    Species = c("PIED", "PIED")
  )
  p <- calc_mortality_probability(trees)
  expect_true(p[1] > p[2])
})

test_that("calc_mortality_probability handles unknown species", {
  trees <- data.table(DBH = c(20), Species = c("UNKNOWN"))
  p <- calc_mortality_probability(trees)
  expect_equal(p, 0.1)
})

# ==========================================================================
# simulate_mortality
# ==========================================================================

test_that("simulate_mortality adds Status column", {
  trees <- calc_tree_attributes(make_test_trees(30))
  result <- simulate_mortality(trees, target_mortality_prop = 0.20)
  expect_true("Status" %in% names(result))
  expect_true(all(result$Status %in% c("live", "dead")))
})

test_that("simulate_mortality achieves target proportion", {
  trees <- calc_tree_attributes(make_test_trees(100, plot_size = 30))
  result <- simulate_mortality(trees, target_mortality_prop = 0.25)
  n_dead <- sum(result$Status == "dead")
  expect_equal(n_dead, round(100 * 0.25))
})

test_that("simulate_mortality with 0 prop kills none", {
  trees <- calc_tree_attributes(make_test_trees(20))
  result <- simulate_mortality(trees, target_mortality_prop = 0)
  expect_true(all(result$Status == "live"))
})

# ==========================================================================
# simulate_stand (short runs only)
# ==========================================================================

test_that("simulate_stand returns expected structure", {
  config <- pj_huffman_2009(max_iterations = 100)
  set.seed(42)
  result <- simulate_stand(
    targets        = config$targets,
    weights        = config$weights,
    plot_size      = 20,
    max_iterations = 100,
    verbose        = FALSE,
    plot_interval  = NULL
  )

  expect_type(result, "list")
  expect_true("trees" %in% names(result))
  expect_true("energy" %in% names(result))
  expect_true("history" %in% names(result))
  expect_true("metrics" %in% names(result))
  expect_true("targets" %in% names(result))
  expect_true(is.data.table(result$trees))
  expect_true(nrow(result$trees) > 0)
  expect_true(is.numeric(result$energy))
})

test_that("simulate_stand trees have required columns", {
  config <- pj_huffman_2009(max_iterations = 50)
  set.seed(1)
  result <- simulate_stand(
    targets        = config$targets,
    weights        = config$weights,
    plot_size      = 20,
    max_iterations = 50,
    verbose        = FALSE,
    plot_interval  = NULL
  )
  needed <- c("x", "y", "Species", "DBH", "Height",
              "CrownRadius", "CrownBaseHeight")
  for (col in needed) {
    expect_true(col %in% names(result$trees), info = paste("missing", col))
  }
})

test_that("simulate_stand with mortality adds Status column", {
  config <- pj_huffman_2009(max_iterations = 50)
  set.seed(1)
  result <- simulate_stand(
    targets        = config$targets,
    weights        = config$weights,
    plot_size      = 20,
    max_iterations = 50,
    verbose        = FALSE,
    plot_interval  = NULL,
    mortality_prop = 0.15
  )
  expect_true("Status" %in% names(result$trees))
  expect_true(any(result$trees$Status == "dead"))
})

# ==========================================================================
# print_simulation_summary
# ==========================================================================

test_that("print_simulation_summary runs without error", {
  config <- pj_huffman_2009(max_iterations = 50)
  set.seed(1)
  result <- simulate_stand(
    targets = config$targets, weights = config$weights,
    plot_size = 20, max_iterations = 50,
    verbose = FALSE, plot_interval = NULL
  )
  expect_no_error(print_simulation_summary(result))
})

# ==========================================================================
# plot_simulation_results
# ==========================================================================

test_that("plot_simulation_results runs without error", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("gridExtra")

  config <- pj_huffman_2009(max_iterations = 50)
  set.seed(1)
  result <- simulate_stand(
    targets = config$targets, weights = config$weights,
    plot_size = 20, max_iterations = 50,
    verbose = FALSE, plot_interval = NULL
  )
  expect_no_error(plot_simulation_results(result))
})

# ==========================================================================
# analyze_simulation_results
# ==========================================================================

test_that("analyze_simulation_results runs with save_plots = FALSE", {
  config <- pj_huffman_2009(max_iterations = 50)
  set.seed(1)
  result <- simulate_stand(
    targets = config$targets, weights = config$weights,
    plot_size = 20, max_iterations = 50,
    verbose = FALSE, plot_interval = NULL,
    mortality_prop = 0.15
  )

  out <- analyze_simulation_results(
    result, config$targets,
    prefix     = file.path(tempdir(), "test_sim"),
    save_plots = FALSE
  )

  expect_type(out, "list")
})
