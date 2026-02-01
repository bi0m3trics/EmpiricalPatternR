# Test performance utility functions

test_that("calc_canopy_cover_fast gives similar results to standard", {
  library(data.table)
  
  set.seed(123)
  x <- runif(50, 0, 20)
  y <- runif(50, 0, 20)
  crown_radius <- runif(50, 1, 3)
  
  cover_standard <- calc_canopy_cover(x, y, crown_radius, plot_size = 20)
  cover_fast <- calc_canopy_cover_fast(x, y, crown_radius, plot_size = 20)
  
  # Should be reasonably close (within 5%)
  expect_true(abs(cover_standard - cover_fast) < 0.05)
})

test_that("calc_tree_attributes_fast works correctly", {
  library(data.table)
  
  trees <- data.table(
    DBH = c(15, 20, 25),
    Species = c("PIED", "JUMO", "PIED")
  )
  
  result <- calc_tree_attributes_fast(trees)
  
  expect_true("Height" %in% names(result))
  expect_true("CrownRadius" %in% names(result))
  expect_true("CanopyFuelMass" %in% names(result))
  expect_equal(nrow(result), 3)
})

test_that("adaptive_temperature adjusts based on progress", {
  library(data.table)
  
  # Simulated history with good progress
  history_good <- data.table(
    iteration = 1:100,
    energy = 1000 - (1:100) * 5  # Decreasing energy
  )
  
  temp <- adaptive_temperature(100, 500, history_good, base_rate = 0.9999)
  
  expect_true(is.numeric(temp))
  expect_true(temp > 0)
})

test_that("should_full_update returns logical", {
  expect_true(should_full_update(10, batch_size = 10))
  expect_false(should_full_update(11, batch_size = 10))
  expect_true(should_full_update(20, batch_size = 10))
})
