# ============================================================
# setup_renv.R – Restore pinned package versions from renv.lock
# ============================================================
# Mandatory for first run (or after clone). Restores exact
# versions from renv.lock. No auto-install; renv is required.
#
# Usage: source("setup_renv.R") then restart R
# ============================================================

message("=== setup_renv.R: Pinning exact package versions ===")

if (!file.exists("renv.lock")) {
  stop("renv.lock not found. Run from project root.", call. = FALSE)
}

if (file.exists("renv/activate.R")) source("renv/activate.R")

renv::restore()

message("=== Versions pinned. Restart R, then run: source(\"run_all.R\") ===")
