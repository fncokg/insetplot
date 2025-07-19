#' insetplot: Create Inset Plots with Minimal Code Changes from ggplot2
#'
#' The insetplot package provides tools for creating inset plots and maps with
#' minimal modifications to existing ggplot2 code. Simply wrap your existing
#' plotting code - no need to rewrite plotting logic or learn new functions.
#' Create combined visualizations with main plots and inset plots at specified
#' locations and sizes.
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{config_insetmap}}: Configure inset map settings
#'   \item \code{\link{plot_spec}}: Define plot specifications
#'   \item \code{\link{with_inset}}: Create combined plots with insets (keeps your plotting code unchanged)
#' }
#'
#' @section Additional functions (not required for basic usage):
#' \itemize{
#'   \item \code{\link{gg2inset}}: Convert ggplots to insets
#'   \item \code{\link{map_border}}: Add borders to map plots
#' }
#'
#' @section Key features:
#' \itemize{
#'   \item Minimal migration from ggplot2 - just wrap existing code
#'   \item Automatically handles aspect ratios and positioning
#'   \item Automatically handles data cropping and multiple subplots
#' }
#'
#' @name insetplot-package
#' @aliases insetplot
#' @import ggplot2
#' @import sf
#' @import cowplot
#' @import rlang
"_PACKAGE"
