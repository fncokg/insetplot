# Test suite for with_inset function

# Load libraries once with warnings suppressed
suppressPackageStartupMessages({
    library(sf)
    library(ggplot2)
})

# Helper function: Create sample data and base plot
setup_base_plot <- function() {
    nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
    base_plot <- ggplot(nc, aes(fill = AREA)) +
        geom_sf() +
        theme_void()
    return(base_plot)
}

# Helper function: Configure inset map with default settings
setup_inset_config <- function(specs_list = NULL) {
    if (is.null(specs_list)) {
        specs_list <- list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = -84, xmax = -75, ymin = 33, ymax = 37,
                loc = "left bottom", width = 0.3
            )
        )
    }
    config_insetmap(
        specs = specs_list,
        full_ratio = 16 / 9
    )
}

test_that("with_inset returns plot unchanged when .as_is = TRUE", {
    base_plot <- setup_base_plot()
    setup_inset_config()

    # Test .as_is = TRUE returns the input plot unchanged
    result <- with_inset(base_plot, .as_is = TRUE)

    expect_identical(result, base_plot)
    expect_is(result, "ggplot")
})

test_that("with_inset throws error when no configuration is available", {
    # Create a dummy plot
    dummy_plot <- ggplot() +
        geom_point(aes(x = 1, y = 1))

    # Test the error message by providing NULL config directly
    expect_error(
        with_inset(dummy_plot, .cfg = NULL),
        "No inset configuration found. Please run config_insetmap\\(\\) first."
    )
})

test_that("with_inset produces valid output with valid configuration", {
    base_plot <- setup_base_plot()
    setup_inset_config()

    # Test that with_inset returns a ggplot object
    result <- with_inset(base_plot)

    expect_is(result, "ggplot")
})
