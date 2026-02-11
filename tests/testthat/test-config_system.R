# Tests for configuration system
# Functions: pj_huffman_2009, create_config, print_config, validate_config,
#            save_config, generate_config_template

# ==========================================================================
# pj_huffman_2009
# ==========================================================================

test_that("pj_huffman_2009 creates valid configuration", {
  config <- pj_huffman_2009()

  expect_type(config, "list")
  expect_true("targets" %in% names(config))
  expect_true("weights" %in% names(config))
  expect_true("simulation" %in% names(config))
  expect_true("allometric_params" %in% names(config))

  # Targets
  expect_true(config$targets$density_ha > 0)
  expect_true(config$targets$canopy_cover >= 0)
  expect_true(config$targets$canopy_cover <= 1)
  expect_equal(sum(config$targets$species_props), 1.0)
  expect_equal(names(config$targets$species_props), c("PIED", "JUSO"))

  # Simulation
  expect_true(config$simulation$max_iterations > 0)
  expect_true(config$simulation$cooling_rate > 0)
  expect_true(config$simulation$cooling_rate < 1)
})

test_that("pj_huffman_2009 accepts custom parameters", {
  config <- pj_huffman_2009(
    density_ha     = 500,
    cfl            = 2.0,
    canopy_cover   = 0.50,
    mean_dbh       = 25.0,
    max_iterations = 1000,
    plot_interval  = 500,
    enable_plotting = FALSE
  )

  expect_equal(config$targets$density_ha, 500)
  expect_equal(config$targets$cfl, 2.0)
  expect_equal(config$targets$canopy_cover, 0.50)
  expect_equal(config$targets$mean_dbh, 25.0)
  expect_equal(config$simulation$max_iterations, 1000)
  expect_equal(config$simulation$plot_interval, 500)
  expect_false(config$simulation$enable_plotting)
})

test_that("pj_huffman_2009 includes allometric params", {
  config <- pj_huffman_2009()
  expect_true("crown_diameter" %in% names(config$allometric_params))
  expect_true("height" %in% names(config$allometric_params))
})

# ==========================================================================
# create_config
# ==========================================================================

test_that("create_config with defaults returns valid config", {
  config <- create_config()

  expect_type(config, "list")
  expect_true("targets" %in% names(config))
  expect_true("weights" %in% names(config))
  expect_true("simulation" %in% names(config))
  expect_true("allometric_params" %in% names(config))
  expect_equal(config$name, "Custom")
})

test_that("create_config with custom name", {
  config <- create_config(name = "My Test Config")
  expect_equal(config$name, "My Test Config")
})

test_that("create_config accepts all custom components", {
  my_targets <- list(
    density_ha    = 600,
    species_props = c(SP1 = 0.5, SP2 = 0.5),
    species_names = c("SP1", "SP2"),
    mean_dbh = 30, sd_dbh = 10,
    mean_height = 12, sd_height = 4,
    canopy_cover = 0.55, cfl = 1.2,
    clark_evans_r = 1.1
  )
  my_weights <- list(
    ce = 20, dbh_mean = 10, dbh_sd = 10,
    height_mean = 10, height_sd = 5,
    species = 80, canopy_cover = 80,
    cfl = 70, density = 90, nurse_effect = 0
  )
  my_sim <- list(
    plot_size = 50, max_iterations = 500,
    temp_initial = 10, temp_final = 0.001,
    cooling_rate = 0.999, plot_interval = 100,
    verbose = FALSE, enable_plotting = FALSE,
    nurse_distance = 0, use_nurse_effect = FALSE,
    mortality_prop = 0.10
  )

  config <- create_config(
    name       = "Custom Full",
    targets    = my_targets,
    weights    = my_weights,
    simulation = my_sim
  )

  expect_equal(config$targets$density_ha, 600)
  expect_equal(config$weights$species, 80)
  expect_equal(config$simulation$plot_size, 50)
  expect_equal(config$name, "Custom Full")
})

# ==========================================================================
# validate_config
# ==========================================================================

test_that("validate_config returns TRUE for valid config", {
  config <- pj_huffman_2009()
  expect_true(validate_config(config))
})

test_that("validate_config returns TRUE for create_config default", {
  config <- create_config()
  expect_true(validate_config(config))
})

test_that("validate_config detects missing components", {
  config <- list(targets = list(), weights = list())
  expect_error(validate_config(config), "missing required components")
})

test_that("validate_config detects missing target fields", {
  config <- pj_huffman_2009()
  config$targets$density_ha <- NULL
  expect_error(validate_config(config), "missing required fields")
})

test_that("validate_config detects negative density", {
  config <- pj_huffman_2009()
  config$targets$density_ha <- -100
  expect_error(validate_config(config), "positive")
})

test_that("validate_config detects invalid canopy cover", {
  config <- pj_huffman_2009()
  config$targets$canopy_cover <- 1.5
  expect_error(validate_config(config), "between 0 and 1")
})

test_that("validate_config warns on species_props not summing to 1", {
  config <- pj_huffman_2009()
  config$targets$species_props <- c(PIED = 0.5, JUSO = 0.3)
  expect_warning(validate_config(config), "do not sum to 1")
})

test_that("validate_config detects non-positive max_iterations", {
  config <- pj_huffman_2009()
  config$simulation$max_iterations <- 0
  expect_error(validate_config(config), "positive")
})

test_that("validate_config detects non-positive plot_size", {
  config <- pj_huffman_2009()
  config$simulation$plot_size <- -10
  expect_error(validate_config(config), "positive")
})

# ==========================================================================
# print_config
# ==========================================================================

test_that("print_config runs without error", {
  config <- pj_huffman_2009()
  expect_no_error(print_config(config))
})

test_that("print_config returns config invisibly", {
  config <- pj_huffman_2009()
  out <- print_config(config)
  expect_identical(out, config)
})

# ==========================================================================
# save_config
# ==========================================================================

test_that("save_config writes a file and returns invisibly", {
  config <- pj_huffman_2009()
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))

  result <- save_config(config, tmp)
  expect_true(file.exists(tmp))
  expect_identical(result, config)

  content <- readLines(tmp)
  expect_true(any(grepl("Auto-generated", content)))
  expect_true(any(grepl("EmpiricalPatternR", content)))
})

# ==========================================================================
# generate_config_template
# ==========================================================================

test_that("generate_config_template creates PJ template", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))

  result <- generate_config_template(tmp, "test_config", base_config = "pj")

  expect_true(file.exists(tmp))
  content <- readLines(tmp)
  expect_true(any(grepl("test_config", content)))
  expect_true(any(grepl("PIED", content)))
})

test_that("generate_config_template creates custom template", {
  tmp <- tempfile(fileext = ".R")
  on.exit(unlink(tmp))

  result <- generate_config_template(tmp, "blank_config", base_config = "custom")

  expect_true(file.exists(tmp))
  content <- readLines(tmp)
  expect_true(any(grepl("blank_config", content)))
})
