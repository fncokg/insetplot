#' Get Map Range and Aspect Ratio
#'
#' Calculates the coordinate ranges and aspect ratio of a ggplot map object,
#' taking into account the coordinate reference system.
#'
#' @param map A ggplot object containing a map.
#' @param crs A coordinate reference system specification.
#'
#' @return A list with components:
#'   \item{xrange}{The range of x-coordinates}
#'   \item{yrange}{The range of y-coordinates}
#'   \item{aspect_ratio}{The aspect ratio of the map}
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

#' Get Map Aspect Ratio
#'
#' A convenience function that returns only the aspect ratio of a map.
#'
#' @param map A ggplot object containing a map.
#' @param crs A coordinate reference system specification.
#'
#' @return Numeric value representing the aspect ratio.
#' @keywords internal
get_map_aspect_ratio <- function(map, crs) {
    return(get_map_range(map, crs)$aspect_ratio)
}

#' Convert ggplot to Inset Plot
#'
#' A wrapper of [cowplot::draw_plot()] handling appropriate scaling and positioning based on the fixed aspect ratio of the inset.
#'
#' The function is only recommended for advanced users who need to create custom insets. For most use cases, it is better to use [with_inset()] which handles the inset creation automatically.
#'
#' @param inset_map A ggplot object to be used as an inset.
#' @param crs A coordinate reference system specification.
#' @param x,y Numeric values between 0 and 1 specifying the position of the
#'   bottom-left corner of the inset within the main plot.
#' @param inset_width,inset_height Numeric values specifying the width and
#'   height of the inset as proportions of the main plot.
#' @param inset_aspect_ratio Numeric value specifying the aspect ratio of the
#'   inset. If NULL, calculated automatically from the inset_map.
#' @param full_aspect_ratio Numeric value specifying the aspect ratio of the
#'   full plot area. Default is 1.0.
#' @param ... Additional arguments passed to [cowplot::draw_plot()].
#'
#' @return A cowplot inset object that can be added to a ggplot.
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

#' Add Border to Map Plot
#'
#' Creates a theme element that adds a border around a map plot. Useful for
#' distinguishing inset plots from the main plot.
#'
#' @param color Character string specifying the border color. Default is "black".
#' @param linewidth Numeric value specifying the border line width. Default is 1.
#' @param fill Character string specifying the background fill color. Default is "white".
#' @param ... Additional arguments passed to [ggplot2::element_rect()].
#'
#' @return A ggplot2 theme object that can be added to a plot.
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
