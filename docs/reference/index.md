# Package index

## Quick Start

Main functions for running simulations and analyzing results.

<!-- end list -->

  - `simulate_stand()` : Simulate Forest Stand with Simulated Annealing
  - `analyze_simulation_results()` : Analyze and Report Simulation
    Results
  - `pj_huffman_2009()` : Create Pinyon-Juniper Configuration (Huffman
    et al. 2009)

## Configuration System

Functions for creating, validating, and managing simulation
configurations.

<!-- end list -->

  - `create_config()` : Create Custom Simulation Configuration
  - `validate_config()` : Validate Configuration
  - `print_config()` : Print Configuration Summary
  - `save_config()` : Export Configuration to File
  - `generate_config_template()` : Generate Template Configuration File

## Allometric Equations

Functions for calculating tree attributes from DBH and species.

<!-- end list -->

  - `calc_height()` : Calculate tree height from DBH using allometric
    equations
  - `calc_crown_radius()` : Calculate crown radius from DBH and height
    using allometric equations
  - `calc_crown_base_height()` : Calculate crown base height from DBH
    and total height
  - `calc_canopy_fuel_mass()` : Calculate canopy fuel mass from DBH
  - `get_default_allometric_params()` : Get default allometric
    parameters for pinyon-juniper woodland
  - `get_ponderosa_allometric_params()` : Get default allometric
    parameters for ponderosa pine forest
  - `allometric_equations` : Allometric Equations for Forest Simulation

## Stand Metrics

Functions for calculating stand-level characteristics.

<!-- end list -->

  - `calc_canopy_cover()` : Calculate total canopy cover accounting for
    overlap
  - `calc_canopy_cover_fast()` : Fast Canopy Cover Calculation
    (Vectorized)
  - `calc_stand_metrics()` : Calculate all stand-level metrics
  - `calc_stand_metrics_parallel()` : Parallel Metric Calculation
  - `calc_clark_evans_fast()` : Fast Spatial Pattern Metrics
  - `calc_tree_attributes()` : Calculate all tree attributes from basic
    measurements
  - `calc_tree_attributes_fast()` : Batch Tree Attribute Calculation

## Energy Calculation

Functions for evaluating how well a stand matches target patterns.

<!-- end list -->

  - `calc_energy()` : Calculate energy (deviation from targets)
  - `calc_energy_cached()` : Energy Calculation with Caching
  - `calc_mortality_probability()` : Calculate Size-Dependent Mortality
    Probability
  - `calc_nurse_tree_energy()` : Calculate Nurse Tree Association Energy
  - `should_full_update()` : Batch Update Check

## Perturbation Functions

Functions for modifying stand structure during optimization.

<!-- end list -->

  - `perturb_add()` : Add a new tree
  - `perturb_remove()` : Remove a random tree
  - `perturb_move()` : Move a random tree to a new location
  - `perturb_dbh()` : Adjust DBH of a random tree
  - `perturb_species()` : Change species of a random tree
  - `perturb_add_with_nurse()` : Add Tree with Nurse Tree Effect

## Mortality and History

Functions for simulating disturbance and tracking optimization.

<!-- end list -->

  - `simulate_mortality()` : Simulate Post-Disturbance Mortality
  - `update_history_efficient()` : Memory-Efficient History Storage
  - `adaptive_temperature()` : Adaptive Temperature Schedule

## Visualization

Functions for plotting simulation results and progress.

<!-- end list -->

  - `plot_simulation_results()` : Plot Simulation Results
  - `plot_progress()` : Plot progress during simulation - showing
    objective progress
  - `print_simulation_summary()` : Print Simulation Summary

## Performance Utilities

Optimized versions of calculation functions.

<!-- end list -->

  - `precompute_ce_table()` : Pre-compute Clark-Evans Lookup Table

## Package Documentation

<!-- end list -->

  - `EmpericalPatternR-package` `EmpericalPatternR` : EmpericalPatternR:
    Forest Stand Pattern Simulation
