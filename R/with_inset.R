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
#' a border from [map_border()]. Insets are composed using [patchwork::inset_element()].
#'
#' @param plot Optional. Either:
#'   \itemize{
#'     \item A single ggplot object to use as the base plot for all subplots (unless a spec has its own plot)
#'     \item A list of ggplot objects matching the length of `.cfg$specs`, where each element
#'       corresponds to a subplot in the configuration.
#'     \item NULL if all specs have their own plot defined (plot is fully optional in this case)
#'   }
#'   NOTE: you SHOULD NOT pass [ggplot2::coord_sf()] into this plot manually. The coordinate system is handled internally.
#'   Default NULL.
#' @param .cfg An inset configuration (class "insetcfg") created by
#'   [config_insetmap()]. Defaults to [last_insetcfg()].
#' @param .as_is Logical. If TRUE, return `plot` as-is without creating insets.
#'   Useful when debugging or code reuse outside the inset workflow. Default FALSE.
#' @param .return_details Logical. If FALSE (default), returns a combined plot
#'   with the main plot and inset layers. If TRUE,
#'   returns a list. See 'Value' section for details.
#'
#' @return If `.return_details = FALSE`, a ggplot object containing the main plot plus inset layers. If TRUE, a list with elements:
#'   \item{full}{The combined plot}
#'   \item{subplots}{Individual ggplot objects for each subplot}
#'   \item{subplot_layouts}{A `list` of layout information (`x`, `y`, `width`, `height`) for each inset}
#'   \item{main_ratio}{Width-to-height ratio of the main plot's data extent}
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
#'             xmin = -82, xmax = -80.5, ymin = 35.5, ymax = 36,
#'             loc = "left bottom", scale_factor = 2
#'         )
#'     )
#' )
#'
#' # Supply base plot for all subplots
#' base <- ggplot(nc, aes(fill = AREA)) +
#'     geom_sf() +
#'     scale_fill_viridis_c() +
#'     guides(fill = "none") +
#'     theme_void()
#' with_inset(base)
#'
#' # Or supply custom plots in each inset_spec, then call with_inset() without plot
#' config_insetmap(
#'     data_list = list(nc),
#'     specs = list(
#'         inset_spec(main = TRUE, plot = base),
#'         inset_spec(
#'             xmin = -82, xmax = -80.5, ymin = 35.5, ymax = 36,
#'             loc = "left bottom", scale_factor = 2,
#'             plot = base # Each spec has its own plot
#'         )
#'     )
#' )
#' with_inset() # plot parameter is optional now
#'
#' @seealso [config_insetmap()]
#' @export
with_inset <- function(plot = NULL, .cfg = last_insetcfg(), .as_is = FALSE, .return_details = FALSE) {
    if (.as_is) {
        return(plot)
    }

    # Check if configuration is available
    if (is.null(.cfg)) {
        stop("No inset configuration found. Please run config_insetmap() first.", call. = FALSE)
    }

    specs <- .cfg$specs

    if (!inherits(plot, "gg") && inherits(plot, "list")) {
        stopifnot(length(plot) == length(specs))
        for (i in seq_along(specs)) {
            stopifnot(!is.null(plot[[i]]))
            specs[[i]]$plot <- plot[[i]]
        }
    }

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

    main_data_features <- get_bbox_features(specs[[.cfg$main_idx]]$data_bbox)

    main_xrange <- main_data_features$x_range
    main_yrange <- main_data_features$y_range
    main_ratio <- main_data_features$xy_ratio

    subplot_layouts <- lapply(seq_len(length(subplots)), function(i_inset) {
        inset <- specs[[i_inset]]
        if (inset$main) {
            return(NULL)
        }
        # Determine width and height
        inset_data_features <- get_bbox_features(inset$data_bbox)
        inset_xrange <- inset_data_features$x_range
        inset_yrange <- inset_data_features$y_range
        width <- inset$width
        height <- inset$height

        if (!is.na(inset$scale_factor)) {
            # Automatically derive width/height based on scale factor, overriding user defined values
            width <- (inset_xrange / main_xrange) * inset$scale_factor
            height <- (inset_yrange / main_yrange) * inset$scale_factor
        } else {
            inset_ratio <- (inset_xrange / main_xrange) / (inset_yrange / main_yrange)
            # In this case, at least one of width/height is provided by the user
            if (is.na(width)) {
                width <- height * inset_ratio
            }
            if (is.na(height)) {
                height <- width / inset_ratio
            }
        }

        # Determine left and bottom positions
        loc_left <- inset$loc_left
        loc_bottom <- inset$loc_bottom
        loc_offset <- 0
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
        list(
            x = loc_left,
            y = loc_bottom,
            width = width,
            height = height
        )
    })

    inset_plots <- lapply(seq_len(length(subplots)), function(i_inset) {
        if (specs[[i_inset]]$main) {
            return(NULL)
        }
        layout <- subplot_layouts[[i_inset]]
        patchwork::inset_element(
            subplots[[i_inset]],
            left = layout$x,
            bottom = layout$y,
            right = layout$width + layout$x,
            top = layout$height + layout$y,
            align_to = "panel",
            on_top = TRUE,
            ignore_tag = TRUE,
            clip = FALSE
        )
    })

    map_full <- subplots[[.cfg$main_idx]] + inset_plots
    if (.return_details) {
        return(list(
            full = map_full,
            subplots = subplots,
            subplot_layouts = subplot_layouts,
            main_ratio = main_ratio
        ))
    }
    return(map_full)
}

#' Save a composed inset plot with appropriate dimensions
#'
#' A wrapper around [ggplot2::ggsave()] that automatically calculates the output
#' dimensions based on the full ratio defined in the inset configuration.
#' This ensures the saved image maintains the correct aspect ratio for proper
#' rendering of all subplots.
#'
#' All parameters are the same as [ggplot2::ggsave()], except that you only need to
#' provide either `width` or `height`, and the other dimension will be calculated
#' automatically to match the aspect ratio defined in the inset configuration.
#'
#' @param filename Filename to save the plot to. Passed directly to [ggplot2::ggsave()].
#' @param plot The plot to save. Default [ggplot2::last_plot()].
#' @param device Device to save to (e.g., "png", "pdf"). Default NULL (inferred from filename).
#' @param path Directory path for saving. Default NULL (current directory).
#' @param scale Scaling factor. Default 1.
#' @param width,height Width and height in inches. You only need to provide one; the other
#'   will be calculated automatically. Default NA.
#' @param ... Additional arguments passed to [ggplot2::ggsave()].
#' @param ratio_scale Optional scaling factor to adjust the aspect ratio. Default 1.0. Use when
#'   there are extra elements (e.g., titles, legends) that affect the overall image dimensions.
#'   For example, set to 1.1 for extra width when a legend is present on the left/right side.
#' @param .cfg An inset configuration (class `insetcfg`) created by [config_insetmap()].
#'
#' @return NULL (invisibly). Saves the plot to disk.
#'
#' @details
#' The function automatically calculates width and height based on `.cfg$main_ratio`
#' to maintain aspect ratio consistency. If both width and height are provided,
#' a warning is issued as the output aspect ratio may not match the configuration.
#'
#' @examples
#' \dontrun{
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
#'     )
#' )
#'
#' base <- ggplot(nc, aes(fill = AREA)) +
#'     geom_sf() +
#'     scale_fill_viridis_c() +
#'     guides(fill = "none") +
#'     theme_void()
#' with_inset(base)
#'
#' # Save with automatically calculated height
#' ggsave_inset("inset_map.png", width = 10)
#' }
#' @seealso [with_inset()]
#' @export
ggsave_inset <- function(filename, plot = last_plot(), device = NULL, path = NULL, scale = 1, width = NA, height = NA, ..., ratio_scale = 1.0, .cfg = last_insetcfg()) {
    ratio <- .cfg$main_ratio * ratio_scale
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
