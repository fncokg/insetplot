# Test suite for with_inset function

test_that("with_inset returns plot unchanged when .as_is = TRUE", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    result <- with_inset(plot = base_plot, .as_is = TRUE)

    expect_identical(result, base_plot)
    expect_is(result, "ggplot")
})

test_that("with_inset throws error when no configuration available", {
    dummy_plot <- ggplot() +
        geom_point(aes(x = 1, y = 1))
    expect_error(
        with_inset(plot = dummy_plot, .cfg = NULL),
        "No inset configuration found"
    )
})

test_that("with_inset produces valid output with configuration and plot parameter", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    result <- with_inset(plot = base_plot)
    expect_is(result, "ggplot")
})

test_that("with_inset handles spec-defined plots correctly", {
    data <- setup_base_plot()
    plots <- setup_spec_plots(data)

    specs <- list(
        inset_spec(main = TRUE, plot = plots$main_plot),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", width = 0.3,
            plot = plots$inset_plot
        )
    )

    setup_inset_config(specs_list = specs, data_list = list(data))

    # Test with_inset works without plot parameter when specs have plots
    result1 <- with_inset()
    expect_is(result1, "ggplot")

    # Test with_inset works with plot parameter (spec plots take precedence)
    result2 <- with_inset(plot = create_base_ggplot(data))
    expect_is(result2, "ggplot")
})

test_that("with_inset returns correct structure with .return_details = TRUE", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    setup_inset_config(data_list = list(data))

    result <- with_inset(plot = base_plot, .return_details = TRUE)

    expect_is(result, "list")
    expect_true(all(c("full", "subplots", "subplot_layouts", "main_ratio") %in% names(result)))
    expect_is(result$full, "ggplot")
    expect_is(result$subplots, "list")
    expect_is(result$main_ratio, "numeric")
    expect_true(all(sapply(result$subplots, function(x) inherits(x, "ggplot"))))
})

test_that("with_inset handles plot as list of ggplot objects", {
    data <- setup_base_plot()
    plots <- setup_spec_plots(data)
    specs <- create_standard_specs()

    setup_inset_config(specs_list = specs, data_list = list(data))

    # Test passing plot as a list
    plot_list <- list(plots$main_plot, plots$inset_plot)
    result <- with_inset(plot = plot_list)
    expect_is(result, "ggplot")
})

test_that("with_inset validates plot list length and elements", {
    data <- setup_base_plot()
    base_plot <- create_base_ggplot(data)
    specs <- create_standard_specs()

    setup_inset_config(specs_list = specs, data_list = list(data))

    # Wrong length list
    expect_error(
        with_inset(plot = list(base_plot)),
        "is not TRUE"
    )

    # NULL elements in list
    expect_error(
        with_inset(plot = list(base_plot, NULL)),
        "is not TRUE"
    )
})

test_that("with_inset spec plots take precedence over list plots", {
    data <- setup_base_plot()
    plots <- setup_spec_plots(data)

    specs <- list(
        inset_spec(main = TRUE, plot = plots$main_plot),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", width = 0.3,
            plot = plots$inset_plot
        )
    )

    setup_inset_config(specs_list = specs, data_list = list(data))

    # Pass different plots as list - spec plots should be used
    other_plots <- list(create_base_ggplot(data), create_base_ggplot(data))
    result <- with_inset(plot = other_plots)
    expect_is(result, "ggplot")
})
