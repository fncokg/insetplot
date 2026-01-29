# insetplot

<!-- badges: start -->
<!-- badges: end -->

insetplot is an R package to create ggplot2 maps with inset maps easily and flexibly. It handles spatial configuration, aspect ratios, and plot composition automatically.

## Quick start

### Approach 1: Reuse one plot (simplest)

Use the same plot for the main map and all insets — let insetplot handle sizing and positioning.

```r
library(insetplot)
library(sf)
library(ggplot2)

# Load data
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# Configure insets: one main + one inset
config_insetmap(
  bbox = st_bbox(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", scale_factor = 0.5
    )
  )
)

# Compose
with_inset(
  ggplot(nc, aes(fill = AREA)) +
    geom_sf() +
    scale_fill_viridis_c() +
    theme_void()
)
```

### Approach 2: Custom plot per subplot

Provide specific plots for the main and inset maps.

```r
base_plot <- ggplot(nc, aes(fill = AREA)) +
  geom_sf() + scale_fill_viridis_c() + theme_void()

main_plot <- base_plot +
  ggtitle("Full North Carolina") 

inset_plot <- base_plot +
  ggtitle("Detail Region") 

config_insetmap(
  bbox = st_bbox(nc),
  specs = list(
    inset_spec(main = TRUE, plot = main_plot),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", scale_factor = 0.5,
      plot = inset_plot
    )
  )
)

with_inset()  # plot argument optional when each spec has its own plot
```

## Installation

To install the released version from CRAN:

```r
install.packages("insetplot")
```

To install the development version from GitHub:

```r
devtools::install_github("fncokg/insetplot")
```

## Documentation

Full documentation and more examples are available at [insetplot package site](https://fncokg.github.io/insetplot/).

## Core functions

- `inset_spec()` — Define bbox, position, and size for each subplot
  - bbox: `xmin, xmax, ymin, ymax`
  - position: `loc` (e.g., "left bottom") or `loc_left`/`loc_bottom` in [0, 1]
  - size: prefer `scale_factor`; or provide one of `width`/`height`
  - `plot`: optional custom ggplot object
  - `main`: exactly one spec must set `main = TRUE`

- `config_insetmap()` — Build and store configuration
  - `bbox`: overall bounding box (sf bbox or similar)
  - `to_crs`: target Coordinate Reference System
  - `from_crs`: source CRS for non-sf inputs
  - `specs`: list of `inset_spec()`
  - `crs`: target CRS (passed to coord_sf as `crs`)
  - `border_args`: forwarded to `map_border()` for inset borders

- `with_inset()` — Compose main plot with insets
  - `plot`: single ggplot or list per spec (optional)
  - `.as_is`: return the input plot as-is (skip inset composition)
  - `.return_details`: return `list(full, subplots, subplot_layouts, main_ratio)`

- `ggsave_inset()` — Save with the correct aspect ratio
  - Provide one of `width` or `height`; the other is computed from `main_ratio`
  - Optional `ratio_scale` for small adjustments (e.g., legends)

- `map_border()` — Small theme to draw a rectangular border around plots

## Further examples

### Custom positioning and sizing

```r
config_insetmap(
  bbox = st_bbox(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc_left = 0.05, loc_bottom = 0.05,
      # Use width only; height auto-calculated to preserve aspect ratio
      width = 0.25
    )
  )
)

with_inset(base_plot)
```

### Pass custom plots after configuration
```r
config_insetmap(
  bbox = st_bbox(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", scale_factor = 0.5,
    )
  )
)

with_inset(list(main_plot, inset_plot))
```

### Save with correct aspect ratio

```r
ggsave_inset(
  "map_with_insets.png",
  # `height` auto-calculated from `main_ratio`
  width = 12,
  dpi = 300
)
```

### Debugging with detailed output

```r
result <- with_inset(plot = my_plot, .return_details = TRUE)
# result$full, result$subplots, result$subplot_layouts, result$main_ratio
```
