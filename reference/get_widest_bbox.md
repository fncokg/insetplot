# Compute the union bounding box from multiple shapes

Calculates the overall bounding box that encompasses all provided
spatial shapes.

## Usage

``` r
get_widest_bbox(shapes)
```

## Arguments

- shapes:

  A list of sf objects.

## Value

A named numeric vector with elements: `ymin`, `xmin`, `xmax`, `ymax`
representing the union of all input bounding boxes.

## Examples

``` r
library(sf)

# Load sample data
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# Get the bounding box of the entire dataset
bbox <- get_widest_bbox(list(nc))
bbox
#>      ymin      xmin      xmax      ymax 
#>  33.88199 -84.32385 -75.45698  36.58965 
```
