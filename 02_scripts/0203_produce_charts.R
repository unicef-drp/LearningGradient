# ============================================================
# 0203_produce_charts.R – Produce PNG charts from output CSVs
# ============================================================
# Input:
#   - output_grade (from 0202_transform.R or 03_output/0301_tables/030101_output_grade.csv)
#   - output_grade_band (from 0202_transform.R or 03_output/0301_tables/030102_output_grade_band.csv)
# Output: PNG chart files saved to 03_output/
#
# This script recreates the charts from the scrollytelling story
# using the two output CSV files as source data.

if (!exists("projectFolder")) {
  if (file.exists("project_config.R")) source("project_config.R") else source("../project_config.R")
}

library(ggplot2)
library(dplyr)
library(readr)

message("=== 0203_produce_charts.R: Producing charts ===")

# ============================================================
# LOAD DATA (from global env or CSV files)
# ============================================================
tablesFolder <- file.path(outputFolder, "0301_tables")

if (!exists("output_grade")) {
  csv_path <- file.path(tablesFolder, "030101_output_grade.csv")
  if (file.exists(csv_path)) {
    output_grade <- read_csv(csv_path, show_col_types = FALSE)
    message("Loaded output_grade from CSV: ", nrow(output_grade), " rows")
  } else {
    stop("output_grade not found. Run 0202_transform.R first or ensure CSV exists.")
  }
}

if (!exists("output_grade_band")) {
  csv_path <- file.path(tablesFolder, "030102_output_grade_band.csv")
  if (file.exists(csv_path)) {
    output_grade_band <- read_csv(csv_path, show_col_types = FALSE)
    message("Loaded output_grade_band from CSV: ", nrow(output_grade_band), " rows")
  } else {
    stop("output_grade_band not found. Run 0202_transform.R first or ensure CSV exists.")
  }
}


# ============================================================
# CONFIGURABLE PARAMETERS
# ============================================================

# Filters
MIN_OBS <- 25 # Exclude country-grade rows where n_weighted < this threshold (i.e., retain rows where n_weighted >= MIN_OBS)
MISSING_GRADES_TOL <- 8 # Max missing grades per country (8 = keep all; 1 = only complete)

# Benchmark labels & colors (UNICEF palette)
BENCH_AFRICA_LABEL <- "MICS6 Africa Countries"
BENCH_AFRICA_COLOR <- "#1CABE2" # UNICEF Blue
BENCH_NON_AFRICA_LABEL <- "MICS6 Rest of the world countries"
BENCH_NON_AFRICA_COLOR <- "#2D2926" # Pantone Black

# Country background colors (faint)
COUNTRY_AFRICA_COLOR <- "#d1e4e6" # Faint Blue
COUNTRY_NON_AFRICA_COLOR <- "#f1e9e0" # Faint Orange

# Output dimensions
CHART_WIDTH <- 10 # inches
CHART_HEIGHT <- 7 # inches
CHART_DPI <- 300

# ============================================================
# FUNCTION: produce_country_by_grade_chart
# ============================================================

produce_country_by_grade_chart <- function(
    data, # output_grade data frame
    subject_filter, # "reading" or "numeracy"
    output_path, # full path to output PNG
    min_obs = 25,
    missing_tol = 8,
    bench_labels = c("MICS6 Africa Countries", "MICS6 Rest of the world countries"),
    bench_colors = c("#1CABE2", "#2D2926"),
    width = 10,
    height = 7,
    dpi = 300) {
  # -------------------------------------------------------
  # Data Preparation
  # -------------------------------------------------------

  # 1-5: Single pipeline for both country lines and benchmarks
  filtered_data <- data %>%
    # 1. Filter: subject, category == "All"
    filter(subject == subject_filter, category == "All") %>%
    # 2. Remove rows where pct_weighted_loess_span1 is NA
    filter(!is.na(pct_weighted_loess_span1)) %>%
    # 3. Keep grades 1-8 only
    filter(grade >= 1, grade <= 8) %>%
    # 4. Apply min-obs: retain rows where n_weighted >= min_obs (inclusive boundary)
    filter(n_weighted >= min_obs)

  # 5. Apply missing-grades tolerance
  required_grades <- 8 - (missing_tol - 1)

  country_grade_counts <- filtered_data %>%
    group_by(iso3) %>%
    summarise(n_grades = n_distinct(grade), .groups = "drop") %>%
    filter(n_grades >= required_grades)

  filtered_data <- filtered_data %>%
    filter(iso3 %in% country_grade_counts$iso3)

  # -------------------------------------------------------
  # Country Lines
  # -------------------------------------------------------

  country_data <- filtered_data %>%
    mutate(
      country_group = ifelse(is_africa, "Africa_BG", "Non_Africa_BG")
    )

  # -------------------------------------------------------
  # Benchmark Lines
  # -------------------------------------------------------

  benchmark_data <- filtered_data %>%
    group_by(grade, is_africa) %>%
    summarise(
      pct_weighted_loess_span1 = mean(pct_weighted_loess_span1, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      benchmark_label = ifelse(is_africa, bench_labels[1], bench_labels[2]),
      benchmark_color = ifelse(is_africa, bench_colors[1], bench_colors[2])
    )

  # -------------------------------------------------------
  # Title & Subtitle (dynamic by subject)
  # -------------------------------------------------------

  if (subject_filter == "reading") {
    plot_title <- "Foundational Reading"
    plot_subtitle <- "Mean Reading proficiency by grade (LOESS Smoothed)"
    y_label <- "Reading proficiency (%)"
  } else {
    plot_title <- "Foundational Numeracy"
    plot_subtitle <- "Mean Numeracy proficiency by grade (LOESS Smoothed)"
    y_label <- "Numeracy proficiency (%)"
  }

  # -------------------------------------------------------
  # Build Plot
  # -------------------------------------------------------

  p <- ggplot() +
    # Layer 1: Country curves (one per iso3) - Smoothed
    geom_smooth(
      data = country_data,
      aes(x = grade, y = pct_weighted_loess_span1, group = iso3, color = country_group),
      method = "loess",
      se = FALSE,
      alpha = 0.4,
      linewidth = 0.5,
      span = 1
    ) +
    # Layer 2: Country grade points
    geom_point(
      data = country_data,
      aes(x = grade, y = pct_weighted_loess_span1, color = country_group),
      alpha = 0.6,
      size = 1.5
    ) +
    # Layer 3 & 4: Benchmark lines - Smoothed
    geom_smooth(
      data = benchmark_data,
      aes(x = grade, y = pct_weighted_loess_span1, color = benchmark_label, group = benchmark_label),
      method = "loess",
      se = FALSE,
      linewidth = 1.5,
      span = 1
    ) +
    geom_point(
      data = benchmark_data,
      aes(x = grade, y = pct_weighted_loess_span1, color = benchmark_label),
      size = 3
    ) +
    # Layer 5 & 6: Value labels for benchmarks
    geom_text(
      data = benchmark_data %>% filter(is_africa),
      aes(x = grade, y = pct_weighted_loess_span1, label = sprintf("%.1f%%", pct_weighted_loess_span1)),
      color = bench_colors[1],
      vjust = 2.5,
      size = 3
    ) +
    geom_text(
      data = benchmark_data %>% filter(!is_africa),
      aes(x = grade, y = pct_weighted_loess_span1, label = sprintf("%.1f%%", pct_weighted_loess_span1)),
      color = bench_colors[2],
      vjust = -1.0,
      size = 3
    ) +
    # Scales
    scale_color_manual(
      values = c(
        setNames(bench_colors, bench_labels),
        "Africa_BG" = COUNTRY_AFRICA_COLOR,
        "Non_Africa_BG" = COUNTRY_NON_AFRICA_COLOR
      ),
      breaks = bench_labels, # Only show benchmarks in legend
      name = NULL
    ) +
    scale_x_continuous(
      name = "Grade",
      breaks = 1:8,
      limits = c(0.5, 8.5)
    ) +
    scale_y_continuous(
      name = y_label,
      limits = c(0, 100),
      breaks = seq(0, 100, 20)
    ) +
    # Labels
    labs(
      title = plot_title,
      subtitle = plot_subtitle
    ) +
    # Theme
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_line(color = "grey90"),
      panel.grid.minor.y = element_line(color = "grey95"),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11)
    )

  # -------------------------------------------------------
  # Save Plot
  # -------------------------------------------------------

  ggsave(
    filename = output_path,
    plot = p,
    width = width,
    height = height,
    dpi = dpi,
    units = "in"
  )

  message("Saved chart: ", output_path)

  return(invisible(p))
}

# ============================================================
# CHART 2: CONFIGURABLE PARAMETERS
# ============================================================

# Filters
MIN_OBS_BAND <- 25 # Exclude combinations with n_weighted <= this
MISSING_COMB_TOL <- 15 # Max missing combinations per country (15 = keep all)
# 15 expected = 3 grade bands × 5 quintiles (excl. "All")

# Panel / facet labels (from app.R Dashboard 2)
PANEL_ALL_LABEL <- "All Countries"
PANEL_AFRICA_LABEL <- "MICS6 Africa Countries"
PANEL_ROW_LABEL <- "MICS6 Rest of the world countries"

# Wealth group labels & colors (UNICEF palette)
WEALTH_CATEGORIES <- c("All", "Poorest", "Second", "Middle", "Fourth", "Richest")
WEALTH_COLORS <- c(
  "All"     = "#1CABE2", # UNICEF Blue
  "Poorest" = "#F26A21", # Pantone 1505 (Orange)
  "Second"  = "#FFC20E", # Pantone 7548 (Yellow)
  "Middle"  = "#77777A", # Cool Grey 9
  "Fourth"  = "#80BD41", # Pantone 376 (Light Green)
  "Richest" = "#00833D" # Pantone 356 (Dark Green)
)

# Grade bands (ordered)
GRADE_BANDS <- c("Early Primary (1-3)", "End of Primary (4-6)", "Lower Secondary (7-9)")

# Output dimensions
CHART2_WIDTH_PER_PANEL <- 7 # inches
CHART2_HEIGHT <- 7 # inches
CHART2_DPI <- 300

# ============================================================
# FUNCTION: produce_wealth_by_grade_band_chart
# ============================================================

produce_wealth_by_grade_band_chart <- function(
    data, # output_grade_band data frame
    subject_filter, # "reading" or "numeracy"
    output_path, # full path to output PNG
    panels, # character vector of panel labels to include
    min_obs = 25,
    missing_comb_tol = 15,
    wealth_categories = c("All", "Poorest", "Second", "Middle", "Fourth", "Richest"),
    wealth_colors = c(
      "All" = "#1CABE2", "Poorest" = "#F26A21", "Second" = "#FFC20E",
      "Middle" = "#77777A", "Fourth" = "#80BD41", "Richest" = "#00833D"
    ),
    grade_bands = c("Early Primary (1-3)", "End of Primary (4-6)", "Lower Secondary (7-9)"),
    width_per_panel = 7,
    height = 7,
    dpi = 300) {
  # -------------------------------------------------------
  # Data Preparation
  # -------------------------------------------------------

  # 1-2: Filter and apply min-obs
  filtered_data <- data %>%
    filter(
      subject == subject_filter,
      grade_band %in% grade_bands,
      !is.na(pct_weighted_loess_span1)
    ) %>%
    filter(n_weighted >= min_obs)

  # 3: Apply missing-combinations tolerance
  quintile_categories <- c("Poorest", "Second", "Middle", "Fourth", "Richest")
  expected_combinations <- length(grade_bands) * length(quintile_categories) # 15

  country_comb_counts <- filtered_data %>%
    filter(category %in% quintile_categories) %>%
    group_by(iso3) %>%
    summarise(n_combinations = n_distinct(paste(category, grade_band)), .groups = "drop")

  max_missing_allowed <- missing_comb_tol - 1
  valid_countries <- country_comb_counts %>%
    filter((expected_combinations - n_combinations) <= max_missing_allowed) %>%
    pull(iso3)

  filtered_data <- filtered_data %>%
    filter(iso3 %in% valid_countries)

  # 4: Add ordered factors
  filtered_data <- filtered_data %>%
    mutate(
      grade_band = factor(grade_band, levels = grade_bands, ordered = TRUE),
      category = factor(category, levels = wealth_categories, ordered = TRUE)
    )

  # 5: Create panel column based on panels parameter
  panel_data <- filtered_data %>%
    mutate(
      panel_all = PANEL_ALL_LABEL %in% panels,
      panel_africa = PANEL_AFRICA_LABEL %in% panels & is_africa,
      panel_row = PANEL_ROW_LABEL %in% panels & !is_africa
    )

  # Duplicate rows into requested facets
  panel_list <- list()

  if (PANEL_ALL_LABEL %in% panels) {
    panel_list[[PANEL_ALL_LABEL]] <- panel_data %>%
      mutate(panel = PANEL_ALL_LABEL)
  }
  if (PANEL_AFRICA_LABEL %in% panels) {
    panel_list[[PANEL_AFRICA_LABEL]] <- panel_data %>%
      filter(is_africa) %>%
      mutate(panel = PANEL_AFRICA_LABEL)
  }
  if (PANEL_ROW_LABEL %in% panels) {
    panel_list[[PANEL_ROW_LABEL]] <- panel_data %>%
      filter(!is_africa) %>%
      mutate(panel = PANEL_ROW_LABEL)
  }

  panel_data <- bind_rows(panel_list)

  # 6: Aggregate within each (panel, category, grade_band)
  agg_data <- panel_data %>%
    group_by(panel, category, grade_band) %>%
    summarise(
      pct_weighted_loess_span1 = mean(pct_weighted_loess_span1, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(panel = factor(panel, levels = panels, ordered = TRUE))

  # -------------------------------------------------------
  # Title & Subtitle (dynamic by subject)
  # -------------------------------------------------------

  if (subject_filter == "reading") {
    plot_title <- "Foundational Reading"
    plot_subtitle <- "Mean proficiency by wealth and grade band (LOESS Smoothed)"
    y_label <- "Reading - % with foundational skills"
  } else {
    plot_title <- "Foundational Numeracy"
    plot_subtitle <- "Mean proficiency by wealth and grade band (LOESS Smoothed)"
    y_label <- "Numeracy - % with foundational skills"
  }

  # -------------------------------------------------------
  # Build Plot
  # -------------------------------------------------------

  # Determine if this is the split variant (2 panels: Africa + RoW)
  is_split_variant <- length(panels) == 2 &&
    PANEL_AFRICA_LABEL %in% panels &&
    PANEL_ROW_LABEL %in% panels

  # Use 80% transparency for split variant base lines, 40% for other variants
  base_alpha <- if (is_split_variant) 0.2 else 0.4

  # Separate "All" from quintiles
  quintile_data <- agg_data %>% filter(category != "All")
  all_data <- agg_data %>% filter(category == "All")

  p <- ggplot() +
    # Layer 1 & 2: Quintile lines and markers
    geom_line(
      data = quintile_data,
      aes(x = grade_band, y = pct_weighted_loess_span1, color = category, group = category),
      alpha = base_alpha,
      linewidth = 0.8
    ) +
    geom_point(
      data = quintile_data,
      aes(x = grade_band, y = pct_weighted_loess_span1, color = category),
      alpha = base_alpha,
      size = 2
    ) +
    # Layer 3 & 4: "All" line and markers
    geom_line(
      data = all_data,
      aes(x = grade_band, y = pct_weighted_loess_span1, color = category, group = category),
      alpha = if (is_split_variant) base_alpha else 1.0,
      linewidth = if (is_split_variant) 0.8 else 1.4
    ) +
    geom_point(
      data = all_data,
      aes(x = grade_band, y = pct_weighted_loess_span1, color = category),
      alpha = if (is_split_variant) base_alpha else 1.0,
      size = if (is_split_variant) 2 else 3
    ) +
    # Layer 5: "All" value labels
    geom_text(
      data = all_data,
      aes(x = grade_band, y = pct_weighted_loess_span1, label = sprintf("%.1f%%", pct_weighted_loess_span1)),
      color = wealth_colors["All"],
      vjust = -1.2,
      hjust = 1.2,
      size = 3
    ) +
    # Faceting
    facet_wrap(~panel, nrow = 1) +
    # Scales
    scale_color_manual(
      values = wealth_colors,
      breaks = wealth_categories,
      name = "Wealth Group"
    ) +
    scale_y_continuous(
      name = y_label,
      limits = c(0, 100),
      breaks = seq(0, 100, 20)
    ) +
    scale_x_discrete(name = NULL) +
    # Labels
    labs(
      title = plot_title,
      subtitle = plot_subtitle
    ) +
    # Theme
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 10),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_line(color = "#E5E5E5"),
      panel.grid.minor.y = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11),
      strip.text = element_text(face = "bold", size = 11),
      axis.text.x = element_text(angle = 0, hjust = 0.5)
    ) +
    guides(color = guide_legend(nrow = 1))

  # -------------------------------------------------------
  # Conditional Styling & Labels for Split Variant
  # -------------------------------------------------------

  if (is_split_variant) {
    # Poorest in Africa panel (below markers)
    poorest_africa <- quintile_data %>%
      filter(panel == PANEL_AFRICA_LABEL, category == "Poorest")

    # Richest in RoW panel (above markers)
    richest_row <- quintile_data %>%
      filter(panel == PANEL_ROW_LABEL, category == "Richest")

    p <- p +
      # Highlight specific lines (opaque, normal thickness)
      geom_line(
        data = poorest_africa,
        aes(x = grade_band, y = pct_weighted_loess_span1, color = category, group = category),
        linewidth = 0.8,
        alpha = 0.4,
        show.legend = FALSE
      ) +
      geom_line(
        data = richest_row,
        aes(x = grade_band, y = pct_weighted_loess_span1, color = category, group = category),
        linewidth = 0.8,
        alpha = 0.4,
        show.legend = FALSE
      ) +
      # Add labels
      geom_text(
        data = poorest_africa,
        aes(
          x = grade_band, y = pct_weighted_loess_span1,
          label = sprintf("%.1f%%", pct_weighted_loess_span1)
        ),
        color = wealth_colors["Poorest"],
        vjust = 1.8,
        size = 3
      ) +
      geom_text(
        data = richest_row,
        aes(
          x = grade_band, y = pct_weighted_loess_span1,
          label = sprintf("%.1f%%", pct_weighted_loess_span1)
        ),
        color = wealth_colors["Richest"],
        vjust = -0.8,
        size = 3
      )
  }

  # -------------------------------------------------------
  # Save Plot
  # -------------------------------------------------------

  chart_width <- width_per_panel * length(panels)

  ggsave(
    filename = output_path,
    plot = p,
    width = chart_width,
    height = height,
    dpi = dpi,
    units = "in"
  )

  message("Saved chart: ", output_path)

  return(invisible(p))
}

# ============================================================
# CHARTS
# ============================================================

# Ensure figures folder exists
figuresFolder <- file.path(outputFolder, "0302_figures")
if (!dir.exists(figuresFolder)) dir.create(figuresFolder, recursive = TRUE)

# ------------------------------------------------------------
# Chart 1: Country-by-Grade
# ------------------------------------------------------------

# Produce Reading Chart
produce_country_by_grade_chart(
  data = output_grade,
  subject_filter = "reading",
  output_path = file.path(figuresFolder, "030201_country_by_grade_reading.png"),
  min_obs = MIN_OBS,
  missing_tol = MISSING_GRADES_TOL,
  bench_labels = c(BENCH_AFRICA_LABEL, BENCH_NON_AFRICA_LABEL),
  bench_colors = c(BENCH_AFRICA_COLOR, BENCH_NON_AFRICA_COLOR),
  width = CHART_WIDTH, height = CHART_HEIGHT, dpi = CHART_DPI
)

# Produce Numeracy Chart
produce_country_by_grade_chart(
  data = output_grade,
  subject_filter = "numeracy",
  output_path = file.path(figuresFolder, "030202_country_by_grade_numeracy.png"),
  min_obs = MIN_OBS,
  missing_tol = MISSING_GRADES_TOL,
  bench_labels = c(BENCH_AFRICA_LABEL, BENCH_NON_AFRICA_LABEL),
  bench_colors = c(BENCH_AFRICA_COLOR, BENCH_NON_AFRICA_COLOR),
  width = CHART_WIDTH, height = CHART_HEIGHT, dpi = CHART_DPI
)

# ------------------------------------------------------------
# Chart 2: Wealth by Grade Band
# ------------------------------------------------------------

# --- Chart 2a: All countries (1 panel) ---
# To add numeracy, change c("reading") to c("reading", "numeracy")
for (subj in c("reading")) {
  produce_wealth_by_grade_band_chart(
    data = output_grade_band,
    subject_filter = subj,
    output_path = file.path(figuresFolder, paste0("030203_wealth_by_grade_band_all_", subj, ".png")),
    panels = c(PANEL_ALL_LABEL),
    min_obs = MIN_OBS_BAND,
    missing_comb_tol = MISSING_COMB_TOL,
    wealth_categories = WEALTH_CATEGORIES,
    wealth_colors = WEALTH_COLORS,
    grade_bands = GRADE_BANDS,
    width_per_panel = CHART2_WIDTH_PER_PANEL,
    height = CHART2_HEIGHT,
    dpi = CHART2_DPI
  )
}

# --- Chart 2b: Africa + Rest of world (2 panels) ---
# To add numeracy, change c("reading") to c("reading", "numeracy")
for (subj in c("reading")) {
  produce_wealth_by_grade_band_chart(
    data = output_grade_band,
    subject_filter = subj,
    output_path = file.path(figuresFolder, paste0("030204_wealth_by_grade_band_split_", subj, ".png")),
    panels = c(PANEL_AFRICA_LABEL, PANEL_ROW_LABEL),
    min_obs = MIN_OBS_BAND,
    missing_comb_tol = MISSING_COMB_TOL,
    wealth_categories = WEALTH_CATEGORIES,
    wealth_colors = WEALTH_COLORS,
    grade_bands = GRADE_BANDS,
    width_per_panel = CHART2_WIDTH_PER_PANEL,
    height = CHART2_HEIGHT,
    dpi = CHART2_DPI
  )
}

# --- Chart 2c: Side by side — All + Africa + Rest of world (3 panels) ---
# To add numeracy, change c("reading") to c("reading", "numeracy")
for (subj in c("reading")) {
  produce_wealth_by_grade_band_chart(
    data = output_grade_band,
    subject_filter = subj,
    output_path = file.path(figuresFolder, paste0("030205_wealth_by_grade_band_side_by_side_", subj, ".png")),
    panels = c(PANEL_ALL_LABEL, PANEL_AFRICA_LABEL, PANEL_ROW_LABEL),
    min_obs = MIN_OBS_BAND,
    missing_comb_tol = MISSING_COMB_TOL,
    wealth_categories = WEALTH_CATEGORIES,
    wealth_colors = WEALTH_COLORS,
    grade_bands = GRADE_BANDS,
    width_per_panel = CHART2_WIDTH_PER_PANEL,
    height = CHART2_HEIGHT,
    dpi = CHART2_DPI
  )
}


message("=== 0203_produce_charts.R complete ===")
