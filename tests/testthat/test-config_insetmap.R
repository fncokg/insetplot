# Test suite for config_insetmap function

test_that("config_insetmap creates valid configuration with standard specs", {
    data <- setup_base_plot()
    specs <- create_standard_specs()

    cfg <- config_insetmap(bbox = sf::st_bbox(data), specs = specs)

    expect_is(cfg, "insetcfg")
    expect_equal(cfg$main_idx, 1)
    expect_equal(length(cfg$specs), 2)
    expect_true("main_ratio" %in% names(cfg))
    expect_true("from_crs" %in% names(cfg))
    expect_true("to_crs" %in% names(cfg))
    expect_true("border_args" %in% names(cfg))
})

test_that("config_insetmap requires exactly one main spec", {
    data <- setup_base_plot()

    # Test no main spec
    expect_error(
        config_insetmap(
            bbox = sf::st_bbox(data),
            specs = list(inset_spec(main = FALSE, loc = "left bottom", width = 0.3))
        ),
        "Exactly one plot specification must have main = TRUE"
    )

    # Test multiple main specs
    expect_error(
        config_insetmap(
            bbox = sf::st_bbox(data),
            specs = list(inset_spec(main = TRUE), inset_spec(main = TRUE))
        ),
        "Only one plot specification can have main = TRUE"
    )
})
