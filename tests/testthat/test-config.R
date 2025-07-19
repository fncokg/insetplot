test_that("config_insetmap validates inputs correctly", {
    skip_if_not_installed("sf")

    # Mock data
    mock_data <- data.frame(x = 1:10, y = 1:10)
    valid_specs <- list(plot_spec(main = TRUE), plot_spec(width = 0.3))

    # Empty specs
    expect_error(config_insetmap(mock_data, specs = list()), "specs must be a non-empty list")

    # Invalid full_ratio
    expect_error(
        config_insetmap(mock_data, specs = valid_specs, full_ratio = 0),
        "full_ratio must be positive"
    )

    # No main plot
    no_main_specs <- list(plot_spec(), plot_spec())
    expect_error(
        config_insetmap(mock_data, specs = no_main_specs),
        "Exactly one plot specification must have main = TRUE"
    )

    # Multiple main plots
    multi_main_specs <- list(plot_spec(main = TRUE), plot_spec(main = TRUE))
    expect_error(
        config_insetmap(mock_data, specs = multi_main_specs),
        "Only one plot specification can have main = TRUE"
    )
})

test_that("config_insetmap stores configuration correctly", {
    skip_if_not_installed("sf")

    mock_data <- data.frame(x = 1:10, y = 1:10)
    specs <- list(plot_spec(main = TRUE), plot_spec(width = 0.3))

    # Should return configuration invisibly
    cfg <- config_insetmap(mock_data, specs = specs)
    expect_s3_class(cfg, "insetcfg")

    # Should store as last configuration
    expect_identical(cfg, last_insetcfg())
})

test_that("plot_spec validates inputs correctly", {
    # Valid inputs should work
    expect_no_error(plot_spec(main = TRUE))
    expect_no_error(plot_spec(xmin = -10, xmax = 10, ymin = -5, ymax = 5))

    # Invalid bounding box
    expect_error(plot_spec(xmin = 10, xmax = -10), "xmin must be less than xmax")
    expect_error(plot_spec(ymin = 5, ymax = -5), "ymin must be less than ymax")

    # Invalid positions
    expect_error(plot_spec(loc_left = -0.1), "loc_left and loc_bottom must be between 0 and 1")
    expect_error(plot_spec(loc_bottom = 1.1), "loc_left and loc_bottom must be between 0 and 1")

    # Invalid dimensions
    expect_error(plot_spec(width = 0), "width must be between 0 and 1")
    expect_error(plot_spec(height = 1.5), "height must be between 0 and 1")
})
