# Get Last Inset Configuration

Retrieves the most recently created inset configuration object. This is
used internally by
[`with_inset()`](https://fncokg.github.io/insetplot/reference/with_inset.md)
when no configuration is explicitly provided.

## Usage

``` r
last_insetcfg()
```

## Value

An inset configuration object of class `insetcfg`, or NULL if no
configuration has been set.

## Examples

``` r
library(sf)

# Load some spatial data
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# Configure inset map
config_insetmap(
    bbox = sf::st_bbox(nc),
    specs = list(
        inset_spec(main = TRUE),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom",
            width = 0.3
        )
    )
)

# Retrieve the configuration
cfg <- last_insetcfg()
```
