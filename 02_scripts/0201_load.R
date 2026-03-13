# ============================================================
# 0201_load.R – Load Learning Gradient data and enrichment sources
# ============================================================
# Loads:
#   1. dw_data: Learning Gradient data from UNICEF DW API (always fetched; saved to local CSV)
#   2. unicef_countries: UNICEF country names and regions (live API: Country-and-Region-Metadata)
#   3. african_countries: Vector of ISO3 codes for African countries (derived from UNICEF regions)
#   4. wb_income: World Bank income classifications
#
# Requires dw_api_url, dw_csv_path, country_regions_url in project_config.R.

if (!exists("projectFolder")) {
  if (file.exists("project_config.R")) source("project_config.R") else source("../project_config.R")
}

library(readr)
library(dplyr)
library(jsonlite)
library(rsdmx)

message("=== 0201_load.R: Loading data sources ===")

# ============================================================
# 1. LEARNING GRADIENT DATA (from UNICEF SDMX API)
# ============================================================
if (!nzchar(dw_api_url)) {
  stop("dw_api_url is not set. Set it in project_config.R.")
}

dw_data <- tryCatch(
  as.data.frame(readSDMX(dw_api_url, isURL = TRUE)),
  error = function(e) {
    stop("Fetch failed (", dw_api_url, "): ", conditionMessage(e))
  }
)

# Coerce numeric columns (SDMX often returns strings)
if ("TIME_PERIOD" %in% names(dw_data)) dw_data$TIME_PERIOD <- as.integer(dw_data$TIME_PERIOD)
if ("OBS_VALUE" %in% names(dw_data)) dw_data$OBS_VALUE <- as.numeric(dw_data$OBS_VALUE)
if ("N_OBS" %in% names(dw_data)) dw_data$N_OBS <- as.numeric(dw_data$N_OBS)

write_csv(dw_data, dw_csv_path)
message("Loaded dw_data from API: ", nrow(dw_data), " rows (saved to ", dw_csv_path, ")")

# ============================================================
# 2. UNICEF COUNTRY-REGION METADATA (from API)
# ============================================================
unicef_countries <- tryCatch(
  {
    out <- read_csv(country_regions_url, show_col_types = FALSE) %>%
      filter(Regional_Grouping == "UNICEF_PROG_REG_GLOBAL") %>%
      select(Country, ISO3Code, Region_Code, Region) %>%
      mutate(
        Region_Code = if_else(Region_Code %in% c("UNICEF_ESARO", "UNICEF_WCARO"), "UNICEF_AFRICA", Region_Code),
        Region      = if_else(Region_Code == "UNICEF_AFRICA", "Africa", Region)
      ) %>%
      distinct(ISO3Code, .keep_all = TRUE) %>%
      rename(iso3 = ISO3Code, country_name = Country)
    message("Loaded unicef_countries from API: ", nrow(out), " countries")
    out
  },
  error = function(e) {
    stop("Country-region metadata fetch failed. Please check your connection to the API (", country_regions_url, "): ", conditionMessage(e), call. = FALSE)
  }
)

# ============================================================
# 3. AFRICAN COUNTRIES (derived from UNICEF regions)
# ============================================================
african_countries <- unicef_countries %>%
  filter(Region_Code == "UNICEF_AFRICA") %>%
  pull(iso3)
message("African countries (UNICEF_AFRICA): ", length(african_countries), " countries")

# ============================================================
# 4. WORLD BANK INCOME CLASSIFICATIONS (from API)
# ============================================================
message("Fetching World Bank income classifications...")
wb_income <- tryCatch(
  {
    url <- "https://api.worldbank.org/v2/country?format=json&per_page=1000"
    api_data <- fromJSON(url)
    country_data <- api_data[[2]]

    df <- data.frame(
      iso3              = country_data$id,
      income_level_code = country_data$incomeLevel$id,
      income_level      = country_data$incomeLevel$value,
      stringsAsFactors  = FALSE
    )
    message("Loaded wb_income: ", nrow(df), " countries")
    df
  },
  error = function(e) {
    stop("World Bank income data fetch failed. Please check your connection to the API (", url, "): ", conditionMessage(e), call. = FALSE)
  }
)

# ============================================================
# EXPORT TO GLOBAL ENVIRONMENT
# ============================================================
assign("dw_data", dw_data, envir = .GlobalEnv)
assign("unicef_countries", unicef_countries, envir = .GlobalEnv)
assign("african_countries", african_countries, envir = .GlobalEnv)
assign("wb_income", wb_income, envir = .GlobalEnv)

message("=== 0201_load.R complete ===")
