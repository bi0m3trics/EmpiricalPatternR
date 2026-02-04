# Fast Canopy Cover Calculation (Vectorized)

Optimized canopy cover calculation using matrix operations instead of
loops. Approximately 2-3x faster than original implementation.

## Usage

``` r
calc_canopy_cover_fast(x, y, crown_radius, plot_size = 100, grid_res = 0.5)
```

## Arguments

- x:

  Vector of x coordinates (m)

- y:

  Vector of y coordinates (m)

- crown_radius:

  Vector of crown radii (m)

- plot_size:

  Size of plot (m)

- grid_res:

  Grid resolution (m). Default 0.5m.

## Value

Proportion of plot covered by canopy (0-1)
