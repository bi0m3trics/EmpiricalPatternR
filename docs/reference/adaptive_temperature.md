# Adaptive Temperature Schedule

Dynamically adjust cooling rate based on optimization progress. Speeds
up convergence while maintaining solution quality.

## Usage

``` r
adaptive_temperature(iteration, energy, history, base_rate = 0.9999)
```

## Arguments

- iteration:

  Current iteration

- energy:

  Current energy

- history:

  Energy history data.table

- base_rate:

  Base cooling rate

## Value

Adjusted temperature
