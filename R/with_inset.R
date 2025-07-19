#' Modify Array by Merging and Deduplicating
#'
#' Internal function that merges two named vectors, keeping the last occurrence
#' of each name.
#'
#' @param x A named vector.
#' @param val A named vector to merge with x.
#'
#' @return A merged named vector with duplicates removed.
#' @keywords internal
#'
#' @noRd
.modifyArray <- function(x, val) {
    out <- c(x, val)
    out[!duplicated(names(out), fromLast = TRUE)]
}

#' Calculate Widest Bounding Box
#'
#' Internal function that calculates the union of multiple bounding boxes,
#' returning the widest extent that encompasses all input boxes.
#'
#' @param bbox_list A list of bounding box vectors with named elements
#'   (ymin, xmin, xmax, ymax).
#'
#' @return A named vector representing the widest bounding box.
#' @keywords internal
#' @noRd
.widest_bbox <- function(bbox_list) {
    mat <- do.call(rbind, bbox_list)
    c(
        ymin = min(mat[, "ymin"]),
        xmin = min(mat[, "xmin"]),
        xmax = max(mat[, "xmax"]),
        ymax = max(mat[, "ymax"])
    )
}

#' Create Inset Plots with Spatial Data
#'
#' Evaluates a plot expression using configured spatial data and plot specifications
#' to create a combined visualization with main plot and inset plots.
#'
#' @param plot_expr Code for map visualization.
#'   This should be an expression that generates a ggplot object using the spatial data objects configured in [config_insetmap()].
#' @param .cfg An inset configuration object. If NULL, uses the last configuration
#'   set by [config_insetmap()]. Default is [last_insetcfg()].
#' @param .return_subplots Logical. If TRUE, returns a list with both the combined
#'   plot and individual subplots. Default is FALSE.
#' @param .as_is Logical. If TRUE, returns the plot expression as-is without
#'   creating insets. Useful for debugging and code reuse. Default is FALSE.
#'
#' @return If `.return_subplots` is FALSE, returns a cowplot drawing canvas object
#'   (which inherits from ggplot) containing the combined main plot and insets.
#'   If TRUE, returns a list with components:
#'   \item{full}{The combined plot (cowplot canvas)}
#'   \item{subplots}{A list of individual subplot objects}
#'
#' @note
#' The best display of the inset map is achieved only when the output image
#' is saved with a width-height ratio that matches the `full_ratio` specified
#' in [config_insetmap()]. Therefore, plots displayed in RStudio or other viewers
#' may not accurately reflect the final output.
#'
#' @details
#' This function works by:
#' 1. Cropping the spatial data according to each plot specification's bounding box
#' 2. Evaluating the plot expression in an environment containing the cropped data
#' 3. Adding coordinate systems and borders as specified
#' 4. Combining all plots using cowplot
#'
#' The spatial data objects are made available in the plot expression environment
#' using the names specified when configuring the inset map.
#'
#' @examples
#' \dontrun{
#' library(sf)
#' library(ggplot2)
#'
#' # Load spatial data
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"))
#'
#' # Configure inset map
#' config_insetmap(
#'     plot_data = nc,
#'     specs = list(
#'         plot_spec(main = TRUE),
#'         plot_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc_left = 0.7, loc_bottom = 0.7,
#'             width = 0.3
#'         )
#'     )
#' )
#'
#' # Create inset plot
#' with_inset({
#'     ggplot(nc) +
#'         geom_sf(aes(fill = AREA)) +
#'         theme_void()
#' })
#' }
#'
#' @seealso [config_insetmap()], [plot_spec()], [last_insetcfg()]
#' @export
with_inset <- function(plot_expr, .cfg = last_insetcfg(), .return_subplots = FALSE, .as_is = FALSE) {
    if (.as_is) {
        return(plot_expr)
    }

    # Check if configuration is available
    if (is.null(.cfg)) {
        stop("No inset configuration found. Please run config_insetmap() first.", call. = FALSE)
    }

    # Check has one main plot
    main_count <- sum(sapply(.cfg$specs, function(x) x$main))
    if (main_count == 0) {
        stop("Exactly one plot specification must have main = TRUE", call. = FALSE)
    } else if (main_count > 1) {
        stop("Only one plot specification can have main = TRUE", call. = FALSE)
    }

    plot_expr <- enexpr(plot_expr)

    data_bboxes <- lapply(.cfg$data, function(x) {
        st_bbox(x)
    })

    full_bbox <- .widest_bbox(data_bboxes)

    specs <- lapply(.cfg$specs, function(spec) {
        spec$bbox <- .modifyArray(full_bbox, spec$bbox)
        spec
    })

    # print(specs)

    main_idx <- NULL

    subplots <- lapply(seq_len(length(specs)), function(i) {
        spec <- specs[[i]]
        env_list <- lapply(.cfg$data, function(x) {
            st_crop(x, spec$bbox)
        })
        names(env_list) <- names(.cfg$data)
        envir <- new_environment(env_list, caller_env())

        subplot <- eval_tidy(plot_expr, env = envir)

        subplot <- subplot + coord_sf(crs = .cfg$crs)

        if (spec$main) {
            main_idx <<- i
        } else {
            subplot <- subplot + do.call(map_border, .cfg$border_args)
        }
        return(subplot)
    })

    main_gg <- subplots[[main_idx]]

    main_range <- get_map_range(main_gg, .cfg$crs)

    # Determine whether main plot will be compressed
    main_wr <- 1.0
    main_hr <- 1.0
    if (.cfg$full_ratio > main_range$aspect_ratio) {
        # full is wider
        main_wr <- main_range$aspect_ratio / .cfg$full_ratio
    } else if (.cfg$full_ratio < main_range$aspect_ratio) {
        # full is taller
        main_hr <- .cfg$full_ratio / main_range$aspect_ratio
    }

    inset_plots <- lapply(seq_len(length(subplots)), function(i_inset) {
        if (i_inset == main_idx) {
            return(NULL) # Skip the main plot
        }
        gg <- subplots[[i_inset]]
        inset <- specs[[i_inset]]
        # In the normal case, only one of the width or height is provided. This case will be handled by gg2inset.
        # If both are provided, ggplot2 automatically scales the inset plot to fit the provided width and height.
        # Here, we should only handle the case where no_scale is TRUE.
        if (inset$no_scale) {
            inset_range <- get_map_range(gg, .cfg$crs)
            inset_width <- inset_range$xrange / main_range$xrange * main_wr
            inset_height <- inset_range$yrange / main_range$yrange * main_hr
        } else {
            inset_width <- inset$width
            inset_height <- inset$height
        }
        gg2inset(gg, crs = .cfg$crs, x = inset$loc_left, y = inset$loc_bottom, inset_width = inset_width, inset_height = inset_height, full_aspect_ratio = .cfg$full_ratio)
    })

    map_full <- cowplot::ggdraw(main_gg) + inset_plots
    if (.return_subplots) {
        return(list(full = map_full, subplots = subplots))
    } else {
        return(map_full)
    }
}
