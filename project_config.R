# ============================================================
# Learning Gradient - Project Configuration
# ============================================================
# Base R only. Load before renv so paths are available everywhere.
# Source from run_all.R, .Rprofile, or scripts as needed.

# Project root (auto-detect if not set)
if (exists("projectFolder") && nzchar(projectFolder)) {
  # Already set (e.g. by .Rprofile)
} else {
  projectFolder <- getwd()
  # If run from a subfolder (e.g. 04_rshiny), find project root (parent of 02_scripts)
  if (!dir.exists(file.path(projectFolder, "02_scripts"))) {
    parent <- dirname(projectFolder)
    if (dir.exists(file.path(parent, "02_scripts"))) {
      projectFolder <- parent
    }
  }
}

# Core paths
documentation       <- file.path(projectFolder, "00_documentation")
rawDataFolder       <- file.path(projectFolder, "01_data")
userFunctionsFolder <- file.path(projectFolder, "99_user_functions")
scriptsFolder       <- file.path(projectFolder, "02_scripts")
outputFolder        <- file.path(projectFolder, "03_output")
# DW API URL (required)
dw_api_url <- "https://sdmx.data.unicef.org/ws/public/sdmxapi/rest/data/UNICEF,EDUCATION_LG,1.0/all"

# Path where fetched DW data is saved
dw_csv_path <- file.path(rawDataFolder, "0101_learning_gradient_unicef_dw.csv")

# Country-region metadata API (UNICEF Country-and-Region-Metadata)
country_regions_url <- "https://raw.githubusercontent.com/unicef-drp/Country-and-Region-Metadata/refs/heads/main/output/all_regions_long_format.csv"

# Required packages (must be installed; run setup_renv.R if missing)
required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "stringr", "jsonlite", "rsdmx")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      "Package '", pkg, "' is required but not installed. Run setup_renv.R or install.packages(\"", pkg, "\").",
      call. = FALSE
    )
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Create directories if missing
dirs <- c(documentation, rawDataFolder, userFunctionsFolder, scriptsFolder,
          outputFolder)
for (d in dirs) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# ============================================================
# PIPELINE OPTIONS
# ============================================================
# Set FORCE_RENV_RESTORE <- TRUE before sourcing run_all.R to trigger
# renv::restore() at the start of the pipeline. This is equivalent to
# running setup_renv.R manually and is provided for automated or
# first-time execution contexts. The default is FALSE to avoid
# unintended package installation during routine sessions.
if (!exists("FORCE_RENV_RESTORE")) FORCE_RENV_RESTORE <- FALSE
