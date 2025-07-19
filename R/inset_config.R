#' Create Plot Specification for Inset Maps
#'
#' Defines the spatial extent and positioning parameters for individual plots
#' in an inset map configuration.
#'
#' @param xmin,xmax,ymin,ymax Numeric values defining the bounding box coordinates
#'   for cropping the spatial data. If NULL, the full extent will be used.
#' @param loc_left,loc_bottom Numeric values between 0 and 1 specifying the
#'   position of the inset plot within the main plot area. Default is (0, 0).
#' @param width,height Numeric values specifying the width and height of the
#'   inset plot as proportions of the main plot. If both are provided, a warning
#'   is issued as aspect ratio maintenance is prioritized.
#' @param no_scale Logical. If TRUE, the inset size is determined automatically
#'   based on the spatial extent relative to the main plot. Default is FALSE.
#' @param main Logical. If TRUE, this specification defines the main plot.
#'   Only one specification should have main = TRUE. Default is FALSE.
#'
#' @return A list containing the plot specification parameters.
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
    xmin = NULL, xmax = NULL, ymin = NULL, ymax = NULL,
    loc_left = 0, loc_bottom = 0, width = NULL, height = NULL,
    no_scale = FALSE, main = FALSE) {
    # Input validation
    if (!is.null(xmin) && !is.null(xmax) && xmin >= xmax) {
        stop("xmin must be less than xmax")
    }
    if (!is.null(ymin) && !is.null(ymax) && ymin >= ymax) {
        stop("ymin must be less than ymax")
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
            warning("If no_scale is TRUE, the width and height are directly determined by the main plot, and therefore the width and height will be ignored.")
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
            main = main
        )
    )
}

#' Configure Inset Map Settings
#'
#' Sets up the configuration for creating inset maps with multiple plot
#' specifications. This function stores the configuration globally for use
#' with [with_inset()].
#'
#' @param plot_data A spatial data object, or multiple spatial data objects
#'   passed as arguments to `c()` (e.g., `c(data1, data2)`). These will be
#'   available for plotting in the inset map expressions using their original
#'   variable names. For a single dataset, can be passed directly without `c()`.
#' @param specs A list of plot specifications created with [plot_spec()].
#'   Each specification defines a subplot with its spatial extent and positioning.
#' @param full_ratio Numeric. The WIDTH-TO-HEIGHT aspect ratio of the full plot area. NOTE: You should save the plot with a width-height ratio that matches this value. Otherwise, the inset plots may not be displayed correctly. Default is 1.0.
#' @param crs A coordinate reference system specification. Default is
#'   EPSG:4326 (WGS84 geographic coordinates).
#' @param border_args A list of arguments passed to [map_border()] for styling
#'   inset plot borders. Default creates a black border with linewidth 1.
#'
#' @return Invisibly returns the inset configuration object of class "insetcfg".
#'   The configuration is also stored globally for use with [with_inset()].
#'
#' @examples
#' \dontrun{
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
#' }
#'
#' @seealso [plot_spec()], [with_inset()], [last_insetcfg()]
#' @export
#' @import rlang
config_insetmap <- function(plot_data, specs, full_ratio = 1.0, crs = sf::st_crs("EPSG:4326"), border_args = list()) {
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

    quos <- enquo(plot_data)
    expr <- get_expr(quos)
    data_env <- get_env(quos)
    if (!is_call(expr, "c")) {
        data_quos <- list(quos)
    } else {
        data_exprs <- expr[-1]
        data_quos <- lapply(data_exprs, function(x) new_quosure(x, data_env))
    }
    data_list <- lapply(data_quos, eval_tidy)
    names(data_list) <- lapply(data_quos, as_name)
    cfg <- structure(
        list(
            data = data_list,
            specs = specs,
            full_ratio = full_ratio,
            crs = crs,
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
#' \dontrun{
#' # After setting up a configuration
#' config_insetmap(some_data, specs = some_specs)
#'
#' # Retrieve the configuration
#' cfg <- last_insetcfg()
#' }
#'
#' @export
last_insetcfg <- function() .cfg_store$get()
