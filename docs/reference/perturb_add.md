# Add a new tree

Add a new tree

## Usage

``` r
perturb_add(trees, plot_size, species_names, species_probs, dbh_mean, dbh_sd)
```

## Arguments

- trees:

  data.table. Tree data

- plot_size:

  Numeric. Plot dimension (m)

- species_names:

  Character vector. Available species

- species_probs:

  Numeric vector. Species proportions

- dbh_mean:

  Numeric. Mean DBH (cm)

- dbh_sd:

  Numeric. SD of DBH (cm)

## Value

data.table. Modified tree data
