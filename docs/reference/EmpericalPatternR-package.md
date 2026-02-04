# EmpericalPatternR: Forest Stand Pattern Simulation

Simulates realistic forest stand patterns using simulated annealing
optimization to match empirical targets for spatial patterns, canopy
structure, species composition, and fire behavior metrics.

## Main Functions

\*\*Simulation:\*\*

- [`simulate_stand`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_stand.md):
  Run complete stand simulation

- [`simulate_mortality`](https://bi0m3trics.github.io/EmpericalPatternR/reference/simulate_mortality.md):
  Add post-disturbance mortality

\*\*Stand Metrics:\*\*

- [`calc_stand_metrics`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_stand_metrics.md):
  Compute all stand-level metrics

- [`calc_tree_attributes`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_tree_attributes.md):
  Calculate tree attributes from DBH

- [`calc_canopy_cover`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_cover.md):
  Canopy cover with overlap handling

\*\*Allometric Equations:\*\*

- [`calc_crown_radius`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_radius.md):
  Crown radius from DBH

- [`calc_height`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_height.md):
  Tree height from DBH

- [`calc_crown_base_height`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_crown_base_height.md):
  Crown base height

- [`calc_canopy_fuel_mass`](https://bi0m3trics.github.io/EmpericalPatternR/reference/calc_canopy_fuel_mass.md):
  Foliage biomass

- [`get_default_allometric_params`](https://bi0m3trics.github.io/EmpericalPatternR/reference/get_default_allometric_params.md):
  Default pinyon-juniper parameters

- [`get_ponderosa_allometric_params`](https://bi0m3trics.github.io/EmpericalPatternR/reference/get_ponderosa_allometric_params.md):
  Ponderosa pine parameters

\*\*Perturbation Operations:\*\*

- [`perturb_move`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_move.md):
  Move tree to new location

- [`perturb_species`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_species.md):
  Change tree species

- [`perturb_dbh`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_dbh.md):
  Adjust tree diameter

- [`perturb_add`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add.md):
  Add new tree

- [`perturb_remove`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_remove.md):
  Remove tree

- [`perturb_add_with_nurse`](https://bi0m3trics.github.io/EmpericalPatternR/reference/perturb_add_with_nurse.md):
  Add tree with nurse effect

## Optimization Weight Guidelines

All optimization weights range from 0-100:

- 0:

  Ignore this metric completely

- 1-20:

  Low priority - let it emerge from other constraints

- 20-50:

  Moderate priority - balance with other metrics

- 50-80:

  High priority - actively optimize toward target

- 80-100:

  Critical - dominates optimization

## Customization

\*\*Allometric Equations:\*\*

Create custom allometric parameters for your forest type:

    my_params <- list(
      crown_radius = list(SPECIES = list(a = 0.5, b = 0.10)),
      height = list(SPECIES = list(a = 20, b = 0.03)),
      crown_ratio = list(SPECIES = list(a = 0.70, b = 0.10)),
      crown_mass = list(SPECIES = list(a = 0.20, b = 2.1))
    )

\*\*Target Parameters:\*\*

Modify targets to match your field data:

    targets <- list(
      density_ha = YOUR_DENSITY,
      species_props = c(SP1 = 0.6, SP2 = 0.4),
      mean_dbh = YOUR_MEAN,
      canopy_cover = YOUR_COVER,
      cfl = YOUR_CFL
    )

## Examples

Complete working examples in `inst/examples/`:

- `example_01_pinyon_juniper.R` - P-J woodland (Huffman 2009)

- `example_02_ponderosa_pine.R` - Ponderosa pine forest

## References

\*\*Empirical Data:\*\*

Huffman et al. (2009). A comparison of fire hazard mitigation
alternatives in pinyon-juniper woodlands of Arizona. Forest Ecology and
Management 257:628-635.

\*\*Allometric Equations:\*\*

Grier et al. (1992). Biomass distribution and productivity of Pinus
edulis-Juniperus monosperma woodlands. Forest Ecology and Management
50:331-350.

Miller et al. (1981). Biomass of singleleaf pinyon and Utah juniper.
USDA Forest Service Research Paper INT-273.

\*\*Crown Fire Methods:\*\*

Van Wagner (1977). Conditions for the start and spread of crown fire.
Canadian Journal of Forest Research 7:23-34.

Scott & Reinhardt (2001). Assessing crown fire potential by linking
models of surface and crown fire behavior. USDA Forest Service Research
Paper RMRS-RP-29.

## See also

Useful links:

- <https://bi0m3trics.github.io/EmpericalPatternR>

- <https://github.com/bi0m3trics/EmpericalPatternR>

- Report bugs at
  <https://github.com/bi0m3trics/EmpericalPatternR/issues>

## Author

**Maintainer**: Andrew Sánchez Meador <andrew.sanchezmeador@nau.edu>
