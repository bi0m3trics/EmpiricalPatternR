# Memory-Efficient History Storage

Store optimization history with periodic thinning to avoid memory issues
in very long runs.

## Usage

``` r
update_history_efficient(
  history,
  new_row,
  max_rows = 10000,
  thin_interval = 10
)
```

## Arguments

  - history:
    
    Current history data.table

  - new\_row:
    
    New row to add

  - max\_rows:
    
    Maximum rows to keep

  - thin\_interval:
    
    Keep every Nth row when thinning

## Value

Updated history
