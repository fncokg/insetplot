.fill_bbox <- function(bbox, overall_bbox) {
    for (name in names(bbox)) {
        if (is.na(bbox[[name]])) {
            if (is.null(overall_bbox)) {
                stop("Cannot fill missing bbox values without an overall bounding box.")
            }
            bbox[[name]] <- overall_bbox[[name]]
        }
    }
    return(bbox)
}

# This is simply copied from coord_sf.R in ggplot2 with minor modifications
# to allow for different methods of calculating the limits bbox
.calc_limits_bbox <- function(method, bbox, crs, default_crs) {
    xlim <- c(bbox[["xmin"]], bbox[["xmax"]])
    ylim <- c(bbox[["ymin"]], bbox[["ymax"]])
    if (!all(is.finite(c(xlim, ylim))) && method != "geometry_bbox") {
        cli::cli_abort(c(
            "Scale limits cannot be mapped onto spatial coordinates in {.fn coord_sf}.",
            "i" = "Consider setting {.code lims_method = \"geometry_bbox\"} or {.code default_crs = NULL}."
        ))
    }

    bbox <- switch(method,
        # For method "box", we take the limits and turn them into a
        # box. We subdivide the box edges into multiple segments to
        # better cover the respective area under non-linear transformation
        box = list(
            x = c(
                rep(xlim[1], 20), seq(xlim[1], xlim[2], length.out = 20),
                rep(xlim[2], 20), seq(xlim[2], xlim[1], length.out = 20)
            ),
            y = c(
                seq(ylim[1], ylim[2], length.out = 20), rep(ylim[2], 20),
                seq(ylim[2], ylim[1], length.out = 20), rep(ylim[1], 20)
            )
        ),
        # For method "geometry_bbox" we ignore all limits info provided here
        geometry_bbox = list(
            x = c(NA_real_, NA_real_),
            y = c(NA_real_, NA_real_)
        ),
        # For method "orthogonal" we simply return what we are given
        orthogonal = list(
            x = xlim,
            y = ylim
        ),
        # For method "cross" we take the mid-point along each side of
        # the scale range for better behavior when box is nonlinear or
        # rotated in projected space
        #
        # Method "cross" is also the default
        cross = ,
        list(
            x = c(rep(mean(xlim), 20), seq(xlim[1], xlim[2], length.out = 20)),
            y = c(seq(ylim[1], ylim[2], length.out = 20), rep(mean(ylim), 20))
        )
    )
    projected_bbox <- sf_transform_xy(bbox, crs, default_crs)
    return(c(
        xmin = min(projected_bbox$x, na.rm = TRUE),
        xmax = max(projected_bbox$x, na.rm = TRUE),
        ymin = min(projected_bbox$y, na.rm = TRUE),
        ymax = max(projected_bbox$y, na.rm = TRUE)
    ))
}


#' Compute the union bounding box from multiple shapes
#'
#' Calculates the overall bounding box that encompasses all provided spatial shapes.
#'
#' @param shapes A list of sf objects.
#'
#' @return A named numeric vector with elements: `ymin`, `xmin`, `xmax`, `ymax`
#'   representing the union of all input bounding boxes.
#'
#' @examples
#' library(sf)
#'
#' # Load sample data
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#'
#' # Get the bounding box of the entire dataset
#' bbox <- get_widest_bbox(list(nc))
#' bbox
#'
#' @export
get_widest_bbox <- function(shapes) {
    mat <- do.call(rbind, lapply(shapes, st_bbox))
    c(
        ymin = min(mat[, "ymin"]),
        xmin = min(mat[, "xmin"]),
        xmax = max(mat[, "xmax"]),
        ymax = max(mat[, "ymax"])
    )
}

#' Extract width, height, and aspect ratio from a bounding box
#'
#' Computes spatial range and aspect ratio metrics from a bounding box.
#'
#' @param bbox A named numeric vector with elements `xmin`, `xmax`, `ymin`, `ymax`.
#'
#' @return A list with elements:
#'   \item{x_range}{Width (xmax - xmin) of the bounding box}
#'   \item{y_range}{Height (ymax - ymin) of the bounding box}
#'   \item{xy_ratio}{Aspect ratio (x_range / y_range)}
#'
#' @examples
#' # Create a sample bounding box
#' bbox <- c(xmin = -84, xmax = -75, ymin = 33, ymax = 37)
#'
#' # Extract width, height, and aspect ratio
#' features <- get_bbox_features(bbox)
#' features
#'
#' # Access individual components
#' features$x_range
#' features$y_range
#' features$xy_ratio
#'
#' @export
get_bbox_features <- function(bbox) {
    x_range <- bbox[["xmax"]] - bbox[["xmin"]]
    y_range <- bbox[["ymax"]] - bbox[["ymin"]]
    xy_ratio <- x_range / y_range
    return(list(x_range = x_range, y_range = y_range, xy_ratio = xy_ratio))
}
