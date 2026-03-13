# ============================================================
# setup_renv.R – Pin exact package versions via renv
# ============================================================
# Optional. Required packages are installed automatically by
# project_config.R on first session. This script pins exact
# versions from renv.lock for reproducibility (audits, CI,
# publications).
#
# Usage: source("setup_renv.R")
# ============================================================

message("=== setup_renv.R: Pinning exact package versions ===")

if (!file.exists("renv.lock")) {
  stop("renv.lock not found. Run from project root.", call. = FALSE)
}

if (file.exists("renv/activate.R")) source("renv/activate.R")

renv::restore()

message("=== Versions pinned. Restart R, then run: source(\"run_all.R\") ===")
