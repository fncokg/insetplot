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
#' @return A ggplot2 theme object to add to a ggplot with `+`.
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(mpg, wt)) +
#'     geom_point() +
#'     map_border(color = "red", linewidth = 2)
#'
#' @seealso [with_inset()]
#' @export
map_border <- function(color = "black", linewidth = 1, fill = "white", ...) {
    return(ggplot2::theme(
        plot.background = ggplot2::element_rect(color = color, linewidth = linewidth, fill = fill, ...),
    ))
}

#' Compose a main plot with inset(s)
#'
#' Build a combined plot using an inset configuration created by [config_insetmap()].
#' For each plot specification in the configuration, the function either uses the
#' provided `spec$plot` or the supplied `plot` parameter and adds spatial coordinates
#' via [ggplot2::coord_sf()] with the given bounding box. Non-main subplots receive
#' a border from [map_border()].
#'
#' The argument `.as_is = TRUE` returns the input `plot` unchanged and does not
#' require any configuration. This is convenient for reusing the same plotting
#' code outside the inset workflow or for testing.
#'
#' @param plot Optional. A ggplot object used as the default for each subplot
#'   (unless a specific spec provides its own `plot`). If NULL and all specs have
#'   their own `plot` defined, this parameter is ignored. Default NULL.
#' @param .cfg An inset configuration (class "insetcfg"), typically created by
#'   [config_insetmap()]. Defaults to [last_insetcfg()] if NULL.
#' @param .as_is Logical. If TRUE, return `plot` as-is without creating insets.
#'   Default FALSE. Requires `plot` to be non-NULL.
#' @param .return_subplots Logical. If FALSE (default), returns a combined plot
#'   using [cowplot::ggdraw()] with the main plot and inset layers. If TRUE,
#'   returns a list with: \item{full}{The combined plot} \item{subplots}{A list
#'   of individual ggplot objects for each subplot}.
#'
#' @return If `.return_subplots = FALSE`, a ggplot object (via cowplot::ggdraw)
#'   containing the main plot plus inset layers. If TRUE, a list with elements
#'   `full` (the combined plot) and `subplots` (individual ggplot objects).
#'
#' @details
#' - Bounding boxes come from each `inset_spec()` in `.cfg$specs`. Missing bbox
#'   values are filled using the overall extent from cropped data in the configuration.
#' - Each subplot receives coordinate system transformation via `coord_sf()` using
#'   `default_crs = .cfg$from_crs`, `crs = .cfg$to_crs`, and the spec's bbox.
#' - Inset sizes are determined by:
#'   \itemize{
#'     \item If `spec$scale_factor` is not NA, width/height are derived from
#'       spatial ranges relative to the main plot multiplied by scale_factor.
#'     \item Otherwise, `width` and/or `height` from the spec are used. If one
#'       is NA, it is computed from the other using the inset's aspect ratio.
#'   }
#' - Non-main insets are positioned using `cowplot::draw_plot()` with
#'   `halign = 0, valign = 0` (anchored at bottom-left).
#' - Best results are achieved when the saved image width-to-height ratio equals
#'   `.cfg$full_ratio`.
#'
#' @examples
#' library(sf)
#' library(ggplot2)
#'
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#'
#' config_insetmap(
#'     data_list = list(nc),
#'     specs = list(
#'         inset_spec(main = TRUE),
#'         inset_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc = "left bottom", width = 0.3
#'         )
#'     ),
#'     full_ratio = 16 / 9
#' )
#'
#' # Supply base plot for all subplots
#' base <- ggplot(nc, aes(fill = AREA)) +
#'     geom_sf() +
#'     theme_void()
#' with_inset(base)
#'
#' # Or supply custom plots in each inset_spec, then call with_inset() without plot
#' config_insetmap(
#'     data_list = list(nc),
#'     specs = list(
#'         inset_spec(main = TRUE, plot = base),
#'         inset_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc = "left bottom", width = 0.3,
#'             plot = base # Each spec has its own plot
#'         )
#'     ),
#'     full_ratio = 16 / 9
#' )
#' with_inset() # plot parameter is optional
#'
#' @seealso [config_insetmap()], [inset_spec()], [last_insetcfg()], [map_border()]
#' @export
with_inset <- function(plot = NULL, .cfg = last_insetcfg(), .as_is = FALSE, .return_subplots = FALSE) {
    if (.as_is) {
        return(plot)
    }

    # Check if configuration is available
    if (is.null(.cfg)) {
        stop("No inset configuration found. Please run config_insetmap() first.", call. = FALSE)
    }

    specs <- .cfg$specs

    # Create each subplot, and do coordinate transformation here
    subplots <- lapply(seq_len(length(specs)), function(i) {
        spec <- specs[[i]]
        if (is.null(spec$plot)) {
            subplot <- plot
            if (!spec$main) {
                subplot <- subplot + do.call(map_border, .cfg$border_args)
            }
        } else {
            subplot <- spec$plot
        }

        subplot <- subplot + coord_sf(
            default_crs = .cfg$from_crs,
            crs = .cfg$to_crs,
            xlim = c(spec$bbox["xmin"], spec$bbox["xmax"]),
            ylim = c(spec$bbox["ymin"], spec$bbox["ymax"]),
            expand = FALSE
        )


        return(subplot)
    })

    # Now process the aspect ratio and sizes

    main_data_bbox <- specs[[.cfg$main_idx]]$data_bbox

    main_xrange <- main_data_bbox[["xmax"]] - main_data_bbox[["xmin"]]
    main_yrange <- main_data_bbox[["ymax"]] - main_data_bbox[["ymin"]]
    main_ratio <- main_xrange / main_yrange
    full_ratio <- .cfg$full_ratio

    # Determine whether main plot will be compressed
    main_wr <- 1.0
    main_hr <- 1.0
    if (full_ratio > main_ratio) {
        # full is wider
        main_wr <- main_ratio / full_ratio
    } else if (full_ratio < main_ratio) {
        # full is taller
        main_hr <- full_ratio / main_ratio
    }

    inset_plots <- lapply(seq_len(length(subplots)), function(i_inset) {
        gg <- subplots[[i_inset]]
        inset <- specs[[i_inset]]
        if (inset$main) {
            return(NULL)
        }
        inset_data_bbox <- inset$data_bbox
        inset_xrange <- inset_data_bbox[["xmax"]] - inset_data_bbox[["xmin"]]
        inset_yrange <- inset_data_bbox[["ymax"]] - inset_data_bbox[["ymin"]]
        inset_ratio <- inset_xrange / inset_yrange
        real_inset_ratio <- inset_ratio / full_ratio

        # Determine width and height
        width <- inset$width
        height <- inset$height
        if (!is.na(inset$scale_factor)) {
            # Automatically derive width/height based on scale factor, overriding user defined values

            width <- (inset_xrange / main_xrange) * main_wr * inset$scale_factor
            height <- (inset_yrange / main_yrange) * main_hr * inset$scale_factor
        } else {
            # In this case, at least one of width/height is provided by the user
            if (is.na(width)) {
                width <- height * real_inset_ratio
            }
            if (is.na(height)) {
                height <- width / real_inset_ratio
            }
        }

        # Determine left and bottom positions
        loc_left <- inset$loc_left
        loc_bottom <- inset$loc_bottom
        loc_offset <- 0.02
        if (is.na(loc_left)) {
            loc_left <- switch(inset$hpos,
                "left" = 0 + loc_offset,
                "center" = 0.5 - width / 2,
                "right" = 1 - width - loc_offset
            )
        }
        if (is.na(loc_bottom)) {
            loc_bottom <- switch(inset$vpos,
                "bottom" = 0 + loc_offset,
                "center" = 0.5 - height / 2,
                "top" = 1 - height - loc_offset
            )
        }
        cowplot::draw_plot(
            gg,
            x = loc_left,
            y = loc_bottom,
            width = width,
            height = height,
            # target plot is anchored at bottom-left if the specified width-height ratio does not match the real ratio
            halign = 0,
            valign = 0
        )
    })

    map_full <- cowplot::ggdraw(subplots[[.cfg$main_idx]]) + inset_plots
    if (.return_subplots) {
        return(list(
            full = map_full,
            subplots = subplots
        ))
    }
    return(map_full)
}

ggsave_inset <- function(filename, plot = last_plot(), device = NULL, path = NULL, scale = 1, width = NA, height = NA, ...) {
    .cfg <- last_insetcfg()
    ratio <- .cfg$full_ratio
    if (is.na(width) && is.na(height)) {
        width <- 8
        height <- width / ratio
    } else if (is.na(width)) {
        width <- height * ratio
    } else if (is.na(height)) {
        height <- width / ratio
    } else {
        warning("Both width and height are provided. The output aspect ratio may not match the inset configuration.")
    }
    ggsave(filename, plot = plot, device = device, path = path, scale = scale, width = width, height = height, ...)
}
