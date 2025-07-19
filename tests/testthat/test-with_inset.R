test_that("with_inset basic functionality works", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")

    # Create mock spatial data
    coords <- matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        area = 1,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure inset map
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0.2, xmax = 0.8, ymin = 0.2, ymax = 0.8,
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.3
            )
        )
    )

    # Test basic plot creation
    result <- with_inset({
        ggplot2::ggplot(mock_sf) +
            ggplot2::geom_sf() +
            ggplot2::theme_void()
    })

    # cowplot::ggdraw returns an object that inherits from ggplot
    # but is more specifically a cowplot drawing canvas
    expect_s3_class(result, "ggplot")
    # Should also inherit from gg (which is the base class for ggplot objects)
    expect_s3_class(result, "gg")
})

test_that("with_inset .as_is parameter works", {
    skip_if_not_installed("ggplot2")

    # Create a simple plot expression
    plot_expr <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
        ggplot2::geom_point()

    # Test .as_is = TRUE returns the expression unchanged
    result <- with_inset(plot_expr, .as_is = TRUE)
    expect_s3_class(result, "ggplot")
})

test_that("with_inset .return_subplots parameter works", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")

    # Create mock spatial data
    coords <- matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        area = 1,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure inset map
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0.2, xmax = 0.8, ymin = 0.2, ymax = 0.8,
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.3
            )
        )
    )

    # Test .return_subplots = TRUE
    result <- with_inset(
        {
            ggplot2::ggplot(mock_sf) +
                ggplot2::geom_sf() +
                ggplot2::theme_void()
        },
        .return_subplots = TRUE
    )

    expect_type(result, "list")
    expect_named(result, c("full", "subplots"))
    # result$full is a cowplot drawing canvas, which inherits from ggplot
    expect_s3_class(result$full, "ggplot")
    expect_type(result$subplots, "list")
    expect_length(result$subplots, 2) # main + 1 inset
})

test_that("with_inset handles missing configuration", {
    # Should error when no configuration is available
    expect_error(
        with_inset(
            {
                ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
                    ggplot2::geom_point()
            },
            .cfg = NULL
        ),
        "No inset configuration found"
    )
})

test_that("with_inset handles invalid configuration", {
    skip_if_not_installed("sf")

    # Create invalid configuration (no main plot)
    mock_sf <- sf::st_sf(
        id = 1,
        geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 4326)
    )

    # This should fail during configuration, but let's test if somehow we get here
    expect_error(
        {
            config_insetmap(
                plot_data = c(mock_sf),
                specs = list(
                    plot_spec(width = 0.3), # No main = TRUE
                    plot_spec(width = 0.3)
                )
            )
        },
        "Exactly one plot specification must have main = TRUE"
    )
})

test_that("with_inset handles no_scale option correctly", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")

    # Create mock spatial data with different extents
    coords1 <- matrix(c(0, 0, 2, 0, 2, 2, 0, 2, 0, 0), ncol = 2, byrow = TRUE)
    poly1 <- sf::st_polygon(list(coords1))
    mock_sf <- sf::st_sf(
        id = 1,
        area = 4,
        geometry = sf::st_sfc(poly1, crs = 4326)
    )

    # Configure with no_scale = TRUE
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0.5, xmax = 1.5, ymin = 0.5, ymax = 1.5,
                loc_left = 0.7, loc_bottom = 0.7,
                no_scale = TRUE
            )
        )
    )

    # Should not error
    expect_no_error({
        result <- with_inset({
            ggplot2::ggplot(mock_sf) +
                ggplot2::geom_sf() +
                ggplot2::theme_void()
        })
    })
})

test_that("with_inset handles multiple insets", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")

    # Create larger mock spatial data
    coords <- matrix(c(0, 0, 4, 0, 4, 4, 0, 4, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        area = 16,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure with multiple insets
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0, xmax = 2, ymin = 0, ymax = 2,
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.25
            ),
            plot_spec(
                xmin = 2, xmax = 4, ymin = 2, ymax = 4,
                loc_left = 0.02, loc_bottom = 0.7,
                width = 0.25
            )
        )
    )

    # Test with multiple insets
    result <- with_inset(
        {
            ggplot2::ggplot(mock_sf) +
                ggplot2::geom_sf() +
                ggplot2::theme_void()
        },
        .return_subplots = TRUE
    )

    expect_type(result, "list")
    expect_length(result$subplots, 3) # main + 2 insets
})

test_that("with_inset expression evaluation works correctly", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")

    # Create mock spatial data with an attribute for mapping
    coords <- matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        value = 100,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure inset map
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0.2, xmax = 0.8, ymin = 0.2, ymax = 0.8,
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.3
            )
        )
    )

    # Test that the spatial data is available in the expression environment
    expect_no_error({
        result <- with_inset({
            ggplot2::ggplot(mock_sf) +
                ggplot2::geom_sf(ggplot2::aes(fill = value)) +
                ggplot2::theme_void()
        })
    })
})

test_that("with_inset handles border arguments correctly", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")

    # Create mock spatial data
    coords <- matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure with custom border arguments
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 0.2, xmax = 0.8, ymin = 0.2, ymax = 0.8,
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.3
            )
        ),
        border_args = list(color = "red", linewidth = 2)
    )

    # Should handle custom border arguments without error
    expect_no_error({
        result <- with_inset({
            ggplot2::ggplot(mock_sf) +
                ggplot2::geom_sf() +
                ggplot2::theme_void()
        })
    })
})

test_that("with_inset handles empty cropped data gracefully", {
    skip_if_not_installed("sf")
    skip_if_not_installed("ggplot2")

    # Create mock spatial data in a small area
    coords <- matrix(c(0, 0, 0.1, 0, 0.1, 0.1, 0, 0.1, 0, 0), ncol = 2, byrow = TRUE)
    poly <- sf::st_polygon(list(coords))
    mock_sf <- sf::st_sf(
        id = 1,
        geometry = sf::st_sfc(poly, crs = 4326)
    )

    # Configure with inset that doesn't intersect the data
    config_insetmap(
        plot_data = mock_sf,
        specs = list(
            plot_spec(main = TRUE),
            plot_spec(
                xmin = 5, xmax = 6, ymin = 5, ymax = 6, # Far from the data
                loc_left = 0.7, loc_bottom = 0.7,
                width = 0.3
            )
        )
    )

    # Should handle empty cropped data (might produce warning but shouldn't error)
    expect_no_error({
        suppressWarnings({
            result <- with_inset({
                ggplot2::ggplot(mock_sf) +
                    ggplot2::geom_sf() +
                    ggplot2::theme_void()
            })
        })
    })
})
