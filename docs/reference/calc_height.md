# Calculate tree height from DBH using allometric equations

Calculates tree height using asymptotic exponential growth curves:
height (m) = 1.3 + a \* (1 - exp(-b \*
DBH))

## Usage

``` r
calc_height(dbh, species, allometric_params = get_default_allometric_params())
```

## Arguments

  - dbh:
    
    Numeric vector. Tree diameter at breast height (cm)

  - species:
    
    Character vector. Species codes

  - allometric\_params:
    
    List. Allometric parameters

## Value

Numeric vector. Tree height (m)

## Examples

``` r
# Single tree
calc_height(20, "PIED")
#> [1] 8.421164

# Multiple trees with different species
calc_height(c(10, 20, 30), c("PIED", "JUSO", "JUMO"))
#> [1]  5.648462  7.621206 11.083281

# Ponderosa pine
params <- get_ponderosa_allometric_params()
calc_height(40, "PIPO", params)
#> [1] 23.42422
```
