#' Create a plot specification for insets
#'
#' Define the spatial extent and positioning for each subplot (main or inset).
#'
#' @param xmin,xmax,ymin,ymax Numeric bbox coordinates for the subplot in the
#'   coordinate system of the data, normally longitude/latitude. Any may
#'   be NA and will be inferred from the overall extent if possible.
#' @param loc A convenience string like "left bottom", "center top", etc. to specify
#'  the position of the inset on the full canvas. Horizontal position must be one of
#'  "left", "center", or "right"; vertical position must be one of "bottom", "center", or "top".
#'  Ignored when `loc_left` and `loc_bottom` are provided.
#' @param loc_left,loc_bottom Numbers in \[0, 1\] for the bottom-left position of
#'   the inset on the full canvas.
#' @param width,height Numeric values in (0, 1\] for the size of the inset.
#'   It is recommended to provide only one of these; the other dimension will be
#'   inferred to maintain the aspect ratio of the spatial extent. It is also
#'   recommended to use `scale_factor` to automatically size the inset relative to
#'   the main plot instead of specifying width/height directly.
#' @param scale_factor Numeric value in (0, Inf) indicating the scale of the inset
#'   relative to the main plot. If not NA, the inset's width/height are
#'   automatically derived from the spatial ranges relative to the main plot
#'   multiplied by this factor. For example, the scale of the main plot is 1:10,000,
#'   the inset's dimensions will be 1:20,000 if `scale_factor` is 0.5.
#' @param main Logical. TRUE marks this spec as the main plot (exactly one).
#'   Default FALSE.
#' @param plot Optional ggplot object to use for this spec instead of the base
#'   plot passed to [with_inset()].
#'
#' @return A list with elements `bbox`, `loc_left`, `loc_bottom`, `width`,
#'   `height`, `scale_factor`, `main`, `plot`, `hpos`, and `vpos`. You do not
#'  normally need to interact with this object directly; it is used internally.
#'
#' @examples
#' specs <- list(
#'     # Create a main plot specification
#'     inset_spec(main = TRUE),
#'     # Create an inset plot specification with explicit dimensions
#'     inset_spec(
#'         xmin = -120, xmax = -100, ymin = 30, ymax = 50,
#'         loc = "right bottom",
#'         width = 0.3
#'     ),
#'     # Create an inset with scale factor
#'     inset_spec(
#'         xmin = -120, xmax = -100, ymin = 30, ymax = 50,
#'         loc = "left bottom",
#'         scale_factor = 0.5
#'     )
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
            warning("When scale_factor is specified, the width and height are directly determined by the main plot, and therefore the width and height will be ignored.")
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
#' configuration contains subplot specifications, aspect ratio of the main plot,
#' CRS settings, and border appearance for insets.
#'
#' @param data_list A list of spatial data objects (sf class). These data are used to compute the overall
#'   bounding box and coordinate systems for the insets.
#' @param specs A non-empty list of [inset_spec()] objects.
#' @param crs Coordinate reference system to transform to, passed to
#'   [ggplot2::coord_sf()] as `crs`. Default `"EPSG:4326"`.
#' @param border_args A list of named arguments passed to [map_border()] to style the
#'   borders around inset plots. See [map_border()] for details
#'   (defaults: `color = "black"`, `linewidth = 1`).
#'
#' @return An object of class `insetcfg`. Also stored as the last configuration, retrievable via [last_insetcfg()].
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
#'             loc = "left bottom", scale_factor = 0.5
#'         )
#'     )
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
            main_ratio <- get_bbox_features(data_bbox)$xy_ratio
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

set_last_insetcfg <- function(insetcfg) .cfg_store$set(insetcfg)

#' Get Last Inset Configuration
#'
#' Retrieves the most recently created inset configuration object.
#' This is used internally by [with_inset()] when no configuration is explicitly provided.
#'
#' @return An inset configuration object of class `insetcfg`, or NULL if no
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
