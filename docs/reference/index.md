# Package index

## Quick Start

Main functions for running simulations and analyzing results.

- [`simulate_stand()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_stand.md)
  : Simulate Forest Stand with Simulated Annealing
- [`analyze_simulation_results()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/analyze_simulation_results.md)
  : Analyze and Report Simulation Results
- [`pj_huffman_2009()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/pj_huffman_2009.md)
  : Create Pinyon-Juniper Configuration (Huffman et al. 2009)

## Configuration System

Functions for creating, validating, and managing simulation
configurations.

- [`create_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/create_config.md)
  : Create Custom Simulation Configuration
- [`validate_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/validate_config.md)
  : Validate Configuration
- [`print_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/print_config.md)
  : Print Configuration Summary
- [`save_config()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/save_config.md)
  : Export Configuration to File
- [`generate_config_template()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/generate_config_template.md)
  : Generate Template Configuration File

## Allometric Equations

Functions for calculating tree attributes from DBH and species.

- [`calc_height()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_height.md)
  : Calculate tree height from DBH using allometric equations
- [`calc_crown_radius()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_radius.md)
  : Calculate crown radius from DBH and height using allometric
  equations
- [`calc_crown_base_height()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_base_height.md)
  : Calculate crown base height from DBH and total height
- [`calc_canopy_fuel_mass()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_fuel_mass.md)
  : Calculate canopy fuel mass from DBH
- [`get_default_allometric_params()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/get_default_allometric_params.md)
  : Get default allometric parameters for pinyon-juniper woodland
- [`get_ponderosa_allometric_params()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/get_ponderosa_allometric_params.md)
  : Get default allometric parameters for ponderosa pine forest
- [`allometric_equations`](https://bi0m3trics.github.io/EmpericalPatternR/reference/allometric_equations.md)
  : Allometric Equations for Forest Simulation

## Stand Metrics

Functions for calculating stand-level characteristics.

- [`calc_canopy_cover()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_cover.md)
  : Calculate total canopy cover accounting for overlap
- [`calc_canopy_cover_fast()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_cover_fast.md)
  : Fast Canopy Cover Calculation (Vectorized)
- [`calc_stand_metrics()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_stand_metrics.md)
  : Calculate all stand-level metrics
- [`calc_stand_metrics_parallel()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_stand_metrics_parallel.md)
  : Parallel Metric Calculation
- [`calc_clark_evans_fast()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_clark_evans_fast.md)
  : Fast Spatial Pattern Metrics
- [`calc_tree_attributes()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_tree_attributes.md)
  : Calculate all tree attributes from basic measurements
- [`calc_tree_attributes_fast()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_tree_attributes_fast.md)
  : Batch Tree Attribute Calculation

## Energy Calculation

Functions for evaluating how well a stand matches target patterns.

- [`calc_energy()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_energy.md)
  : Calculate energy (deviation from targets)
- [`calc_energy_cached()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_energy_cached.md)
  : Energy Calculation with Caching
- [`calc_mortality_probability()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_mortality_probability.md)
  : Calculate Size-Dependent Mortality Probability
- [`calc_nurse_tree_energy()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_nurse_tree_energy.md)
  : Calculate Nurse Tree Association Energy
- [`should_full_update()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/should_full_update.md)
  : Batch Update Check

## Perturbation Functions

Functions for modifying stand structure during optimization.

- [`perturb_add()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add.md)
  : Add a new tree
- [`perturb_remove()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_remove.md)
  : Remove a random tree
- [`perturb_move()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_move.md)
  : Move a random tree to a new location
- [`perturb_dbh()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_dbh.md)
  : Adjust DBH of a random tree
- [`perturb_species()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_species.md)
  : Change species of a random tree
- [`perturb_add_with_nurse()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add_with_nurse.md)
  : Add Tree with Nurse Tree Effect

## Mortality and History

Functions for simulating disturbance and tracking optimization.

- [`simulate_mortality()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_mortality.md)
  : Simulate Post-Disturbance Mortality
- [`update_history_efficient()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/update_history_efficient.md)
  : Memory-Efficient History Storage
- [`adaptive_temperature()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/adaptive_temperature.md)
  : Adaptive Temperature Schedule

## Visualization

Functions for plotting simulation results and progress.

- [`plot_simulation_results()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/plot_simulation_results.md)
  : Plot Simulation Results
- [`plot_progress()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/plot_progress.md)
  : Plot progress during simulation - showing objective progress
- [`print_simulation_summary()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/print_simulation_summary.md)
  : Print Simulation Summary

## Performance Utilities

Optimized versions of calculation functions.

- [`precompute_ce_table()`](https://bi0m3trics.github.io/EmpericalPatternR/reference/precompute_ce_table.md)
  : Pre-compute Clark-Evans Lookup Table

## Package Documentation

- [`EmpericalPatternR-package`](https://bi0m3trics.github.io/EmpericalPatternR/reference/EmpericalPatternR-package.md)
  [`EmpericalPatternR`](https://bi0m3trics.github.io/EmpericalPatternR/reference/EmpericalPatternR-package.md)
  : EmpericalPatternR: Forest Stand Pattern Simulation
