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
    return(nc) # Return the spatial data
}

# Helper function: Create base ggplot from data
create_base_ggplot <- function(data = NULL) {
    if (is.null(data)) {
        data <- setup_base_plot()
    }
    ggplot(data, aes(fill = AREA)) +
        geom_sf() +
        theme_void()
}

# Helper function: Configure inset map with default settings
setup_inset_config <- function(specs_list = NULL, data_list = NULL) {
    if (is.null(data_list)) {
        data_list <- list(setup_base_plot())
    }
    if (is.null(specs_list)) {
        specs_list <- list(
            inset_spec(main = TRUE),
            inset_spec(
                xmin = -84, xmax = -75, ymin = 33, ymax = 37,
                loc = "left bottom", width = 0.3
            )
        )
    }
    config_insetmap(
        data_list = data_list,
        specs = specs_list,
        full_ratio = 16 / 9
    )
}

test_that("with_inset returns plot unchanged when .as_is = TRUE", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    # Test .as_is = TRUE returns the input plot unchanged
    # Note: plot parameter is now optional, but required when .as_is = TRUE
    result <- with_inset(plot = base_plot, .as_is = TRUE)

    expect_identical(result, base_plot)
    expect_is(result, "ggplot")
})

test_that("with_inset throws error when no configuration is available", {
    # Create a dummy plot
    dummy_plot <- ggplot() +
        geom_point(aes(x = 1, y = 1))

    # Test the error message by providing NULL config directly
    # Note: plot parameter can be NULL or provided
    expect_error(
        with_inset(plot = dummy_plot, .cfg = NULL),
        "No inset configuration found. Please run config_insetmap\\(\\) first."
    )
})

test_that("with_inset produces valid output with valid configuration", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    # Test that with_inset returns a ggplot object
    # plot parameter can be provided as a default for all subplots
    result <- with_inset(plot = base_plot)

    expect_is(result, "ggplot")
})

test_that("with_inset works when all subplots have custom plots in specs", {
    data <- setup_base_plot()

    # Create different plots for main and inset
    main_plot <- create_base_ggplot(data) +
        ggtitle("Main Map")

    inset_plot <- create_base_ggplot(data) +
        ggtitle("Inset Detail")

    # Configure insets with custom plots in each spec
    specs_with_custom_plots <- list(
        inset_spec(main = TRUE, plot = main_plot),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", width = 0.3,
            plot = inset_plot
        )
    )

    setup_inset_config(specs_list = specs_with_custom_plots, data_list = list(data))

    # Test that with_inset works when called without plot parameter
    # (each spec has its own plot defined, so plot is optional)
    result <- with_inset()

    expect_is(result, "ggplot")
})

test_that("with_inset plot parameter is truly optional when all specs have plots", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)

    # Configure insets with custom plots in each spec
    specs_with_custom_plots <- list(
        inset_spec(main = TRUE, plot = base_plot),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", width = 0.3,
            plot = base_plot
        )
    )

    setup_inset_config(specs_list = specs_with_custom_plots, data_list = list(data))

    # Call with_inset without any plot parameter
    result <- with_inset()
    expect_is(result, "ggplot")

    # Call with_inset with plot parameter (should use spec plots anyway)
    result_with_plot <- with_inset(plot = create_base_ggplot(data))
    expect_is(result_with_plot, "ggplot")
})

test_that("with_inset returns correct structure when .return_details = TRUE", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    # Test that .return_details = TRUE returns a list with expected elements
    result <- with_inset(plot = base_plot, .return_details = TRUE)

    expect_is(result, "list")
    expect_true("full" %in% names(result))
    expect_true("subplots" %in% names(result))
    expect_true("subplot_layouts" %in% names(result))
    expect_true("main_ratio" %in% names(result))

    expect_is(result$full, "ggplot")
    expect_is(result$subplots, "list")
    expect_is(result$main_ratio, "numeric")
})
