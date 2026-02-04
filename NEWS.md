# EmpiricalPatternR 0.1.0

## Major Changes

### Documentation
* Added comprehensive pkgdown documentation website
* Created three detailed vignettes:
  - `getting-started`: Installation, quick start, and configuration basics
  - `pinyon-juniper`: Complete workflow for P-J woodland simulations with nurse effects
  - `ponderosa-pine`: Custom configurations for different forest types
* Enhanced README with:
  - Professional badges (R-CMD-check, License)
  - Package logo and banner image
  - Quick start examples
  - Workflow diagram
  - Performance benchmarks table
  - Updated citations to Pommerening (2006, 2008) framework
* Organized function reference into 9 logical topic groups
* Created deployment documentation:
  - `DOCUMENTATION_SUMMARY.md`: Technical build summary
  - `GETTING_STARTED_WITH_DOCS.md`: User-friendly documentation guide
  - `DEPLOYMENT_CHECKLIST.md`: GitHub Pages deployment steps

### Package Infrastructure
* Added `build_pkgdown.R` helper script for easy documentation rebuilding
* Updated DESCRIPTION with pkgdown URL and vignette support
* Added knitr and rmarkdown to Suggests for vignette building
* Configured VignetteBuilder for proper vignette compilation
* Added package logo (`man/figures/logo.png`)
* Added package banner (`man/figures/banner.png`)

### Project Organization
* Moved example R files to `misc/` folder:
  - `example_pjwoodland_simulation.R`
  - `my_simulation.R`
  - `run_example.R`
  - `test_template.R`
* Cleaned up root directory for better package structure

### License
* Changed license from MIT to GPL-3
* Added LICENSE file with full GPL-3 text

### Citations
* Updated from empirical data citations (Huffman, Reese, Miller, Grier) to methodological framework:
  - Pommerening, A., 2006. Evaluating structural indices by reversing forest structural analysis
  - Pommerening, A. and Stoyan, D., 2008. Reconstructing spatial tree point patterns from nearest neighbour summary statistics

## Initial Release (0.1.0)

### Core Features
* Simulated annealing optimization for forest stand pattern matching
* Pre-built configuration for pinyon-juniper woodlands (`pj_huffman_2009()`)
* Flexible configuration system with `create_config()`
* Species-specific allometric equations
* OpenMP-parallelized C++ functions for performance
* Canopy fuel load (CFL) optimization
* Nurse tree effects for facilitation patterns
* Comprehensive analysis and visualization functions
* 62 unit tests covering all major functions

### Functions
* **Quick Start**: `pj_huffman_2009()`, `simulate_stand()`
* **Configuration**: `create_config()`, `validate_config()`, `print_config()`, `save_config()`
* **Allometry**: `calc_height()`, `calc_crown_radius()`, `calc_crown_base_height()`, `calc_canopy_fuel_mass()`
* **Stand Metrics**: `calc_stand_metrics()`, `calc_canopy_cover()`, `calc_clark_evans_fast()`
* **Energy Calculation**: `calc_energy()`, `calc_energy_cached()`, `calc_nurse_tree_energy()`
* **Perturbations**: `perturb_add()`, `perturb_remove()`, `perturb_move()`, `perturb_dbh()`, `perturb_species()`, `perturb_add_with_nurse()`
* **Analysis**: `analyze_simulation_results()`, `plot_simulation_results()`, `plot_progress()`
* **Utilities**: `adaptive_temperature()`, `precompute_ce_table()`, Performance optimization functions
