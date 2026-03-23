# ============================================================
# run_all.R – Single entry: fetch → transform → produce charts
# ============================================================
# Run from project root: source("run_all.R")

# Activate renv before config so packages load from project library
if (file.exists("renv/activate.R")) source("renv/activate.R")

# Restore on first run (or after clone) when project library is out of sync
if (!isTRUE(renv::status()$synchronized)) renv::restore()

if (file.exists("project_config.R")) source("project_config.R") else stop("project_config.R not found. Run from project root.")
setwd(projectFolder)

# 01 – Load data
source(file.path(scriptsFolder, "0201_load.R"))

# 02 – Transform data
source(file.path(scriptsFolder, "0202_transform.R"))

# 03 – Produce charts (PNG files from output CSVs)
source(file.path(scriptsFolder, "0203_produce_charts.R"))

message("Pipeline complete.")