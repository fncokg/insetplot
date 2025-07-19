test_that("gg2inset creates valid inset objects", {
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")
    skip_if_not_installed("sf")

    # Create a simple ggplot
    simple_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
        ggplot2::geom_point()

    # Test basic gg2inset functionality
    inset <- gg2inset(
        inset_map = simple_plot,
        crs = sf::st_crs(4326),
        x = 0.7, y = 0.7,
        inset_width = 0.3, inset_height = 0.3
    )

    expect_s3_class(inset, "gg")
})

test_that("gg2inset handles missing dimensions correctly", {
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("cowplot")
    skip_if_not_installed("sf")

    # Create a simple ggplot
    simple_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
        ggplot2::geom_point()

    # Test with missing width and height (should warn and default)
    expect_warning(
        gg2inset(
            inset_map = simple_plot,
            crs = sf::st_crs(4326),
            x = 0.7, y = 0.7
        ),
        "Both inset_height and inset_width are NULL"
    )

    # Test with only width provided
    expect_no_error(
        gg2inset(
            inset_map = simple_plot,
            crs = sf::st_crs(4326),
            x = 0.7, y = 0.7,
            inset_width = 0.3
        )
    )

    # Test with only height provided
    expect_no_error(
        gg2inset(
            inset_map = simple_plot,
            crs = sf::st_crs(4326),
            x = 0.7, y = 0.7,
            inset_height = 0.3
        )
    )
})

test_that("map_border creates valid theme elements", {
    skip_if_not_installed("ggplot2")

    # Test default border
    border_theme <- map_border()
    expect_s3_class(border_theme, "theme")

    # Test custom border
    custom_border <- map_border(color = "red", linewidth = 2, fill = "blue")
    expect_s3_class(custom_border, "theme")

    # Test that it can be added to a plot
    expect_no_error({
        p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
            ggplot2::geom_point() +
            map_border()
    })
})

test_that("get_map_range calculates ranges correctly", {
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("sf")

    # Create a simple plot with known ranges
    p <- ggplot2::ggplot(data.frame(x = c(0, 10), y = c(0, 5)), ggplot2::aes(x, y)) +
        ggplot2::geom_point() +
        ggplot2::coord_cartesian(xlim = c(0, 10), ylim = c(0, 5))

    # Test with geographic CRS
    range_result <- get_map_range(p, sf::st_crs(4326))

    expect_type(range_result, "list")
    expect_named(range_result, c("xrange", "yrange", "aspect_ratio"))
    expect_true(is.numeric(range_result$xrange))
    expect_true(is.numeric(range_result$yrange))
    expect_true(is.numeric(range_result$aspect_ratio))
})

test_that("get_map_aspect_ratio returns correct type", {
    skip_if_not_installed("ggplot2")
    skip_if_not_installed("sf")

    # Create a simple plot
    p <- ggplot2::ggplot(data.frame(x = c(0, 10), y = c(0, 5)), ggplot2::aes(x, y)) +
        ggplot2::geom_point()

    # Test aspect ratio calculation
    aspect_ratio <- get_map_aspect_ratio(p, sf::st_crs(4326))

    expect_type(aspect_ratio, "double")
    expect_length(aspect_ratio, 1)
    expect_true(is.finite(aspect_ratio))
    expect_true(aspect_ratio > 0)
})
