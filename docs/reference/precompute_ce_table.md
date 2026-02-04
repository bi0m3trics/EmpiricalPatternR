# Pre-compute Clark-Evans Lookup Table

For common densities, pre-compute expected R values to avoid repeated
calculations during optimization.

## Usage

``` r
precompute_ce_table(plot_size = 20, density_range = seq(100, 2000, by = 50))
```

## Arguments

- plot_size:

  Plot size (m)

- density_range:

  Range of densities to pre-compute

## Value

List with density and expected_r vectors
