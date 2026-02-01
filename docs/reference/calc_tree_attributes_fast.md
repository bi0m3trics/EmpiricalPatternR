# Batch Tree Attribute Calculation

Calculate tree attributes for multiple trees efficiently using
vectorization. Significantly faster than row-by-row calculations for
large stands.

## Usage

``` r
calc_tree_attributes_fast(trees, allometric_params = NULL)
```

## Arguments

  - trees:
    
    Data.table with DBH and Species columns

  - allometric\_params:
    
    Allometric parameters (optional)

## Value

Data.table with added Height, CrownRadius, CrownBaseHeight, etc.
