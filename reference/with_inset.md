# Compose a main plot with inset(s)

Build a combined plot using an inset configuration created by
[`config_insetmap()`](https://fncokg.github.io/insetplot/reference/config_insetmap.md).
For each plot specification in the configuration, the function either
uses the provided `spec$plot` or the supplied `plot` parameter and adds
spatial coordinates via
[`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
with the given bounding box. Non-main subplots receive a border from
[`map_border()`](https://fncokg.github.io/insetplot/reference/map_border.md).
Insets are composed using
[`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html).

## Usage

``` r
with_inset(
  plot = NULL,
  .cfg = last_insetcfg(),
  .as_is = FALSE,
  .return_details = FALSE
)
```

## Arguments

- plot:

  Optional. Either:

  - A single ggplot object to use as the base plot for all subplots
    (unless a spec has its own plot)

  - A list of ggplot objects matching the length of `.cfg$specs`, where
    each element corresponds to a subplot in the configuration.

  - NULL if all specs have their own plot defined (plot is fully
    optional in this case)

  NOTE: you SHOULD NOT pass
  [`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html)
  into this plot manually. The coordinate system is handled internally.
  Default NULL.

- .cfg:

  An inset configuration (class "insetcfg") created by
  [`config_insetmap()`](https://fncokg.github.io/insetplot/reference/config_insetmap.md).
  Defaults to
  [`last_insetcfg()`](https://fncokg.github.io/insetplot/reference/last_insetcfg.md).

- .as_is:

  Logical. If TRUE, return `plot` as-is without creating insets. Useful
  when debugging or code reuse outside the inset workflow. Default
  FALSE.

- .return_details:

  Logical. If FALSE (default), returns a combined plot with the main
  plot and inset layers. If TRUE, returns a list. See 'Value' section
  for details.

## Value

If `.return_details = FALSE`, a ggplot object containing the main plot
plus inset layers. If TRUE, a list with elements:

- full:

  The combined plot

- subplots:

  Individual ggplot objects for each subplot

- subplot_layouts:

  A `list` of layout information (`x`, `y`, `width`, `height`) for each
  inset

- main_ratio:

  Width-to-height ratio of the main plot's data extent

## See also

[`config_insetmap()`](https://fncokg.github.io/insetplot/reference/config_insetmap.md)

## Examples

``` r
library(sf)
library(ggplot2)

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

config_insetmap(
    data_list = list(nc),
    specs = list(
        inset_spec(main = TRUE),
        inset_spec(
            xmin = -82, xmax = -80.5, ymin = 35.5, ymax = 36,
            loc = "left bottom", scale_factor = 2
        )
    )
)
#> Error in config_insetmap(data_list = list(nc), specs = list(inset_spec(main = TRUE),     inset_spec(xmin = -82, xmax = -80.5, ymin = 35.5, ymax = 36,         loc = "left bottom", scale_factor = 2))): unused argument (data_list = list(nc))

# Supply base plot for all subplots
base <- ggplot(nc, aes(fill = AREA)) +
    geom_sf() +
    scale_fill_viridis_c() +
    guides(fill = "none") +
    theme_void()
with_inset(base)
#> Error: No inset configuration found. Please run config_insetmap() first.

# Or supply custom plots in each inset_spec, then call with_inset() without plot
config_insetmap(
    data_list = list(nc),
    specs = list(
        inset_spec(main = TRUE, plot = base),
        inset_spec(
            xmin = -82, xmax = -80.5, ymin = 35.5, ymax = 36,
            loc = "left bottom", scale_factor = 2,
            plot = base # Each spec has its own plot
        )
    )
)
#> Error in config_insetmap(data_list = list(nc), specs = list(inset_spec(main = TRUE,     plot = base), inset_spec(xmin = -82, xmax = -80.5, ymin = 35.5,     ymax = 36, loc = "left bottom", scale_factor = 2, plot = base))): unused argument (data_list = list(nc))
with_inset() # plot parameter is optional now
#> Error: No inset configuration found. Please run config_insetmap() first.
```
