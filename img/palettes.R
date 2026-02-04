# ============================================================
# EmpericalPatternR Color Palette
# ------------------------------------------------------------
# Cohesive color system for:
#  - Forest ecology
#  - Fire and disturbance
#  - Data visualization
#  - Dark UI / pkgdown themes
#
# Author: Andrew J. Sanchez Meador
# Package: EmpericalPatternR
# ============================================================

# ---- Primary Brand Colors ----------------------------------

emperical_primary <- c(
  forest_dark   = "#1F6B3A",  # evergreen tree
  forest_mid    = "#3E8F5B",
  forest_light  = "#7BC8A4",

  fire_dark     = "#C43D1A",  # flame base
  fire_mid      = "#F26A2E",
  fire_light    = "#FDB366",

  data_orange   = "#F28E2B",  # "PatternR"
  data_blue     = "#2F5D7C",
  data_teal     = "#2FA4A9"
)

# ---- Background & Structural Colors ------------------------

emperical_background <- c(
  night_blue     = "#0E2A36",  # outer hex / header border
  deep_teal      = "#143F4F",
  grid_teal      = "#1F5668",
  muted_sage     = "#6E8F7A",

  parchment      = "#F5EEDC",  # scroll / paper
  parchment_warm = "#EFE2C4",
  parchment_dark = "#D6C7A1"
)

# ---- Data Visualization Colors -----------------------------

emperical_data <- c(
  blue_1  = "#1B3A4B",
  blue_2  = "#2F5D7C",
  blue_3  = "#4F7D99",

  green_1 = "#245C3A",
  green_2 = "#3E8F5B",
  green_3 = "#7BC8A4",

  orange_1 = "#C43D1A",
  orange_2 = "#F26A2E",
  orange_3 = "#FDB366"
)

# ---- Fire Severity / Disturbance Gradient ------------------

emperical_fire <- c(
  "#4B1D0F",  # char
  "#7A2E17",
  "#A33A1E",
  "#C43D1A",
  "#F26A2E",
  "#FDB366",
  "#FFE2A8"
)

# ---- Vegetation / Ecology Gradient -------------------------

emperical_forest <- c(
  "#0F2F1E",
  "#1F6B3A",
  "#3E8F5B",
  "#6FBF8F",
  "#9ED6B5",
  "#CFEBDD"
)

# ---- Tech / Binary Accents ---------------------------------

emperical_tech <- c(
  binary_light = "#BFE6E2",
  binary_mid   = "#6FB8B3",
  binary_dark  = "#2C7C7A",

  grid_light   = "#8FBFC6",
  grid_dark    = "#2B4F5C"
)

# ---- Text & Annotation Colors ------------------------------

emperical_text <- c(
  text_light  = "#F7F7F7",
  text_dark   = "#1E1E1E",
  text_muted  = "#8FA3A8",
  text_accent = "#F28E2B"
)

# ---- Master Palette ----------------------------------------

emperical_palette <- c(
  emperical_primary,
  emperical_background,
  emperical_data,
  emperical_fire,
  emperical_forest,
  emperical_tech,
  emperical_text
)

# ============================================================
# Helper Functions
# ============================================================

#' Get EmpericalPatternR color palettes
#'
#' @param palette Character. One of:
#'   "primary", "background", "data", "fire", "forest",
#'   "tech", "text", or "all"
#'
#' @return A named character vector of hex colors
#' @export
emperical_pal <- function(palette = "all") {
  switch(
    palette,
    primary    = emperical_primary,
    background = emperical_background,
    data       = emperical_data,
    fire       = emperical_fire,
    forest     = emperical_forest,
    tech       = emperical_tech,
    text       = emperical_text,
    all        = emperical_palette,
    stop("Unknown palette name.")
  )
}

#' ggplot2-friendly discrete scale
#'
#' @param palette Character. Palette name
#' @export
scale_color_emperical <- function(palette = "data", ...) {
  ggplot2::scale_color_manual(values = emperical_pal(palette), ...)
}

#' ggplot2-friendly fill scale
#'
#' @param palette Character. Palette name
#' @export
scale_fill_emperical <- function(palette = "data", ...) {
  ggplot2::scale_fill_manual(values = emperical_pal(palette), ...)
}

#' ggplot2 gradient scale (fire or forest)
#'
#' @param palette Character. "fire" or "forest"
#' @export
scale_fill_emperical_gradient <- function(palette = "fire", ...) {
  ggplot2::scale_fill_gradientn(colors = emperical_pal(palette), ...)
}

# ============================================================
# End of file
# ============================================================
