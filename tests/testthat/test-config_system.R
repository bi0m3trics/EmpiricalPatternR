# Test configuration system

test_that("pj_huffman_2009 creates valid configuration", {
  config <- pj_huffman_2009()
  
  expect_type(config, "list")
  expect_true("targets" %in% names(config))
  expect_true("weights" %in% names(config))
  expect_true("simulation" %in% names(config))
  
  # Check targets
  expect_true(config$targets$density_ha > 0)
  expect_true(config$targets$canopy_cover >= 0)
  expect_true(config$targets$canopy_cover <= 1)
  
  # Check simulation parameters
  expect_true(config$simulation$max_iterations > 0)
  expect_true(config$simulation$cooling_rate > 0)
  expect_true(config$simulation$cooling_rate < 1)
})

test_that("pj_huffman_2009 accepts custom parameters", {
  config <- pj_huffman_2009(
    density_ha = 500,
    cfl = 2.0,
    max_iterations = 1000
  )
  
  expect_equal(config$targets$density_ha, 500)
  expect_equal(config$targets$cfl, 2.0)
  expect_equal(config$simulation$max_iterations, 1000)
})

test_that("validate_config works correctly", {
  config <- pj_huffman_2009()
  
  expect_true(validate_config(config))
})

test_that("print_config runs without error", {
  config <- pj_huffman_2009()
  
  # Just expect it not to throw an error
  expect_no_error(print_config(config))
})
