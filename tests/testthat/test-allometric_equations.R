# Tests for allometric equations
# Functions: get_default_allometric_params, get_ponderosa_allometric_params,
#            calc_height, calc_crown_radius, calc_crown_base_height,
#            calc_canopy_fuel_mass

# ==========================================================================
# get_default_allometric_params
# ==========================================================================

test_that("get_default_allometric_params returns valid structure", {
  params <- get_default_allometric_params()

  expect_type(params, "list")
  expect_true("crown_diameter" %in% names(params))
  expect_true("height" %in% names(params))
  expect_true("crown_ratio" %in% names(params))
  expect_true("crown_mass" %in% names(params))
  expect_true("cbh_method" %in% names(params))
  expect_true("foliage_method" %in% names(params))

  for (sp in c("PIED", "JUMO", "JUSO", "default")) {
    expect_true(sp %in% names(params$crown_diameter))
    expect_true(sp %in% names(params$height))
  }
})

test_that("get_default_allometric_params respects Reese CBH toggle", {
  params_reese <- get_default_allometric_params(use_reese_cbh = TRUE)
  expect_equal(params_reese$cbh_method, "reese_quadratic")
  expect_true("cbh_reese" %in% names(params_reese))

  params_simple <- get_default_allometric_params(use_reese_cbh = FALSE)
  expect_equal(params_simple$cbh_method, "simple_ratio")
  expect_true("cbh_ratio" %in% names(params_simple))
})

test_that("get_default_allometric_params respects Miller foliage toggle", {
  params_miller <- get_default_allometric_params(use_miller_foliage = TRUE)
  expect_equal(params_miller$foliage_method, "miller_1981")
  expect_true("foliage_miller" %in% names(params_miller))

  params_vol <- get_default_allometric_params(use_miller_foliage = FALSE)
  expect_equal(params_vol$foliage_method, "crown_volume")
})

# ==========================================================================
# get_ponderosa_allometric_params
# ==========================================================================

test_that("get_ponderosa_allometric_params returns valid structure", {
  params <- get_ponderosa_allometric_params()

  expect_type(params, "list")
  expect_true("PIPO" %in% names(params$crown_diameter))
  expect_true("PSME" %in% names(params$crown_diameter))
  expect_true("ABCO" %in% names(params$crown_diameter))
  expect_equal(params$cbh_method, "simple_ratio")
  expect_equal(params$foliage_method, "crown_volume")
})

# ==========================================================================
# calc_height
# ==========================================================================

test_that("calc_height returns reasonable values", {
  params <- get_default_allometric_params()

  h_pied <- calc_height(20, "PIED", params)
  h_jumo <- calc_height(20, "JUMO", params)

  expect_true(h_pied > 1.3)
  expect_true(h_jumo > 1.3)
  expect_true(h_pied < 20)
  expect_true(h_jumo < 20)
})

test_that("calc_height increases with DBH", {
  params <- get_default_allometric_params()
  h10 <- calc_height(10, "PIED", params)
  h30 <- calc_height(30, "PIED", params)
  expect_true(h30 > h10)
})

test_that("calc_height works with vectors", {
  params <- get_default_allometric_params()
  dbh <- c(10, 15, 20, 25)
  species <- c("PIED", "PIED", "JUMO", "JUMO")

  heights <- calc_height(dbh, species, params)

  expect_equal(length(heights), 4)
  expect_true(all(heights > 1.3))
  expect_true(heights[2] > heights[1])
  expect_true(heights[4] > heights[3])
})

test_that("calc_height uses default for unknown species", {
  params <- get_default_allometric_params()
  h <- calc_height(20, "UNKNOWN_SP", params)
  expect_true(is.numeric(h))
  expect_true(h > 1.3)
})

test_that("calc_height works with ponderosa params", {
  params <- get_ponderosa_allometric_params()
  h <- calc_height(40, "PIPO", params)
  expect_true(h > 10)
  expect_true(h < 50)
})

# ==========================================================================
# calc_crown_radius
# ==========================================================================

test_that("calc_crown_radius returns positive values", {
  params <- get_default_allometric_params()
  h <- calc_height(20, "PIED", params)
  r <- calc_crown_radius(20, h, "PIED", params)

  expect_true(r >= 0.3)
  expect_true(r < 20)
})

test_that("calc_crown_radius increases with DBH", {
  params <- get_default_allometric_params()
  h10 <- calc_height(10, "PIED", params)
  h30 <- calc_height(30, "PIED", params)
  r10 <- calc_crown_radius(10, h10, "PIED", params)
  r30 <- calc_crown_radius(30, h30, "PIED", params)

  expect_true(r30 > r10)
})

test_that("calc_crown_radius works with vectors", {
  params <- get_default_allometric_params()
  dbh <- c(10, 20, 30)
  species <- c("PIED", "JUMO", "JUSO")
  heights <- calc_height(dbh, species, params)
  radii <- calc_crown_radius(dbh, heights, species, params)

  expect_equal(length(radii), 3)
  expect_true(all(radii >= 0.3))
})

test_that("calc_crown_radius enforces minimum of 0.3", {
  params <- get_default_allometric_params()
  h <- calc_height(1, "PIED", params)
  r <- calc_crown_radius(1, h, "PIED", params)
  expect_true(r >= 0.3)
})

# ==========================================================================
# calc_crown_base_height
# ==========================================================================

test_that("calc_crown_base_height less than height (Reese method)", {
  params <- get_default_allometric_params(use_reese_cbh = TRUE)
  dbh <- 20
  h <- calc_height(dbh, "PIED", params)
  cbh <- calc_crown_base_height(dbh, h, "PIED", params)

  expect_true(cbh >= 1.3)
  expect_true(cbh < h)
})

test_that("calc_crown_base_height less than height (simple ratio)", {
  params <- get_default_allometric_params(use_reese_cbh = FALSE)
  dbh <- 20
  h <- calc_height(dbh, "PIED", params)
  cbh <- calc_crown_base_height(dbh, h, "PIED", params)

  expect_true(cbh >= 1.3)
  expect_true(cbh < h)
})

test_that("calc_crown_base_height works with vectors", {
  params <- get_default_allometric_params()
  dbh <- c(10, 20, 30)
  species <- rep("PIED", 3)
  heights <- calc_height(dbh, species, params)
  cbhs <- calc_crown_base_height(dbh, heights, species, params)

  expect_equal(length(cbhs), 3)
  expect_true(all(cbhs >= 1.3))
  expect_true(all(cbhs < heights))
})

test_that("calc_crown_base_height handles multiple species", {
  params <- get_default_allometric_params()
  dbh <- c(20, 20, 20)
  species <- c("PIED", "JUMO", "JUSO")
  heights <- calc_height(dbh, species, params)
  cbhs <- calc_crown_base_height(dbh, heights, species, params)

  expect_equal(length(cbhs), 3)
  expect_true(all(is.numeric(cbhs)))
})

# ==========================================================================
# calc_canopy_fuel_mass
# ==========================================================================

test_that("calc_canopy_fuel_mass positive (Miller method)", {
  params <- get_default_allometric_params(use_miller_foliage = TRUE)
  mass <- calc_canopy_fuel_mass(20, "PIED", params)

  expect_true(mass > 0)
  expect_true(mass < 500)
})

test_that("calc_canopy_fuel_mass positive (crown volume method)", {
  params <- get_default_allometric_params(use_miller_foliage = FALSE)
  mass <- calc_canopy_fuel_mass(20, "PIED", params)
  expect_true(mass > 0)
})

test_that("calc_canopy_fuel_mass increases with DBH", {
  params <- get_default_allometric_params()
  m10 <- calc_canopy_fuel_mass(10, "PIED", params)
  m30 <- calc_canopy_fuel_mass(30, "PIED", params)
  expect_true(m30 > m10)
})

test_that("calc_canopy_fuel_mass works with vectors", {
  params <- get_default_allometric_params()
  masses <- calc_canopy_fuel_mass(c(10, 20, 30), c("PIED", "JUSO", "JUMO"), params)

  expect_equal(length(masses), 3)
  expect_true(all(masses > 0))
})
