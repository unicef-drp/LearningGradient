# Reproducibility Note

This repository enables users to regenerate Learning Gradient output tables and chart images from the UNICEF Global Data Warehouse without access to microdata. Indicator structure and Data Warehouse query details are described in the [Technical Note](../0001_technical_note/Technical_Note.md).

---

## Running the workflow

From the repository root directory, run:

```r
source("run_all.R")
```

Before first execution, run `source("setup_renv.R")` to restore pinned package versions, then restart R. Subsequently, `source("run_all.R")` retrieves data from the Data Warehouse, rebuilds the output tables in `03_output/0301_tables/`, and exports chart images to `03_output/0302_figures/`. An active internet connection is required to fetch data from the UNICEF Data Warehouse API, the UNICEF Country-and-Region-Metadata API, and the World Bank API.

To combine both steps into a single call, set `FORCE_RENV_RESTORE <- TRUE` before sourcing `run_all.R`. This triggers `setup_renv.R` automatically at the start of the pipeline run. The default value is `FALSE` to avoid unintended package installation during routine sessions.

---

## Software environment

This project uses [renv](https://rstudio.github.io/renv/) to lock R package versions and support reproducible installs. Package versions are recorded in `renv.lock`, and the project environment is activated through `.Rprofile` and `renv/activate.R`. The pipeline has been tested on R version 4.0 and higher.

On first run, dependencies are restored using:

```r
renv::restore()
```

---

## What is computed in this repository

The Data Warehouse provides harmonized aggregated inputs (proficiency rates and sample size measures). Analytical and visualization choices are computed in this repository so they remain explicit and reproducible in code. These include minimum observation filtering, latest-year selection, LOESS smoothing used for visualization, and any mean-based aggregations used for chart overlays or benchmarks.

---

## Parameters that influence outputs

Several configurable settings can change the resulting outputs and should be treated as part of the run configuration. These include the latest-year selection rule, the minimum observations threshold (25 by default), missingness tolerance rules, and smoothing settings (including whether smoothing is applied and the LOESS span, which defaults to 1).

