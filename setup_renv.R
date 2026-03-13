# ============================================================
# setup_renv.R – Reproducible environment setup
# ============================================================
# Run once: source("setup_renv.R") then restart R.

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}
library(renv)

if (file.exists("renv.lock")) {
  # Restore pinned versions from lockfile
  renv::restore(prompt = FALSE)
  message("Setup complete. Restored from renv.lock. Run source(\"run_all.R\") to fetch data and run the pipeline.")
} else {
  # First-time: initialize, install packages, snapshot
  renv::init(bare = TRUE)
  packages <- c(
    "readr", "dplyr", "tidyr", "ggplot2", "stringr", "jsonlite", "rsdmx"
  )
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      renv::install(pkg)
    }
  }
  renv::snapshot()
  message("Setup complete. Restart R; then run source(\"run_all.R\") to fetch data and run the pipeline.")
}
