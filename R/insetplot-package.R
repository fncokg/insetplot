#' insetplot: Compose ggplot2 maps with insets
#'
#' insetplot lets you create ggplot2 maps with inset maps easily and flexibly. It handles
#' spatial configuration, aspect ratios, and plot composition automatically.
#'
#' @section Core workflow:
#' \enumerate{
#'   \item Build a configuration with \code{\link{config_insetmap}} and \code{\link{inset_spec}} by specifying necessary parameters (position and size).
#'   \item Pass your \code{ggplot} object to \code{\link{with_inset}} to generate the composed figure.
#'   \item Save the final plot with \code{\link{ggsave_inset}} to maintain correct aspect ratio.
#' }
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{inset_spec}}: Define bbox, position (\code{loc} or \code{loc_left}/\code{loc_bottom}),
#'     and size (prefer \code{scale_factor}; or provide one of \code{width}/\code{height}).
#'   \item \code{\link{config_insetmap}}: Create and store the configuration.
#'   \item \code{\link{with_inset}}: Crop each subplot, compose subplots and calculate sizes and positions automatically.
#'   \item \code{\link{ggsave_inset}}: Save with the correct aspect ratio derived from \code{\link{with_inset}},
#'     with optional \code{ratio_scale} for fine-tuning.
#' }
#'
#' @section Example:
#' \preformatted{
#' library(sf)
#' library(ggplot2)
#' library(insetplot)
#'
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#'
#' # Approach 1: shared base plot for all subplots
#' config_insetmap(
#'   data_list = list(nc),
#'   specs = list(
#'     inset_spec(main = TRUE),
#'     inset_spec(
#'       xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'       loc = "left bottom", scale_factor = 0.5
#'     )
#'   )
#' )
#' base_map <- ggplot(nc, aes(fill = AREA)) +
#'   geom_sf() +
#'   scale_fill_viridis_c() +
#'   guides(fill = "none") +
#'   theme_void()
#' p <- with_inset(base_map)
#'
#' # Approach 2: provide custom plots in each spec
#' config_insetmap(
#'   data_list = list(nc),
#'   specs = list(
#'     inset_spec(main = TRUE, plot = base_map),
#'     inset_spec(
#'       xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'       loc = "left bottom", scale_factor = 0.5,
#'       plot = base_map + ggtitle("Detail")
#'     )
#'   )
#' )
#' p <- with_inset()  # plot argument is optional here
#'
#' # Save with the correct aspect ratio
#' ggsave_inset("map.png", p, width = 10)
#' }
#'
#' @seealso \code{\link{inset_spec}}, \code{\link{config_insetmap}},
#'   \code{\link{with_inset}}, \code{\link{ggsave_inset}}, \code{\link{map_border}},
#'   \code{\link{last_insetcfg}}
#'
#' @name insetplot-package
#' @aliases insetplot
#' @import ggplot2
#' @import sf
#' @import patchwork
"_PACKAGE"
