# Add a border around a map plot

Returns a small theme that draws a rectangular border around the plot
area. Handy for visually separating inset plots from the main plot.

## Usage

``` r
map_border(color = "black", linewidth = 1, fill = "white", ...)
```

## Arguments

- color:

  Border color. Default "black".

- linewidth:

  Border line width. Default 1.

- fill:

  Background fill color. Default "white".

- ...:

  Passed to
  [`ggplot2::element_rect()`](https://ggplot2.tidyverse.org/reference/element.html).

## Value

A ggplot2 theme object to add to a ggplot with `+`.

## Examples

``` r
library(ggplot2)

ggplot(mtcars, aes(mpg, wt)) +
    geom_point() +
    map_border(color = "red", linewidth = 2)

```
