# Configure inset map settings

Create and store an inset configuration used by
[`with_inset()`](https://fncokg.github.io/insetplot/reference/with_inset.md).
The configuration contains subplot specifications, aspect ratio of the
main plot, CRS settings, and border appearance for insets.

## Usage

``` r
config_insetmap(
  data_list,
  specs,
  crs = sf::st_crs("EPSG:4326"),
  border_args = list()
)
```

## Arguments

- data_list:

  A list of spatial data objects (sf class). These data are used to
  compute the overall bounding box and coordinate systems for the
  insets.

- specs:

  A non-empty list of
  [`inset_spec()`](https://fncokg.github.io/insetplot/reference/inset_spec.md)
  objects.

- crs:

  Coordinate reference system to transform to, passed to
  [`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
  as `crs`. Default `"EPSG:4326"`.

- border_args:

  A list of named arguments passed to
  [`map_border()`](https://fncokg.github.io/insetplot/reference/map_border.md)
  to style the borders around inset plots. See
  [`map_border()`](https://fncokg.github.io/insetplot/reference/map_border.md)
  for details (defaults: `color = "black"`, `linewidth = 1`).

## Value

An object of class `insetcfg`. Also stored as the last configuration,
retrievable via
[`last_insetcfg()`](https://fncokg.github.io/insetplot/reference/last_insetcfg.md).

## See also

[`inset_spec()`](https://fncokg.github.io/insetplot/reference/inset_spec.md),
[`with_inset()`](https://fncokg.github.io/insetplot/reference/with_inset.md),
[`last_insetcfg()`](https://fncokg.github.io/insetplot/reference/last_insetcfg.md)

## Examples

``` r
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

config_insetmap(
    data_list = list(nc),
    specs = list(
        inset_spec(main = TRUE),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", scale_factor = 0.5
        )
    )
)
#> Error in config_insetmap(data_list = list(nc), specs = list(inset_spec(main = TRUE),     inset_spec(xmin = -84, xmax = -75, ymin = 33, ymax = 37,         loc = "left bottom", scale_factor = 0.5))): unused argument (data_list = list(nc))
```
