# Changelog

## EmpericalPatternR 0.1.0

### Major Changes

#### Documentation

- Added comprehensive pkgdown documentation website
- Created three detailed vignettes:
  - `getting-started`: Installation, quick start, and configuration
    basics
  - `pinyon-juniper`: Complete workflow for P-J woodland simulations
    with nurse effects
  - `ponderosa-pine`: Custom configurations for different forest types
- Enhanced README with:
  - Professional badges (R-CMD-check, License)
  - Package logo and banner image
  - Quick start examples
  - Workflow diagram
  - Performance benchmarks table
  - Updated citations to Pommerening (2006, 2008) framework
- Organized function reference into 9 logical topic groups
- Created deployment documentation:
  - `DOCUMENTATION_SUMMARY.md`: Technical build summary
  - `GETTING_STARTED_WITH_DOCS.md`: User-friendly documentation guide
  - `DEPLOYMENT_CHECKLIST.md`: GitHub Pages deployment steps

#### Package Infrastructure

- Added `build_pkgdown.R` helper script for easy documentation
  rebuilding
- Updated DESCRIPTION with pkgdown URL and vignette support
- Added knitr and rmarkdown to Suggests for vignette building
- Configured VignetteBuilder for proper vignette compilation
- Added package logo (`man/figures/logo.png`)
- Added package banner (`man/figures/banner.png`)

#### Project Organization

- Moved example R files to `misc/` folder:
  - `example_pjwoodland_simulation.R`
  - `my_simulation.R`
  - `run_example.R`
  - `test_template.R`
- Cleaned up root directory for better package structure

#### License

- Changed license from MIT to GPL-3
- Added LICENSE file with full GPL-3 text

#### Citations

- Updated from empirical data citations (Huffman, Reese, Miller, Grier)
  to methodological framework:
  - Pommerening, A., 2006. Evaluating structural indices by reversing
    forest structural analysis
  - Pommerening, A. and Stoyan, D., 2008. Reconstructing spatial tree
    point patterns from nearest neighbour summary statistics

### Initial Release (0.1.0)

#### Core Features

- Simulated annealing optimization for forest stand pattern matching
- Pre-built configuration for pinyon-juniper woodlands
  ([`pj_huffman_2009()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/pj_huffman_2009.md))
- Flexible configuration system with
  [`create_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/create_config.md)
- Species-specific allometric equations
- OpenMP-parallelized C++ functions for performance
- Canopy fuel load (CFL) optimization
- Nurse tree effects for facilitation patterns
- Comprehensive analysis and visualization functions
- 62 unit tests covering all major functions

#### Functions

- **Quick Start**:
  [`pj_huffman_2009()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/pj_huffman_2009.md),
  [`simulate_stand()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_stand.md)
- **Configuration**:
  [`create_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/create_config.md),
  [`validate_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/validate_config.md),
  [`print_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/print_config.md),
  [`save_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/save_config.md)
- **Allometry**:
  [`calc_height()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_height.md),
  [`calc_crown_radius()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_radius.md),
  [`calc_crown_base_height()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_base_height.md),
  [`calc_canopy_fuel_mass()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_fuel_mass.md)
- **Stand Metrics**:
  [`calc_stand_metrics()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_stand_metrics.md),
  [`calc_canopy_cover()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_cover.md),
  [`calc_clark_evans_fast()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_clark_evans_fast.md)
- **Energy Calculation**:
  [`calc_energy()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_energy.md),
  [`calc_energy_cached()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_energy_cached.md),
  [`calc_nurse_tree_energy()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_nurse_tree_energy.md)
- **Perturbations**:
  [`perturb_add()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add.md),
  [`perturb_remove()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_remove.md),
  [`perturb_move()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_move.md),
  [`perturb_dbh()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_dbh.md),
  [`perturb_species()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_species.md),
  [`perturb_add_with_nurse()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add_with_nurse.md)
- **Analysis**:
  [`analyze_simulation_results()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/analyze_simulation_results.md),
  [`plot_simulation_results()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/plot_simulation_results.md),
  [`plot_progress()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/plot_progress.md)
- **Utilities**:
  [`adaptive_temperature()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/adaptive_temperature.md),
  [`precompute_ce_table()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/precompute_ce_table.md),
  Performance optimization functions
