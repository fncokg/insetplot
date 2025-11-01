#' Create a plot specification for insets
#'
#' Define the spatial extent and positioning for each subplot (main or inset).
#'
#' @param xmin,xmax,ymin,ymax Numeric bbox coordinates for the subplot. Any may
#'   be NA and will be inferred from the overall extent if possible.
#' @param loc A convenience string like "left bottom", "center top", or
#'   "right center". When supplied, it overrides `loc_left`/`loc_bottom` with
#'   predefined anchor positions close to the plot edges (with small margins).
#' @param loc_left,loc_bottom Numbers in \[0, 1\] for the bottom-left position of
#'   the inset on the full canvas. Ignored when `main = TRUE`.
#' @param width,height Optional size of the inset as a fraction of canvas width/
#'   height. Supplying both is allowed but not recommended; aspect ratio will be
#'   prioritized. If both are NULL and `no_scale = FALSE`, `no_scale` is set to
#'   TRUE with a warning.
#' @param no_scale Logical. If TRUE, the inset's width/height are derived from
#'   the spatial ranges relative to the main plot. See [with_inset()].
#' @param main Logical. TRUE marks this spec as the main plot (exactly one).
#' @param plot Optional ggplot object to use for this spec instead of the base
#'   plot passed to [with_inset()].
#'
#' @return A list with elements `bbox`, `loc_left`, `loc_bottom`, `width`,
#'   `height`, `no_scale`, `main`, and `plot`.
#'
#' @examples
#' # Create a main plot specification
#' main_spec <- plot_spec(main = TRUE)
#'
#' # Create an inset plot specification
#' inset_spec <- plot_spec(
#'     xmin = -120, xmax = -100, ymin = 30, ymax = 50,
#'     loc_left = 0.7, loc_bottom = 0.7,
#'     width = 0.3
#' )
#'
#' @export
plot_spec <- function(
    xmin = NA, xmax = NA, ymin = NA, ymax = NA,
    loc = "", loc_left = 0, loc_bottom = 0, width = NULL, height = NULL,
    no_scale = FALSE, main = FALSE, plot = NULL) {
    # Input validation
    if (!is.na(xmin) && !is.na(xmax) && xmin >= xmax) {
        stop("xmin must be less than xmax")
    }
    if (!is.na(ymin) && !is.na(ymax) && ymin >= ymax) {
        stop("ymin must be less than ymax")
    }
    if (loc != "") {
        # parse loc string
        loc <- tolower(loc)
        locs <- strsplit(loc, " ")[[1]]
        horizontal_pos <- locs[1]
        vertical_pos <- locs[2]
        if (horizontal_pos == "left") {
            loc_left <- 0.02
        } else if (horizontal_pos == "center") {
            loc_left <- 0.5
        } else if (horizontal_pos == "right") {
            loc_left <- 0.98
        } else {
            stop("Invalid horizontal position in loc. Use 'left', 'center', or 'right'.")
        }
        if (vertical_pos == "bottom") {
            loc_bottom <- 0.02
        } else if (vertical_pos == "center") {
            loc_bottom <- 0.5
        } else if (vertical_pos == "top") {
            loc_bottom <- 0.98
        } else {
            stop("Invalid vertical position in loc. Use 'bottom', 'center', or 'top'.")
        }
    }
    if (!main) {
        # Only check location and size if not the main plot
        if (loc_left < 0 || loc_left > 1 || loc_bottom < 0 || loc_bottom > 1) {
            stop("loc_left and loc_bottom must be between 0 and 1")
        }
        if (!is.null(width) && (width <= 0 || width > 1)) {
            stop("width must be between 0 and 1")
        }
        if (!is.null(height) && (height <= 0 || height > 1)) {
            stop("height must be between 0 and 1")
        }

        if (!is.null(width) && !is.null(height)) {
            warning("Providing both width and height is not recommended. We will prioritize maintaining aspect ratio.")
        }
        if (no_scale && (is.null(width) || is.null(height))) {
            cat("If no_scale is TRUE, the width and height are directly determined by the main plot, and therefore the width and height will be ignored.")
        }
        if (is.null(width) && is.null(height) && !no_scale) {
            no_scale <- TRUE
            warning("Both width and height are NULL. Setting no_scale to TRUE to determine width and height based on the main plot.")
        }
    }
    return(
        list(
            bbox = c(ymin = ymin, xmin = xmin, xmax = xmax, ymax = ymax),
            loc_left = loc_left,
            loc_bottom = loc_bottom,
            width = width,
            height = height,
            no_scale = no_scale,
            main = main,
            plot = plot
        )
    )
}

#' Configure inset map settings
#'
#' Create and store an inset configuration used by [with_inset()]. The
#' configuration contains subplot specifications, aspect ratio of the full
#' canvas, CRS settings, and border appearance for insets.
#'
#' @param plot_data Reserved for future use; currently ignored. Kept for API
#'   stability.
#' @param specs A non-empty list of [plot_spec()] objects.
#' @param full_ratio Numeric width-to-height ratio of the full canvas. For best
#'   results, save figures with this ratio. Default 1.
#' @param from_crs,to_crs Coordinate reference systems passed to
#'   [ggplot2::coord_sf()] as `default_crs` and `crs` respectively. Defaults are
#'   EPSG:4326 for both.
#' @param border_args A list merged into defaults for [map_border()] arguments
#'   (defaults: `color = "black"`, `linewidth = 1`).
#'
#' @return Invisibly, an object of class "insetcfg" with fields: `specs`,
#'   `full_ratio`, `from_crs`, `to_crs`, and `border_args`. It is also stored as
#'   the last configuration, retrievable via [last_insetcfg()].
#'
#' @examples
#' library(sf)
#'
#' g <- sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
#' d <- sf::st_sf(id = 1, geometry = g)
#'
#' config_insetmap(
#'     plot_data = d,
#'     specs = list(
#'         plot_spec(main = TRUE),
#'         plot_spec(
#'             xmin = -1, xmax = 1, ymin = -1, ymax = 1,
#'             loc_left = 0.7, loc_bottom = 0.7, width = 0.25
#'         )
#'     )
#' )
#'
#' @seealso [plot_spec()], [with_inset()], [last_insetcfg()]
#' @export
#' @import rlang
config_insetmap <- function(plot_data, specs, full_ratio = 1.0, from_crs = sf::st_crs("EPSG:4326"), to_crs = sf::st_crs("EPSG:4326"), border_args = list()) {
    # Input validation
    if (!is.list(specs) || length(specs) == 0) {
        stop("specs must be a non-empty list of plot_spec objects")
    }
    if (full_ratio <= 0) {
        stop("full_ratio must be positive")
    }

    # Check that exactly one spec has main = TRUE
    main_count <- sum(sapply(specs, function(x) x$main))
    if (main_count == 0) {
        stop("Exactly one plot specification must have main = TRUE")
    } else if (main_count > 1) {
        stop("Only one plot specification can have main = TRUE")
    }

    cfg <- structure(
        list(
            specs = specs,
            full_ratio = full_ratio,
            from_crs = from_crs,
            to_crs = to_crs,
            border_args = utils::modifyList(
                list(
                    color = "black",
                    linewidth = 1
                ),
                border_args
            )
        ),
        class = "insetcfg"
    )
    set_last_insetcfg(cfg)
    invisible(cfg)
}

.insetcfg_store <- function() {
    .last_insetcfg <- NULL

    list(
        get = function() {
            return(.last_insetcfg)
        },
        set = function(insetcfg) {
            if (inherits(insetcfg, "insetcfg")) {
                .last_insetcfg <<- insetcfg
            } else {
                stop("Inset configuration must be of class 'insetcfg'.")
            }
        }
    )
}

.cfg_store <- .insetcfg_store()

#' Set Last Inset Configuration
#'
#' Stores an inset configuration object for later use with [with_inset()].
#' This is typically called internally by [config_insetmap()].
#'
#' @param insetcfg An inset configuration object of class "insetcfg".
#'
#' @return NULL (called for side effects).
#' @keywords internal
set_last_insetcfg <- function(insetcfg) .cfg_store$set(insetcfg)

#' Get Last Inset Configuration
#'
#' Retrieves the most recently stored inset configuration object.
#' This is used internally by [with_inset()] when no configuration is explicitly provided.
#'
#' @return An inset configuration object of class "insetcfg", or NULL if no
#'   configuration has been set.
#'
#' @examples
#' library(sf)
#'
#' # Load some spatial data
#' world_data <- sf::st_read(system.file("shape/nc.shp", package = "sf"))
#'
#' # Configure inset map
#' config_insetmap(
#'     plot_data = world_data,
#'     specs = list(
#'         plot_spec(main = TRUE),
#'         plot_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc_left = 0.02, loc_bottom = 0.7,
#'             width = 0.3
#'         )
#'     )
#' )
#'
#' # Retrieve the configuration
#' cfg <- last_insetcfg()
#'
#' @export
last_insetcfg <- function() .cfg_store$get()
