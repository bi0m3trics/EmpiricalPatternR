# Tests for performance utility functions
# Exported: calc_canopy_cover_fast, calc_tree_attributes_fast, calc_stand_metrics_parallel
# Internal: calc_energy_cached, precompute_ce_table, calc_clark_evans_fast,
#           adaptive_temperature, should_full_update, update_history_efficient

library(data.table)

# ==========================================================================
# calc_canopy_cover_fast
# ==========================================================================

test_that("calc_canopy_cover_fast returns proportion in [0, 1]", {
  set.seed(1)
  cc <- calc_canopy_cover_fast(
    x = runif(15, 0, 20), y = runif(15, 0, 20),
    crown_radius = rep(2, 15), plot_size = 20
  )
  expect_true(cc >= 0 && cc <= 1)
})

test_that("calc_canopy_cover_fast increases with crown size", {
  set.seed(1)
  x <- runif(5, 2, 18)
  y <- runif(5, 2, 18)
  cc_s <- calc_canopy_cover_fast(x, y, rep(1, 5), 20)
  cc_l <- calc_canopy_cover_fast(x, y, rep(5, 5), 20)
  expect_true(cc_l > cc_s)
})

test_that("calc_canopy_cover_fast agrees with calc_canopy_cover", {
  set.seed(42)
  x <- runif(10, 0, 20)
  y <- runif(10, 0, 20)
  cr <- runif(10, 1, 3)
  cc_orig <- calc_canopy_cover(x, y, cr, 20)
  cc_fast <- calc_canopy_cover_fast(x, y, cr, 20)
  expect_equal(cc_orig, cc_fast, tolerance = 0.05)
})

# ==========================================================================
# calc_tree_attributes_fast
# ==========================================================================

test_that("calc_tree_attributes_fast adds required columns", {
  trees <- data.table(
    Number  = 1:5,
    x       = 1:5,
    y       = 1:5,
    Species = c("PIED", "JUSO", "PIED", "JUMO", "PIED"),
    DBH     = c(15, 20, 25, 30, 35)
  )
  result <- calc_tree_attributes_fast(trees)
  needed <- c("Height", "CrownRadius", "CrownDiameter",
              "CrownArea", "CrownBaseHeight", "CrownLength",
              "CanopyFuelMass")
  for (col in needed) {
    expect_true(col %in% names(result), info = paste("missing", col))
  }
})

test_that("calc_tree_attributes_fast produces positive values", {
  trees <- data.table(DBH = c(10, 20, 30), Species = c("PIED", "PIED", "JUSO"))
  result <- calc_tree_attributes_fast(trees)
  expect_true(all(result$Height > 0))
  expect_true(all(result$CrownRadius > 0))
  expect_true(all(result$CrownArea > 0))
})

test_that("calc_tree_attributes_fast does not modify input", {
  trees <- data.table(
    Number  = 1:3, x = 1:3, y = 1:3,
    Species = "PIED", DBH = c(15, 20, 25)
  )
  orig <- copy(trees)
  calc_tree_attributes_fast(trees)
  expect_identical(trees, orig)
})

test_that("calc_tree_attributes_fast matches calc_tree_attributes", {
  trees <- data.table(
    Number  = 1:5, x = 1:5, y = 1:5,
    Species = c("PIED", "JUSO", "PIED", "JUMO", "PIED"),
    DBH     = c(10, 15, 20, 25, 30)
  )
  r1 <- calc_tree_attributes(trees)
  r2 <- calc_tree_attributes_fast(trees)
  expect_equal(r1$Height, r2$Height, tolerance = 1e-6)
  expect_equal(r1$CrownRadius, r2$CrownRadius, tolerance = 1e-6)
  expect_equal(r1$CanopyFuelMass, r2$CanopyFuelMass, tolerance = 1e-6)
})

# ==========================================================================
# calc_stand_metrics_parallel
# ==========================================================================

test_that("calc_stand_metrics_parallel returns all expected metrics", {
  set.seed(1)
  trees <- data.table(
    Number  = 1:10,
    x       = runif(10, 0, 20),
    y       = runif(10, 0, 20),
    Species = sample(c("PIED", "JUMO"), 10, replace = TRUE),
    DBH     = pmax(rnorm(10, 20, 5), 5)
  )
  trees <- calc_tree_attributes(trees)
  m <- calc_stand_metrics_parallel(trees, plot_size = 20)

  expect_type(m, "list")
  needed <- c("clark_evans_r", "mean_dbh", "sd_dbh",
              "canopy_cover", "cfl", "density_ha")
  for (k in needed) {
    expect_true(k %in% names(m), info = paste("missing", k))
  }
})

test_that("calc_stand_metrics_parallel matches calc_stand_metrics for small stands", {
  set.seed(1)
  trees <- data.table(
    Number  = 1:15,
    x       = runif(15, 0, 20),
    y       = runif(15, 0, 20),
    Species = sample(c("PIED", "JUSO"), 15, replace = TRUE),
    DBH     = pmax(rnorm(15, 20, 5), 5)
  )
  trees <- calc_tree_attributes(trees)
  m1 <- calc_stand_metrics(trees, 20)
  m2 <- calc_stand_metrics_parallel(trees, 20)
  expect_equal(m1$density_ha, m2$density_ha)
  expect_equal(m1$mean_dbh, m2$mean_dbh)
})

# ==========================================================================
# Internal: should_full_update
# ==========================================================================

test_that("should_full_update returns TRUE on multiples of batch_size", {
  expect_true(EmpiricalPatternR:::should_full_update(10, 10))
  expect_true(EmpiricalPatternR:::should_full_update(20, 10))
  expect_false(EmpiricalPatternR:::should_full_update(11, 10))
})

# ==========================================================================
# Internal: adaptive_temperature
# ==========================================================================

test_that("adaptive_temperature returns positive numeric", {
  history <- data.table(iteration = 1:10, energy = 10:1)
  temp <- EmpiricalPatternR:::adaptive_temperature(5, 3, history)
  expect_type(temp, "double")
  expect_true(temp > 0)
})

# ==========================================================================
# Internal: calc_clark_evans_fast
# ==========================================================================

test_that("calc_clark_evans_fast returns NA for < 2 points", {
  r <- EmpiricalPatternR:::calc_clark_evans_fast(5, 5, 20)
  expect_true(is.na(r))
})

test_that("calc_clark_evans_fast returns positive number", {
  set.seed(1)
  r <- EmpiricalPatternR:::calc_clark_evans_fast(
    runif(20, 0, 20), runif(20, 0, 20), 20
  )
  expect_true(is.numeric(r) && r > 0)
})
