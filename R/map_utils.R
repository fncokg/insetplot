.fill_bbox <- function(bbox, overall_bbox) {
    for (name in names(bbox)) {
        if (is.na(bbox[[name]])) {
            bbox[[name]] <- overall_bbox[[name]]
        }
    }
    return(bbox)
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
