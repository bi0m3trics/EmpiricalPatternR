# Calculate energy (deviation from targets)

Calculate energy (deviation from targets)

## Usage

``` r
calc_energy(
  metrics,
  targets,
  weights,
  trees = NULL,
  nurse_distance = 3,
  use_nurse_effect = TRUE
)
```

## Arguments

  - metrics:
    
    Current stand metrics

  - targets:
    
    Target parameters

  - weights:
    
    Weights for each component

  - trees:
    
    Current trees (for nurse tree calc)

  - nurse\_distance:
    
    Target nurse tree distance

  - use\_nurse\_effect:
    
    Whether to include nurse tree energy

## Value

Total energy (lower is better)

All metrics are normalized to relative errors so weights range 0-100: 0
= ignore this metric 1-20 = low priority 20-50 = moderate priority 50-80
= high priority 80-100 = critical (will dominate optimization)
