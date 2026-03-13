# R environment setup (renv)

## Quick setup

1. Open R or RStudio in the **project root** directory.
2. Run:
   ```r
   source("setup_renv.R")
   ```
3. Restart R (Session → Restart R in RStudio, or restart R console).
4. Run the pipeline: `source("run_all.R")`.

Alternatively, skip step 2 by setting `FORCE_RENV_RESTORE <- TRUE` before sourcing `run_all.R`. This triggers environment restoration as part of the pipeline run:

```r
FORCE_RENV_RESTORE <- TRUE
source("run_all.R")
```

## What setup_renv.R does

- Installs **renv** if needed
- Initializes the project library (`renv::init(bare = TRUE)` if no `renv.lock` yet)
- Installs required packages (readr, dplyr, tidyr, ggplot2, stringr, jsonlite, rsdmx)
- Creates a snapshot (`renv.lock`)

First run may take a few minutes.

## Manual setup

If you prefer to set up renv yourself:

```r
install.packages("renv")
renv::init(bare = TRUE)
# Install packages (see setup_renv.R for the list)
renv::install(c("readr", "dplyr", "tidyr", "ggplot2", "stringr", "jsonlite", "rsdmx"))
renv::snapshot()
```

## After clone (new machine)

```r
renv::restore()
```

Then restart R. No need to run `setup_renv.R` again unless you add packages.

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
- **Wrong R version**: Use R 4.0 or higher.
