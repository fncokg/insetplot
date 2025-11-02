# insetplot

<!-- badges: start -->
<!-- badges: end -->

`insetplot` provides tools for creating inset plots and maps with spatial data. **Compose maps with proper aspect ratios** - the automatic kind, not the guessed kind!

## ⚡ Quick Start: Two Approaches

### Approach 1: Reuse Plot Code (Minimal Setup)

Same plot for main and all insets - let `insetplot` handle sizing:

```r
library(insetplot)
library(sf)
library(ggplot2)

nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Configure insets
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", width = 0.3
    )
  ),
  full_ratio = 16 / 9
)

# Reuse the same plot code
with_inset({
  ggplot(nc, aes(fill = AREA)) +
    geom_sf() +
    scale_fill_viridis_c() +
    theme_void()
})
```

### Approach 2: Customize Each Subplot

Define unique plots for main and insets:

```r
base_map <- ggplot(nc, aes(fill = AREA)) +
  geom_sf() + scale_fill_viridis_c() + theme_void()

inset_map <- ggplot(nc, aes(fill = AREA)) +
  geom_sf() + scale_fill_viridis_c() +
  theme_void() + theme(legend.position = "none")

# Configure with custom plots
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE, plot = base_map),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", width = 0.3,
      plot = inset_map
    )
  ),
  full_ratio = 16 / 9
)

# Call with_inset() without plot parameter
with_inset()
```

## Installation

You can install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("fncokg/insetplot")
```

## Why insetplot?

### ✅ Correct Aspect Ratios

`insetplot` **computes aspect ratios from your data**, not guesses. Compare:

```r
# ❌ Direct cowplot (manual, often wrong):
ggdraw(main) + draw_plot(inset, x = 0.1, y = 0.1, width = 0.3, height = 0.25)
# You guessed width/height ratio matches the data? Probably not.

# ✅ insetplot (automatic, always right):
config_insetmap(data_list = list(nc), specs = list(...), full_ratio = 16/9)
with_inset(plot)
# Aspect ratio = data extent / canvas ratio. Math works.
```

See the vignette for a detailed comparison with examples.

## Key Features

- **🎯 Automatic aspect ratio handling**: Based on data bounding boxes and canvas ratio
- **📍 Flexible positioning**: Corners (e.g., `"left bottom"`) or custom coordinates
- **🎨 Customizable**: Same plot for all subplots OR unique plots per subplot
- **🔧 Scale factor support**: Size insets relative to data extent with `scale_factor`
- **🎁 Convenience features**: Border styling, CRS transformations, subtitle support

## Main Functions

- `inset_spec()`: Define spatial extent and positioning for each subplot
- `config_insetmap()`: Create an inset configuration from your data
- `with_inset()`: Compose the final plot
- `last_insetcfg()`: Retrieve the most recent configuration
- `map_border()`: Add subtle borders around insets

## Examples

### Multiple Insets with Scale Factors

```r
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(xmin = -84, xmax = -75, ymin = 33, ymax = 37,
               loc = "left bottom", scale_factor = 0.5),
    inset_spec(xmin = -81, xmax = -72, ymin = 34, ymax = 36,
               loc = "right top", scale_factor = 0.4)
  ),
  full_ratio = 16 / 9,
  border_args = list(color = "red", linewidth = 1.5)
)

with_inset(ggplot(nc, aes(fill = AREA)) + geom_sf() + theme_void())
```

## Learn More

Read the vignette for a detailed comparison with `cowplot` and examples:

```r
vignette("insetplot-intro", package = "insetplot")
```

