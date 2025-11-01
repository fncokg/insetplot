#' Merge named vectors, keep last
#'
#' Internal helper that combines two named vectors and, for duplicated names,
#' retains the last occurrence.
#'
#' @param x A named vector.
#' @param val A named vector to merge into `x`.
#'
#' @return A merged named vector with duplicates removed.
#' @keywords internal
#' @noRd
.modifyArray <- function(x, val) {
    out <- c(x, val)
    out[!duplicated(names(out), fromLast = TRUE)]
}

#' Union of multiple bounding boxes
#'
#' Internal helper that returns the overall extent (ymin, xmin, xmax, ymax)
#' covering all provided bounding boxes.
#'
#' @param bbox_list A list of bounding boxes as named numeric vectors with
#'   names: ymin, xmin, xmax, ymax.
#'
#' @return A named numeric vector (ymin, xmin, xmax, ymax).
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

#' Compose a main plot with inset(s)
#'
#' Build a combined plot using a base ggplot and an inset configuration created
#' by [config_insetmap()]. For each plot specification in the configuration, the
#' function either uses the provided `spec$plot` or the supplied `plot` and adds
#' spatial coordinates via [ggplot2::coord_sf()] with the given bounding box.
#' Non-main subplots receive a border from [map_border()].
#'
#' The argument `.as_is = TRUE` returns the input `plot` unchanged and does not
#' require any configuration. This is convenient for reusing the same plotting
#' code outside the inset workflow or for testing.
#'
#' @param plot A ggplot object used as the default for each subplot (unless a
#'   specific spec provides its own `plot`).
#' @param .cfg An inset configuration (class "insetcfg"). Defaults to
#'   [last_insetcfg()].
#' @param .as_is Logical. If TRUE, return `plot` as-is without creating insets.
#'
#' @return If `.return_subplots = FALSE`, a cowplot canvas (inherits from
#'   ggplot) containing the main plot plus inset layers. If TRUE, a list with:
#'   \item{full}{The combined plot}
#'   \item{subplots}{A list of individual subplot ggplot objects}
#'
#' @details
#' - Bounding boxes come from each `plot_spec()` in `.cfg$specs`. Missing bbox
#'   values are filled using the overall extent if available in the configuration.
#' - Coordinate systems are applied with `coord_sf(default_crs = .cfg$from_crs,
#'   crs = .cfg$to_crs, xlim/ylim = bbox, expand = FALSE)`.
#' - Inset sizes: when a spec has `no_scale = TRUE`, the inset width/height are
#'   derived from the spatial ranges relative to the main plot; otherwise the
#'   requested `width`/`height` are used.
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
#'     specs = list(
#'         plot_spec(main = TRUE),
#'         plot_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc = "left bottom", width = 0.3
#'         )
#'     ),
#'     full_ratio = 16 / 9
#' )
#'
#' base <- ggplot(nc, aes(fill = AREA)) +
#'     geom_sf() +
#'     theme_void()
#' with_inset(base)
#'
#' @seealso [config_insetmap()], [plot_spec()], [last_insetcfg()]
#' @export
with_inset <- function(plot, .cfg = last_insetcfg(), .as_is = FALSE) {
    if (.as_is) {
        return(plot)
    }

    # Check if configuration is available
    if (is.null(.cfg)) {
        stop("No inset configuration found. Please run config_insetmap() first.", call. = FALSE)
    }

    specs <- .cfg$specs

    main_idx <- NULL

    subplots <- lapply(seq_len(length(specs)), function(i) {
        spec <- specs[[i]]
        if (is.null(spec$plot)) {
            subplot <- plot
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

        if (spec$main) {
            main_idx <<- i
        } else {
            subplot <- subplot + do.call(map_border, .cfg$border_args)
        }
        return(subplot)
    })

    main_gg <- subplots[[main_idx]]

    main_range <- get_map_range(main_gg, .cfg$to_crs)

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
            inset_range <- get_map_range(gg, .cfg$to_crs)
            inset_width <- inset_range$xrange / main_range$xrange * main_wr
            inset_height <- inset_range$yrange / main_range$yrange * main_hr
        } else {
            inset_width <- inset$width
            inset_height <- inset$height
        }
        gg2inset(gg, crs = .cfg$to_crs, x = inset$loc_left, y = inset$loc_bottom, inset_width = inset_width, inset_height = inset_height, full_aspect_ratio = .cfg$full_ratio)
    })

    map_full <- cowplot::ggdraw(main_gg) + inset_plots
    return(map_full)
}
