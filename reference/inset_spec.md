# Create a plot specification for insets

Define the spatial extent and positioning for each subplot (main or
inset).

## Usage

``` r
inset_spec(
  xmin = NA,
  xmax = NA,
  ymin = NA,
  ymax = NA,
  loc = "right bottom",
  loc_left = NA,
  loc_bottom = NA,
  width = NA,
  height = NA,
  scale_factor = NA,
  main = FALSE,
  plot = NULL
)
```

## Arguments

- xmin, xmax, ymin, ymax:

  Numeric bbox coordinates for the subplot in the coordinate system of
  the data, normally longitude/latitude. Any may be NA and will be
  inferred from the overall extent if possible.

- loc:

  A convenience string like "left bottom", "center top", etc. to specify
  the position of the inset on the full canvas. Horizontal position must
  be one of "left", "center", or "right"; vertical position must be one
  of "bottom", "center", or "top". Ignored when `loc_left` and
  `loc_bottom` are provided.

- loc_left, loc_bottom:

  Numbers in \[0, 1\] for the bottom-left position of the inset on the
  full canvas.

- width, height:

  Numeric values in (0, 1\] for the size of the inset. It is recommended
  to provide only one of these; the other dimension will be inferred to
  maintain the aspect ratio of the spatial extent. It is also
  recommended to use `scale_factor` to automatically size the inset
  relative to the main plot instead of specifying width/height directly.

- scale_factor:

  Numeric value in (0, Inf) indicating the scale of the inset relative
  to the main plot. If not NA, the inset's width/height are
  automatically derived from the spatial ranges relative to the main
  plot multiplied by this factor. For example, the scale of the main
  plot is 1:10,000, the inset's dimensions will be 1:20,000 if
  `scale_factor` is 0.5.

- main:

  Logical. TRUE marks this spec as the main plot (exactly one). Default
  FALSE.

- plot:

  Optional ggplot object to use for this spec instead of the base plot
  passed to
  [`with_inset()`](https://fncokg.github.io/insetplot/reference/with_inset.md).

## Value

A list with elements `bbox`, `loc_left`, `loc_bottom`, `width`,
`height`, `scale_factor`, `main`, `plot`, `hpos`, and `vpos`. You do not
normally need to interact with this object directly; it is used
internally.

## Examples

``` r
specs <- list(
    # Create a main plot specification
    inset_spec(main = TRUE),
    # Create an inset plot specification with explicit dimensions
    inset_spec(
        xmin = -120, xmax = -100, ymin = 30, ymax = 50,
        loc = "right bottom",
        width = 0.3
    ),
    # Create an inset with scale factor
    inset_spec(
        xmin = -120, xmax = -100, ymin = 30, ymax = 50,
        loc = "left bottom",
        scale_factor = 0.5
    )
)
```
