#' Create a plot specification for insets
#'
#' Define the spatial extent and positioning for each subplot (main or inset).
#'
#' @param xmin,xmax,ymin,ymax Numeric bbox coordinates for the subplot. Any may
#'   be NA and will be inferred from the overall extent if possible.
#' @param loc A convenience string like "left bottom", "center top", or
#'   "right center". When supplied, it overrides `loc_left`/`loc_bottom` with
#'   predefined anchor positions close to the plot edges (with small margins).
#'   Default "right bottom".
#' @param loc_left,loc_bottom Numbers in \[0, 1\] for the bottom-left position of
#'   the inset on the full canvas. Ignored when `main = TRUE`.
#' @param width,height Optional size of the inset as a fraction of canvas width/
#'   height. Supplying both is allowed but not recommended; aspect ratio will be
#'   prioritized. If both are NA and `scale_factor` is NA, `scale_factor` is
#'   set to 1.0 with a warning.
#' @param scale_factor Numeric. If not NA, the inset's width/height are
#'   automatically derived from the spatial ranges relative to the main plot
#'   multiplied by this factor. When specified, `width` and `height` are ignored.
#'   See [with_inset()] for details.
#' @param main Logical. TRUE marks this spec as the main plot (exactly one).
#'   Default FALSE.
#' @param plot Optional ggplot object to use for this spec instead of the base
#'   plot passed to [with_inset()].
#'
#' @return A list with elements `bbox`, `loc_left`, `loc_bottom`, `width`,
#'   `height`, `scale_factor`, `main`, `plot`, `hpos`, and `vpos`.
#'
#' @examples
#' # Create a main plot specification
#' main_spec <- inset_spec(main = TRUE)
#'
#' # Create an inset plot specification with explicit dimensions
#' inset_spec_dim <- inset_spec(
#'     xmin = -120, xmax = -100, ymin = 30, ymax = 50,
#'     loc = "right bottom",
#'     width = 0.3
#' )
#'
#' # Create an inset with scale factor
#' inset_spec_scaled <- inset_spec(
#'     xmin = -120, xmax = -100, ymin = 30, ymax = 50,
#'     loc = "left bottom",
#'     scale_factor = 0.5
#' )
#'
#' @export
inset_spec <- function(
    xmin = NA, xmax = NA, ymin = NA, ymax = NA,
    loc = "right bottom", loc_left = NA, loc_bottom = NA, width = NA, height = NA,
    scale_factor = NA, main = FALSE, plot = NULL) {
    # Input validation
    if (!is.na(xmin) && !is.na(xmax) && xmin >= xmax) {
        stop("xmin must be less than xmax")
    }
    if (!is.na(ymin) && !is.na(ymax) && ymin >= ymax) {
        stop("ymin must be less than ymax")
    }
    hpos <- NULL
    vpos <- NULL

    if (!main) {
        # Only check location and size if not the main plot
        if (loc != "") {
            # we only check the validity here; actual loc_left and loc_bottom will be set when placing the inset
            loc <- tolower(loc)
            locs <- strsplit(loc, " ")[[1]]
            hpos <- locs[1]
            vpos <- locs[2]
            stopifnot(hpos %in% c("left", "center", "right"))
            stopifnot(vpos %in% c("bottom", "center", "top"))
        } else {
            stopifnot(!is.na(loc_left), !is.na(loc_bottom))
            if (loc_left < 0 || loc_left > 1 || loc_bottom < 0 || loc_bottom > 1) {
                stop("loc_left and loc_bottom must be between 0 and 1")
            }
        }

        if (!is.na(width) && (width <= 0 || width > 1)) {
            stop("width must be between 0 and 1")
        }
        if (!is.na(height) && (height <= 0 || height > 1)) {
            stop("height must be between 0 and 1")
        }

        if (!is.na(width) && !is.na(height)) {
            warning("Providing both width and height is not recommended.")
        }
        if (!is.na(scale_factor) && (!is.na(width) || !is.na(height))) {
            cat("When scale_factor is specified, the width and height are directly determined by the main plot, and therefore the width and height will be ignored.")
        }
        if (is.na(width) && is.na(height) && is.na(scale_factor)) {
            scale_factor <- 1.0
            warning("Both width and height are NULL. Setting scale_factor to 1.0 to determine width and height based on the main plot.")
        }
    }
    return(
        list(
            bbox = c(ymin = ymin, xmin = xmin, xmax = xmax, ymax = ymax),
            loc_left = loc_left,
            loc_bottom = loc_bottom,
            width = width,
            height = height,
            scale_factor = scale_factor,
            main = main,
            plot = plot,
            hpos = hpos,
            vpos = vpos
        )
    )
}

#' Configure inset map settings
#'
#' Create and store an inset configuration used by [with_inset()]. The
#' configuration contains subplot specifications, aspect ratio of the full
#' canvas, CRS settings, and border appearance for insets.
#'
#' @param data_list A list of spatial data objects (sf class). All elements
#'   must inherit from 'sf'. These data are used to compute the overall
#'   bounding box and coordinate systems for the insets.
#' @param specs A non-empty list of [inset_spec()] objects.
#' @param full_ratio Numeric width-to-height ratio of the full canvas. For best
#'   results, save figures with this ratio. Default 1.
#' @param crs Coordinate reference system to transform to, passed to
#'   [ggplot2::coord_sf()] as `crs`. The CRS of the first sf object in
#'   `data_list` is used as `default_crs` (from_crs). Default EPSG:4326.
#' @param border_args A list merged into defaults for [map_border()] arguments
#'   (defaults: `color = "black"`, `linewidth = 1`).
#'
#' @return Invisibly, an object of class "insetcfg" with fields: `data_list`,
#'   `specs`, `main_idx`, `full_ratio`, `from_crs`, `to_crs`, and `border_args`.
#'   It is also stored as the last configuration, retrievable via [last_insetcfg()].
#'
#' @details
#' Each spec in `specs` must have its bbox filled in (missing NA values are
#' replaced with the overall extent). The `data_bbox` for each spec is computed
#' by cropping the data in `data_list` to the spec's bbox and transforming to
#' the target CRS.
#'
#' @examples
#' library(sf)
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
#' @seealso [inset_spec()], [with_inset()], [last_insetcfg()]
#' @export
config_insetmap <- function(data_list, specs, crs = sf::st_crs("EPSG:4326"), border_args = list()) {
    # Input validation
    if (missing(data_list) || length(data_list) == 0 || !all(sapply(data_list, function(x) inherits(x, "sf")))) {
        stop("data_list must be provided, and all elements must be of class 'sf'")
    }
    if (!is.list(specs) || length(specs) == 0) {
        stop("specs must be a non-empty list of inset_spec objects")
    }

    # Check that exactly one spec has main = TRUE
    main_count <- sum(sapply(specs, function(x) x$main))
    if (main_count == 0) {
        stop("Exactly one plot specification must have main = TRUE")
    } else if (main_count > 1) {
        stop("Only one plot specification can have main = TRUE")
    }

    from_crs <- st_crs(data_list[[1]])
    widest_bbox <- get_widest_bbox(data_list)
    main_ratio <- get_bbox_features(widest_bbox)$xy_ratio
    main_idx <- NULL
    for (i in seq_along(specs)) {
        spec <- specs[[i]]
        # Fill missing bbox values
        full_bbox <- .fill_bbox(spec$bbox, widest_bbox)
        data_bbox <- get_widest_bbox(lapply(data_list, function(data) st_transform(suppressWarnings(st_crop(data, full_bbox)), crs)))
        spec$data_bbox <- data_bbox
        spec$bbox <- full_bbox
        specs[[i]] <- spec

        if (spec$main) {
            main_idx <- i
        }
    }

    cfg <- structure(
        list(
            data_list = data_list,
            specs = specs,
            main_idx = main_idx,
            from_crs = from_crs,
            to_crs = crs,
            main_ratio = main_ratio,
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
#' Stores an inset configuration object in a private environment for later retrieval.
#' This function is typically called internally by [config_insetmap()] and is rarely
#' used directly by end users.
#'
#' @param insetcfg An inset configuration object of class "insetcfg", typically
#'   created by [config_insetmap()].
#'
#' @return NULL (invisibly). The function is called for its side effect of
#'   storing the configuration.
#'
#' @details
#' The stored configuration can later be retrieved using [last_insetcfg()].
#' This mechanism allows [with_inset()] to work without explicitly passing
#' the configuration if [config_insetmap()] has been called previously.
#'
#' @keywords internal
#' @seealso [last_insetcfg()], [config_insetmap()]
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
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#'
#' # Configure inset map
#' config_insetmap(
#'     data_list = list(nc),
#'     specs = list(
#'         inset_spec(main = TRUE),
#'         inset_spec(
#'             xmin = -84, xmax = -75, ymin = 33, ymax = 37,
#'             loc = "left bottom",
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
