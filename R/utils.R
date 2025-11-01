#' Get map ranges and aspect ratio
#'
#' Inspect a ggplot built with spatial coordinates and return the x/y ranges
#' and the effective aspect ratio. If the target CRS is geographic
#' (longitude/latitude), the ratio is adjusted by cos(mean(latitude)).
#'
#' Note: This inspects the plot scales via ggplot2 internals (layer scales),
#' so the plot should include coordinate limits (e.g., coord_sf with xlim/ylim)
#' to be meaningful.
#'
#' @param map A ggplot object (typically using coord_sf).
#' @param crs A coordinate reference system (CRS) used to determine whether the
#'   plot is in long/lat. Passed to sf::st_is_longlat().
#'
#' @return A list with components:
#'   \item{xrange}{Numeric length of x extent}
#'   \item{yrange}{Numeric length of y extent}
#'   \item{aspect_ratio}{Numeric width-to-height ratio after CRS adjustment}
#'
#' @keywords internal
get_map_range <- function(map, crs) {
    xranges <- ggplot2::layer_scales(map)$x$range$range
    yranges <- ggplot2::layer_scales(map)$y$range$range
    if (sf::st_is_longlat(crs)) {
        # refer to source code in coord_sf
        ratio <- cos(mean(yranges) * pi / 180)
    } else {
        ratio <- 1.0
    }
    xrange <- diff(xranges)[1]
    yrange <- diff(yranges)[1]

    aspect.ratio <- xrange / yrange * ratio
    return(list(xrange = xrange, yrange = yrange, aspect_ratio = aspect.ratio))
}

#' Get map aspect ratio
#'
#' Convenience wrapper around [get_map_range()] returning only the numeric
#' aspect ratio.
#'
#' @param map A ggplot object.
#' @param crs A coordinate reference system (CRS).
#'
#' @return A single numeric aspect ratio (width/height).
#' @keywords internal
get_map_aspect_ratio <- function(map, crs) {
    return(get_map_range(map, crs)$aspect_ratio)
}

#' Convert a ggplot to an inset layer
#'
#' Helper around [cowplot::draw_plot()] that computes missing width/height from
#' the inset's aspect ratio and the full canvas aspect ratio.
#'
#' - If both `inset_width` and `inset_height` are NULL, `inset_height` defaults
#'   to 0.2 (with a warning) and width is derived from aspect ratios.
#' - If only one of width/height is provided, the other is derived to preserve
#'   the inset aspect ratio on the full canvas.
#'
#' For most users, prefer [with_inset()] which orchestrates this automatically.
#'
#' @param inset_map A ggplot object to be used as the inset.
#' @param crs A CRS used to compute the inset's aspect ratio when needed.
#' @param x,y Numbers in \[0, 1\] for the bottom-left location on the canvas.
#' @param inset_width,inset_height Size of the inset as a fraction of the full
#'   canvas width/height. May be NULL to auto-derive.
#' @param inset_aspect_ratio Optional numeric aspect ratio of the inset itself.
#'   When NULL, it is computed from `inset_map` and `crs`.
#' @param full_aspect_ratio Width-to-height ratio of the full canvas (default 1).
#' @param ... Passed to [cowplot::draw_plot()].
#'
#' @return A cowplot layer that can be added to `ggdraw()`.
#'
#' @examples
#' library(ggplot2)
#' library(cowplot)
#'
#' # Create main plot
#' main_plot <- ggplot(mtcars, aes(mpg, wt)) +
#'     geom_point()
#'
#' # Create inset plot
#' inset_plot <- ggplot(iris, aes(Sepal.Length, Sepal.Width)) +
#'     geom_point()
#'
#' # Convert to inset
#' inset <- gg2inset(inset_plot, sf::st_crs(4326),
#'     x = 0.7, y = 0.7,
#'     inset_width = 0.3, inset_height = 0.3
#' )
#'
#' # Combine plots
#' ggdraw(main_plot) + inset
#'
#' @export
gg2inset <- function(inset_map, crs, x, y, inset_width = NULL, inset_height = NULL, inset_aspect_ratio = NULL, full_aspect_ratio = 1.0, ...) {
    if (is.null(inset_aspect_ratio)) {
        inset_aspect_ratio <- get_map_aspect_ratio(inset_map, crs)
    }
    real_inset_aspect_ratio <- inset_aspect_ratio / full_aspect_ratio
    if (is.null(inset_height) && is.null(inset_width)) {
        inset_height <- 0.2
        warning("Both inset_height and inset_width are NULL. Defaulting to inset_height = 0.2.")
    }
    if (is.null(inset_width)) {
        inset_width <- inset_height * real_inset_aspect_ratio
    }
    if (is.null(inset_height)) {
        inset_height <- inset_width / real_inset_aspect_ratio
    }
    return(
        cowplot::draw_plot(
            inset_map,
            x = x, y = y,
            width = inset_width, height = inset_height,
            ...
        )
    )
}

#' Add a border around a map plot
#'
#' Returns a small theme that draws a rectangular border around the plot area.
#' Handy for visually separating inset plots from the main plot.
#'
#' @param color Border color. Default "black".
#' @param linewidth Border line width. Default 1.
#' @param fill Background fill color. Default "white".
#' @param ... Passed to [ggplot2::element_rect()].
#'
#' @return A ggplot2 theme to add with `+`.
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(mpg, wt)) +
#'     geom_point() +
#'     map_border(color = "red", linewidth = 2)
#'
#' @export
map_border <- function(color = "black", linewidth = 1, fill = "white", ...) {
    return(ggplot2::theme(
        plot.background = ggplot2::element_rect(color = color, linewidth = linewidth, fill = fill, ...),
    ))
}
