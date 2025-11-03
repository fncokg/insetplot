# Helper functions for insetplot tests

suppressPackageStartupMessages({
    library(sf)
    library(ggplot2)
})

#' Create sample spatial data (NC from sf package)
setup_base_plot <- function() {
    nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
    return(nc)
}

#' Create a basic ggplot from spatial data
create_base_ggplot <- function(data = NULL) {
    if (is.null(data)) {
        data <- setup_base_plot()
    }
    ggplot(data, aes(fill = AREA)) +
        geom_sf() +
        theme_void()
}

#' Create a titled ggplot
create_titled_ggplot <- function(data = NULL, title = "Plot") {
    create_base_ggplot(data) + ggtitle(title)
}

#' Configure inset map with specifications
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
        specs = specs_list
    )
}

#' Standard two-plot setup (main + inset with titles)
setup_spec_plots <- function(data = NULL) {
    if (is.null(data)) {
        data <- setup_base_plot()
    }
    list(
        main_plot = create_titled_ggplot(data, "Main Map"),
        inset_plot = create_titled_ggplot(data, "Inset Detail")
    )
}

#' Standard two-spec setup
create_standard_specs <- function(...) {
    list(
        inset_spec(main = TRUE, ...),
        inset_spec(
            xmin = -84, xmax = -75, ymin = 33, ymax = 37,
            loc = "left bottom", width = 0.3
        )
    )
}
