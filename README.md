# insetplot

<!-- badges: start -->
<!-- badges: end -->

Compose ggplot2 maps with insets using simple spatial configuration. **Get correct aspect ratios automatically** — no more guessing width/height ratios. Define insets with bounding boxes, positions, and sizes, then reuse the same plotting code for all subplots or customize each one.

## ⚡ Quick Start

### Two Approaches to Get Started

#### Approach 1: Reuse Plot Code (Simplest)

Use the same plot for main and all insets — let `insetplot` handle sizing and positioning:

```r
library(insetplot)
library(sf)
library(ggplot2)

# Load data
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# Configure insets: define main + one inset
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

# Compose: pass your plot to with_inset()
with_inset({
  ggplot(nc, aes(fill = AREA)) +
    geom_sf() +
    scale_fill_viridis_c() +
    theme_void()
})
```

#### Approach 2: Custom Plots for Each Subplot

Define unique plots for main and insets — useful for highlighting different features:

```r
# Create different plot versions
main_plot <- ggplot(nc, aes(fill = AREA)) +
  geom_sf() + scale_fill_viridis_c() + 
  ggtitle("Full North Carolina") + theme_void()

inset_plot <- ggplot(nc, aes(fill = AREA)) +
  geom_sf() + scale_fill_viridis_c() +
  ggtitle("Detail Region") + theme_void()

# Configure with custom plots in each spec
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE, plot = main_plot),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", width = 0.3,
      plot = inset_plot
    )
  ),
  full_ratio = 16 / 9
)

# Call with_inset() without arguments
with_inset()
```

## Installation

Install from GitHub:

```r
# install.packages("devtools")
devtools::install_github("fncokg/insetplot")
```

## Why insetplot?

### 🎯 Automatic Aspect Ratio Handling

`insetplot` **computes aspect ratios from your spatial data**, not from guesses:

```r
# ❌ Manual approach (guessing is error-prone):
# You have to calculate: width/height should match data ratio
# Easy to get wrong!

# ✅ insetplot (automatic and correct):
# Extracts extent from bounding boxes
# Multiplies by main plot ratio and canvas ratio
# Always mathematically consistent
```

### 📊 How It Works

1. **Data-driven**: Crops data to specified bounding boxes
2. **Automatic sizing**: Uses spatial extent and canvas aspect ratio to compute dimensions
3. **Flexible**: Scale factor (relative sizing) or explicit dimensions
4. **Flexible positioning**: Corners (`"left bottom"`, `"right top"`) or custom coordinates
5. **Reusable configuration**: Define once, apply to multiple plots

## Key Features

| Feature                       | Description                                            |
| ----------------------------- | ------------------------------------------------------ |
| **🎯 Automatic aspect ratios** | Based on spatial data extents and canvas ratio         |
| **📍 Flexible positioning**    | Preset corners or custom (x, y) coordinates            |
| **🎨 Flexible plotting**       | Same plot for all subplots OR unique per subplot       |
| **🔧 Multiple sizing options** | Scale factor, explicit dimensions, or auto-computed    |
| **🌍 CRS support**             | Transform to different coordinate reference systems    |
| **🎁 Borders & styling**       | Optional borders around insets for visual separation   |
| **💾 Save correctly**          | `ggsave_inset()` maintains aspect ratios automatically |

## Core Functions

### Configuration

- **`inset_spec()`** — Define spatial extent (bbox), position, and size for each subplot
  - `xmin, xmax, ymin, ymax`: Bounding box coordinates
  - `loc`: Position string like `"left bottom"`, `"center top"`, etc.
  - `scale_factor`: Size relative to main plot extent (optional)
  - `width, height`: Explicit dimensions (alternative to scale_factor)
  - `plot`: Custom ggplot object for this subplot (optional)
  - `main`: Set to `TRUE` for exactly one main plot

- **`config_insetmap()`** — Create and store configuration
  - `data_list`: List of sf objects (spatial data)
  - `specs`: List of `inset_spec()` objects
  - `full_ratio`: Canvas width-to-height ratio (for saving)
  - `crs`: Target CRS for transformations
  - `border_args`: Styling for inset borders

- **`last_insetcfg()`** — Retrieve the most recent configuration (automatic)

### Composition & Output

- **`with_inset()`** — Compose main and insets
  - `plot`: Optional base ggplot (used if specs don't have custom plots)
  - `.cfg`: Configuration object (auto-retrieves last one)
  - `.as_is`: Return plot unchanged (for code reuse)
  - `.return_details`: Get detailed output with subplots and layouts

- **`ggsave_inset()`** — Save with correct dimensions
  - Automatically calculates width/height from aspect ratio
  - Just provide one dimension (`width` or `height`)

### Styling

- **`map_border()`** — Add border around plots
  - Parameters: `color`, `linewidth`, `fill`

## Examples

### Example 1: Multiple Insets with Scale Factors

Size insets relative to their data extent:

```r
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "left bottom", scale_factor = 0.5
    ),
    inset_spec(
      xmin = -81, xmax = -72, ymin = 34, ymax = 36,
      loc = "right top", scale_factor = 0.4
    )
  ),
  full_ratio = 16 / 9,
  border_args = list(color = "red", linewidth = 1.5)
)

with_inset(
  ggplot(nc, aes(fill = AREA)) +
    geom_sf() +
    theme_void()
)
```

### Example 2: Custom Positioning

Use explicit coordinates instead of corner names:

```r
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -84, xmax = -75, ymin = 33, ymax = 37,
      loc = "",  # Empty string for custom positioning
      loc_left = 0.05, loc_bottom = 0.05,  # Custom x, y
      width = 0.25, height = 0.25
    )
  ),
  full_ratio = 16 / 9
)

with_inset(base_plot)
```

### Example 3: Save with Correct Aspect Ratio

Let `ggsave_inset()` handle dimensions:

```r
# Just specify width OR height, the other is computed automatically
ggsave_inset(
  "map_with_insets.png",
  plot = composed_plot,
  width = 12,  # inches
  dpi = 300
)
```

### Example 4: Debugging with Detailed Output

Get individual subplots and layout information:

```r
result <- with_inset(
  plot = my_plot,
  .return_details = TRUE
)

# result$full — the complete composed plot
# result$subplots — individual ggplot objects for each subplot
# result$subplot_layouts — position and size info
# result$main_ratio — aspect ratio of main plot data
```

## Workflow: From Data to Final Plot

```
Your Data (sf object)
    ↓
1. inset_spec() — define spatial extents and positions
    ↓
2. config_insetmap() — prepare data, store configuration
    ↓
3. with_inset() — compose with your ggplot code
    ↓
4. ggsave_inset() — save with correct aspect ratio
    ↓
Final Map with Insets
```

## Best Practices

### ✅ Do:

- Keep your ggplot code **outside** `config_insetmap()` call
- Use `scale_factor` for proportional sizing
- Let `with_inset()` handle coordinate systems (don't add `coord_sf()` manually)
- Use `ggsave_inset()` to maintain aspect ratios
- Set `full_ratio` to match your target save dimensions

### ❌ Don't:

- Add `coord_sf()` to your plot manually (insetplot does this)
- Guess width/height ratios (use scale_factor instead)
- Forget to define exactly one main plot (`main = TRUE`)
- Mix spec definitions — keep them consistent

## Common Patterns

### Pattern: Zoom Inset

Highlight a zoomed region:

```r
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),
    inset_spec(
      xmin = -80.5, xmax = -78.5, ymin = 35, ymax = 36.5,
      loc = "right bottom",
      scale_factor = 0.6  # Zoomed region is 60% of main
    )
  ),
  full_ratio = 16 / 9
)
```

### Pattern: Contextual Inset

Show full extent + detail region:

```r
config_insetmap(
  data_list = list(nc),
  specs = list(
    inset_spec(main = TRUE),  # Full map
    inset_spec(
      xmin = -82, xmax = -76, ymin = 33, ymax = 37,  # Subset
      loc = "left bottom",
      width = 0.35
    )
  ),
  full_ratio = 16 / 9
)
```

## Learn More

See the package documentation:

```r
# Overview of main functions
?insetplot

# Detailed function help
?inset_spec
?config_insetmap
?with_inset
?ggsave_inset

# Read the package vignette
# vignette("insetplot-intro", package = "insetplot")
```

## Troubleshooting

| Problem                                     | Solution                                                                 |
| ------------------------------------------- | ------------------------------------------------------------------------ |
| **Inset dimensions don't match data ratio** | Use `scale_factor` instead of manual width/height                        |
| **Plot looks distorted when saved**         | Use `ggsave_inset()` instead of `ggsave()`                               |
| **Coordinates are wrong**                   | Make sure bounding boxes are in correct order (xmin < xmax, ymin < ymax) |
| **No inset appears**                        | Check that you have exactly one `main = TRUE` in specs                   |
| **CRS issues**                              | Verify data and target CRS match in `config_insetmap()`                  |

## Related Packages

- **patchwork** — Used for flexible plot composition via `inset_element()`
- **ggplot2** — Foundation for all plotting
- **sf** — Spatial data handling and CRS transformations

---

**Made with ❤️ for cleaner, more correct inset maps**
