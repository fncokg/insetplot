# Extract width, height, and aspect ratio from a bounding box

Computes spatial range and aspect ratio metrics from a bounding box.

## Usage

``` r
get_bbox_features(bbox)
```

## Arguments

- bbox:

  A named numeric vector with elements `xmin`, `xmax`, `ymin`, `ymax`.

## Value

A list with elements:

- x_range:

  Width (xmax - xmin) of the bounding box

- y_range:

  Height (ymax - ymin) of the bounding box

- xy_ratio:

  Aspect ratio (x_range / y_range)

## Examples

``` r
# Create a sample bounding box
bbox <- c(xmin = -84, xmax = -75, ymin = 33, ymax = 37)

# Extract width, height, and aspect ratio
features <- get_bbox_features(bbox)
features
#> $x_range
#> [1] 9
#> 
#> $y_range
#> [1] 4
#> 
#> $xy_ratio
#> [1] 2.25
#> 

# Access individual components
features$x_range
#> [1] 9
features$y_range
#> [1] 4
features$xy_ratio
#> [1] 2.25
```
