# ============================================================
# Learning Gradient - Project Configuration
# ============================================================
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
country_regions_url <- "https://raw.githubusercontent.com/unicef-drp/Country-and-Region-Metadata/refs/heads/main/output/UNICEF_PROG_REG_GLOBAL.csv"

# Required packages (must already exist in project renv library)
required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "stringr", "jsonlite", "conflicted", "curl")
missing <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0) {
  stop(
    "Missing required packages: ", paste(missing, collapse = ", "),
    "\nRun source(\"setup_renv.R\"), restart R, then run source(\"run_all.R\").",
    call. = FALSE
  )
}

invisible(lapply(required_packages, library, character.only = TRUE))

# Prefer dplyr::filter and dplyr::select over stats::filter and MASS::select project-wide
conflicted::conflicts_prefer(
  dplyr::filter,
  dplyr::select,
  dplyr::lag
)

# Create directories if missing
dirs <- c(documentation, rawDataFolder, userFunctionsFolder, scriptsFolder,
          outputFolder)
for (d in dirs) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

