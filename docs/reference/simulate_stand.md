# Simulate Forest Stand with Simulated Annealing

Run complete stand simulation to match empirical targets using simulated
annealing optimization. Optimizes spatial pattern, species composition,
size structure, and fire behavior metrics.

## Usage

``` r
simulate_stand(
  targets,
  weights = NULL,
  plot_size = 100,
  max_iterations = 1e+05,
  initial_temp = 0.01,
  cooling_rate = 0.9999,
  energy_threshold = 1e-06,
  verbose = TRUE,
  print_every = 1000,
  plot_interval = 1000,
  save_plots = FALSE,
  nurse_distance = 3,
  use_nurse_effect = TRUE,
  mortality_prop = 0
)
```

## Arguments

- targets:

  List of target values (density_ha, species_props, mean_dbh, etc.)

- weights:

  List of optimization weights (0-100 scale)

- plot_size:

  Plot dimension (m), creates plot_size x plot_size area

- max_iterations:

  Maximum annealing iterations

- initial_temp:

  Initial temperature for annealing

- cooling_rate:

  Temperature cooling rate per iteration

- energy_threshold:

  Stop if energy below this threshold

- verbose:

  Print progress messages

- print_every:

  Print status every N iterations

- plot_interval:

  Update plots every N iterations (NULL = no plotting)

- save_plots:

  Save intermediate plot images to files

- nurse_distance:

  Target distance for PIED trees to nearest juniper (m)

- use_nurse_effect:

  Include nurse tree effect in optimization

- mortality_prop:

  Simulate this proportion of dead trees after optimization (0-1)

## Value

List containing trees, metrics, history, and final energy

## Examples

``` r
if (FALSE) { # \dontrun{
targets <- list(density_ha = 960, species_props = c(0.55, 0.45),
                mean_dbh = 18, sd_dbh = 8, canopy_cover = 0.40, cfl = 1.16)
result <- simulate_stand(targets, max_iterations = 50000)
} # }
```
