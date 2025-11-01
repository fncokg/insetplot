# insetplot

<!-- badges: start -->
<!-- badges: end -->

`insetplot` provides tools for creating inset plots and maps with spatial data. **Migrate from normal ggplot2 mapping to inset plots with minimal code changes** - just wrap your existing plotting code!

## ⚡ Quick Migration Example

**Before (normal ggplot):**
```r
ggplot(spatial_data) +
  geom_sf(aes(fill = population)) +
  theme_void()
```

**After (with insets):**
```r
# 1. Configure insets once
config_insetmap(
  plot_data = spatial_data,
  specs = list(
    plot_spec(main = TRUE),
    plot_spec(xmin = -10, xmax = 30, ymin = 35, ymax = 70,
              loc_left = 0.7, loc_bottom = 0.7, width = 0.3)
  )
)

# 2. Wrap your SAME plotting code
with_inset({
  ggplot(spatial_data) +
    geom_sf(aes(fill = population)) +
    theme_void()
})
```

**That's it!** Your plotting code remains unchanged - just configuration and wrapping.

## Installation

You can install the development version of insetplot from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("fncokg/insetplot")
```

## Features

- **🚀 Minimal Migration**: Wrap existing ggplot2 code - no need to rewrite plotting logic
- **📍 Flexible positioning**: Define multiple plot areas with custom bounding boxes and positioning
- **🎯 Automatic aspect ratio handling**: Maintains proper proportions for geographic data

## Basic Usage

Here's a simple example of how to create an inset map:

```r
library(insetplot)
library(sf)
library(ggplot2)

# Load spatial data
nc <- sf::st_read(system.file("shape/nc.shp", package="sf"))

# Configure the inset map
config_insetmap(
  plot_data = nc,
  specs = list(
    # Main plot (full extent)
    plot_spec(main = TRUE),
    
    # Inset plot (zoomed region)
    plot_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,  # Bounding box
      loc_left = 0.7, loc_bottom = 0.7,              # Position in main plot
      width = 0.3                                    # Size of inset
    )
  )
)

# Create the combined plot
with_inset({
  ggplot(nc) +
    geom_sf(aes(fill = AREA)) +
    scale_fill_viridis_c() +
    theme_void()
})
```

## Advanced Usage

### Multiple Insets

You can create multiple insets in a single plot:

```r
config_insetmap(
  plot_data = world_data,
  specs = list(
    plot_spec(main = TRUE),
    plot_spec(xmin = -10, xmax = 30, ymin = 35, ymax = 70, 
              loc_left = 0.02, loc_bottom = 0.7, width = 0.3),
    plot_spec(xmin = -180, xmax = -120, ymin = 55, ymax = 75,
              loc_left = 0.02, loc_bottom = 0.02, width = 0.25)
  )
)
```

### Automatic Sizing

Use `no_scale = TRUE` to automatically determine inset size to keep the aspect ratio consistent with the main plot:

```r
plot_spec(
  xmin = -84, xmax = -75, ymin = 33, ymax = 37,
  loc_left = 0.7, loc_bottom = 0.7,
  no_scale = TRUE
)
```
