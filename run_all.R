# ============================================================
# run_all.R – Single entry: fetch → transform → produce charts
# ============================================================
# Run from project root: source("run_all.R")

# Activate renv before config so packages load from project library
if (file.exists("renv/activate.R")) source("renv/activate.R")

if (file.exists("project_config.R")) source("project_config.R") else stop("project_config.R not found. Run from project root.")
setwd(projectFolder)

# Optionally restore pinned package versions before running the pipeline.
# Set FORCE_RENV_RESTORE <- TRUE before sourcing this script to trigger setup_renv.R.
if (exists("FORCE_RENV_RESTORE") && isTRUE(FORCE_RENV_RESTORE)) {
  message("FORCE_RENV_RESTORE is TRUE: running setup_renv.R before pipeline.")
  source("setup_renv.R")
}

# 01 – Load data
source(file.path(scriptsFolder, "0201_load.R"))

# 02 – Transform data
source(file.path(scriptsFolder, "0202_transform.R"))

# 03 – Produce charts (PNG files from output CSVs)
source(file.path(scriptsFolder, "0203_produce_charts.R"))

message("Pipeline complete.")
