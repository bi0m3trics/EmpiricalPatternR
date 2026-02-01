# Test allometric equations

test_that("calc_height returns reasonable values", {
  params <- get_default_allometric_params()
  
  # Test with different species and DBH
  h_pied <- calc_height(20, "PIED", params)
  h_jumo <- calc_height(20, "JUMO", params)
  
  expect_true(h_pied > 0)
  expect_true(h_jumo > 0)
  expect_true(h_pied < 50)  # Reasonable max height
  expect_true(h_jumo < 50)
})

test_that("calc_crown_radius requires height parameter", {
  params <- get_default_allometric_params()
  
  # Should work with height
  r <- calc_crown_radius(20, 8, "PIED", params)
  expect_true(r > 0)
  expect_true(r < 10)  # Reasonable max radius
})

test_that("calc_crown_base_height is less than height", {
  params <- get_default_allometric_params()
  
  dbh <- 20
  h <- calc_height(dbh, "PIED", params)
  cbh <- calc_crown_base_height(dbh, h, "PIED", params)
  
  expect_true(cbh >= 0)
  expect_true(cbh < h)
})

test_that("calc_canopy_fuel_mass returns positive values", {
  params <- get_default_allometric_params()
  
  mass <- calc_canopy_fuel_mass(20, "PIED", params)
  
  expect_true(mass > 0)
  expect_true(mass < 1000)  # Reasonable max (kg)
})

test_that("allometric equations work with vectors", {
  params <- get_default_allometric_params()
  
  dbh <- c(10, 15, 20, 25)
  species <- c("PIED", "PIED", "JUMO", "JUMO")
  
  heights <- calc_height(dbh, species, params)
  
  expect_equal(length(heights), 4)
  expect_true(all(heights > 0))
  expect_true(all(diff(heights[1:2]) > 0))  # Height increases with DBH
})
