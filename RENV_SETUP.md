# R environment setup (renv)

## Quick setup

1. Open R or RStudio in the **project root** directory.
2. Run:
   ```r
   source("setup_renv.R")
   ```
3. Restart R (Session → Restart R in RStudio, or restart R console).
4. Run the pipeline: `source("run_all.R")`.

## What setup_renv.R does

- Restores pinned versions from `renv.lock` using `renv::restore()`
- Pins the project environment for strict reproducibility contexts (audits, CI, publication reruns)

First run may take a few minutes.

## Manual setup

If you prefer to set up renv yourself:

```r
install.packages("renv")
renv::init(bare = TRUE)
# Install packages (see project_config.R for the list)
renv::install(c("readr", "dplyr", "tidyr", "ggplot2", "stringr", "jsonlite", "conflicted", "curl"))
renv::snapshot()
```

## After clone (new machine)

```r
renv::restore()
```

Then restart R. In this repository, renv restore is mandatory before running `run_all.R`.

## Useful renv commands

```r
renv::status()     # Check status
renv::restore()    # Restore from renv.lock
renv::snapshot()   # Update lockfile
renv::install("pkg")  # Add a package (then snapshot)
```

## Important files

- **renv.lock** – Commit to git (exact package versions).
- **renv/activate.R** – Commit; used by .Rprofile.
- **renv/library/** – Do not commit (local installs).
- **.Rprofile** – Loads project_config.R and renv.

## Troubleshooting

- **Packages fail to install**: Try `renv::install("package_name")` individually.
- **renv not activating**: Run `source("renv/activate.R")` then `source("project_config.R")`.
- **Wrong R version**: Use R 4.4.0 or higher.
