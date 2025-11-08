# insetplot: Compose ggplot2 maps with insets

insetplot lets you create ggplot2 maps with inset maps easily and
flexibly. It handles spatial configuration, aspect ratios, and plot
composition automatically.

## Core workflow

1.  Build a configuration with
    [`config_insetmap`](https://fncokg.github.io/insetplot/reference/config_insetmap.md)
    and
    [`inset_spec`](https://fncokg.github.io/insetplot/reference/inset_spec.md)
    by specifying necessary parameters (position and size).

2.  Pass your `ggplot` object to
    [`with_inset`](https://fncokg.github.io/insetplot/reference/with_inset.md)
    to generate the composed figure.

3.  Save the final plot with
    [`ggsave_inset`](https://fncokg.github.io/insetplot/reference/ggsave_inset.md)
    to maintain correct aspect ratio.

## Main functions

- [`inset_spec`](https://fncokg.github.io/insetplot/reference/inset_spec.md):
  Define bbox, position (`loc` or `loc_left`/`loc_bottom`), and size
  (prefer `scale_factor`; or provide one of `width`/`height`).

- [`config_insetmap`](https://fncokg.github.io/insetplot/reference/config_insetmap.md):
  Create and store the configuration.

- [`with_inset`](https://fncokg.github.io/insetplot/reference/with_inset.md):
  Crop each subplot, compose subplots and calculate sizes and positions
  automatically.

- [`ggsave_inset`](https://fncokg.github.io/insetplot/reference/ggsave_inset.md):
  Save with the correct aspect ratio derived from
  [`with_inset`](https://fncokg.github.io/insetplot/reference/with_inset.md),
  with optional `ratio_scale` for fine-tuning.

## Example

    library(sf)
    library(ggplot2)
    library(insetplot)

    nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

    # Approach 1: shared base plot for all subplots
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
    base_map <- ggplot(nc, aes(fill = AREA)) +
      geom_sf() +
      scale_fill_viridis_c() +
      guides(fill = "none") +
      theme_void()
    p <- with_inset(base_map)

    # Approach 2: provide custom plots in each spec
    config_insetmap(
      data_list = list(nc),
      specs = list(
        inset_spec(main = TRUE, plot = base_map),
        inset_spec(
          xmin = -84, xmax = -75, ymin = 33, ymax = 37,
          loc = "left bottom", scale_factor = 0.5,
          plot = base_map + ggtitle("Detail")
        )
      )
    )
    p <- with_inset()  # plot argument is optional here

    # Save with the correct aspect ratio
    ggsave_inset("map.png", p, width = 10)

## See also

[`inset_spec`](https://fncokg.github.io/insetplot/reference/inset_spec.md),
[`config_insetmap`](https://fncokg.github.io/insetplot/reference/config_insetmap.md),
[`with_inset`](https://fncokg.github.io/insetplot/reference/with_inset.md),
[`ggsave_inset`](https://fncokg.github.io/insetplot/reference/ggsave_inset.md),
[`map_border`](https://fncokg.github.io/insetplot/reference/map_border.md),
[`last_insetcfg`](https://fncokg.github.io/insetplot/reference/last_insetcfg.md)

## Author

**Maintainer**: Chao Kong <kongchao1998@gmail.com>
([ORCID](https://orcid.org/0000-0002-6404-6142)) \[copyright holder\]
