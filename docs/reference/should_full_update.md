# Batch Update Check

For large stands, only recalculate full metrics every N iterations and
use incremental updates in between. Major speed improvement for large
simulations.

## Usage

``` r
should_full_update(iteration, batch_size = 10)
```

## Arguments

- iteration:

  Current iteration

- batch_size:

  Update full metrics every N iterations

## Value

Logical - should do full update?
