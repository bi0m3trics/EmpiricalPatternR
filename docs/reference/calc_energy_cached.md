# Energy Calculation with Caching

Wrapper around calc_energy that caches metric calculations to avoid
redundant computation when only spatial properties change.

## Usage

``` r
calc_energy_cached(
  metrics,
  targets,
  weights,
  trees = NULL,
  nurse_distance = 3,
  use_nurse_effect = FALSE,
  cache = new.env()
)
```

## Arguments

- metrics:

  Current stand metrics

- targets:

  Target stand metrics

- weights:

  Optimization weights

- trees:

  Tree data.table (optional, for nurse effect)

- nurse_distance:

  Target nurse distance (optional)

- use_nurse_effect:

  Include nurse effect (optional)

- cache:

  Environment for caching (auto-managed)

## Value

Numeric energy value
