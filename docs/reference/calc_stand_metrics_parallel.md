# Parallel Metric Calculation

Calculate stand metrics using parallel processing for large stands.
Useful for stands with \>500 trees.

## Usage

``` r
calc_stand_metrics_parallel(trees, plot_size = 100, n_cores = NULL)
```

## Arguments

- trees:

  Tree data.table

- plot_size:

  Plot size (m)

- n_cores:

  Number of cores to use (NULL = auto-detect)

## Value

Stand metrics list
