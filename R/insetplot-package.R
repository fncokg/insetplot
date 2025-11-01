#' insetplot: compose ggplot2 with insets
#'
#' Utilities to compose a base ggplot with one or more inset plots using simple
#' configuration. Keep your plotting code unchanged and specify insets with
#' bounding boxes and positions.
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{config_insetmap}}: Configure inset settings
#'   \item \code{\link{plot_spec}}: Define subplot specifications
#'   \item \code{\link{with_inset}}: Create combined plots with insets
#' }
#'
#' @section Additional functions (not required for basic usage):
#' \itemize{
#'   \item \code{\link{gg2inset}}: Convert ggplots to inset layers
#'   \item \code{\link{map_border}}: Add borders around inset plots
#' }
#'
#' @section Key features:
#' \itemize{
#'   \item Keep ggplot2 code intact, simply add configuration
#'   \item Handles aspect ratios, positions, and borders
#'   \item Works with multiple subplots
#' }
#'
#' @name insetplot-package
#' @aliases insetplot
#' @import ggplot2
#' @import sf
#' @import cowplot
#' @import rlang
"_PACKAGE"
