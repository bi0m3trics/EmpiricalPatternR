# Test forest simulation functions

test_that("calc_tree_attributes works correctly", {
  library(data.table)
  
  trees <- data.table(
    Number = 1:3,
    x = c(10, 20, 30),
    y = c(15, 25, 35),
    Species = c("PIED", "JUMO", "PIED"),
    DBH = c(15, 20, 25)
  )
  
  result <- calc_tree_attributes(trees)
  
  expect_true("Height" %in% names(result))
  expect_true("CrownRadius" %in% names(result))
  expect_true("CrownBaseHeight" %in% names(result))
  expect_true("CanopyFuelMass" %in% names(result))
  
  expect_equal(nrow(result), 3)
  expect_true(all(result$Height > 0))
  expect_true(all(result$CrownRadius > 0))
})

test_that("calc_stand_metrics computes all metrics", {
  library(data.table)
  
  trees <- data.table(
    Number = 1:10,
    x = runif(10, 0, 20),
    y = runif(10, 0, 20),
    Species = sample(c("PIED", "JUMO"), 10, replace = TRUE),
    DBH = rnorm(10, 20, 5)
  )
  trees$DBH <- pmax(trees$DBH, 5)
  
  trees <- calc_tree_attributes(trees)
  metrics <- calc_stand_metrics(trees, plot_size = 20)
  
  expect_type(metrics, "list")
  expect_true("density_ha" %in% names(metrics))
  expect_true("mean_dbh" %in% names(metrics))
  expect_true("canopy_cover" %in% names(metrics))
  expect_true("cfl" %in% names(metrics))
  expect_true("cbd" %in% names(metrics))
  
  expect_true(metrics$density_ha > 0)
  expect_true(metrics$cfl >= 0)
  expect_true(metrics$cbd >= 0)
})

test_that("simulate_mortality works correctly", {
  library(data.table)
  
  trees <- data.table(
    Number = 1:20,
    x = runif(20, 0, 20),
    y = runif(20, 0, 20),
    Species = sample(c("PIED", "JUMO"), 20, replace = TRUE),
    DBH = rnorm(20, 20, 5)
  )
  trees$DBH <- pmax(trees$DBH, 5)
  trees <- calc_tree_attributes(trees)
  
  result <- simulate_mortality(trees, target_mortality_prop = 0.20)
  
  expect_true("Status" %in% names(result))
  n_dead <- sum(result$Status == "dead")
  n_total <- nrow(result)
  
  # Should be approximately 20% mortality (allow some variation)
  expect_true(n_dead >= n_total * 0.1)
  expect_true(n_dead <= n_total * 0.3)
})

test_that("perturbation functions preserve tree count", {
  library(data.table)
  
  trees <- data.table(
    Number = 1:10,
    x = runif(10, 0, 20),
    y = runif(10, 0, 20),
    Species = sample(c("PIED", "JUMO"), 10, replace = TRUE),
    DBH = rnorm(10, 20, 5)
  )
  
  # Move should preserve count
  trees_moved <- perturb_move(trees, plot_size = 20)
  expect_equal(nrow(trees_moved), nrow(trees))
  
  # Species should preserve count
  trees_species <- perturb_species(trees, c("PIED", "JUMO"), c(0.7, 0.3))
  expect_equal(nrow(trees_species), nrow(trees))
  
  # DBH should preserve count
  trees_dbh <- perturb_dbh(trees, dbh_sd_perturb = 2)
  expect_equal(nrow(trees_dbh), nrow(trees))
  
  # Add should increase count
  trees_add <- perturb_add(trees, 20, c("PIED", "JUMO"), c(0.7, 0.3), 20, 5)
  expect_equal(nrow(trees_add), nrow(trees) + 1)
  
  # Remove should decrease count  
  trees_remove <- perturb_remove(trees, min_trees = 5)
  expect_equal(nrow(trees_remove), nrow(trees) - 1)
})
