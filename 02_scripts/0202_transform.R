# ============================================================
# 0202_transform.R – Transform DW format to output shape
# ============================================================
# Input: dw_data, unicef_countries, african_countries, wb_income (from 01_load.R)
# Output: Two enriched tibbles with LOESS smoothing:
#   - output_grade: grade-level data (grades 1-8)
#   - output_grade_band: grade-band data (Early Primary, End of Primary, Lower Secondary)
#
# Columns: iso3, country_name, category, subject, grade/grade_band,
#          is_africa, income_level, income_level_code, Region_Code, Region,
#          n_unweighted, pct_weighted, n_weighted, pct_unweighted, pct_weighted_loess_span1

if (!exists("projectFolder")) {
  if (file.exists("project_config.R")) source("project_config.R") else source("../project_config.R")
}

library(dplyr)
library(tidyr)
library(stringr)

message("=== 0202_transform.R: Transforming data ===")

# ============================================================
# REQUIRE DATA FROM 0201_load.R
# ============================================================
if (!exists("dw_data")) stop("dw_data not found. Run 0201_load.R first.")
if (!exists("unicef_countries")) stop("unicef_countries not found. Run 0201_load.R first.")
if (!exists("african_countries")) stop("african_countries not found. Run 0201_load.R first.")
if (!exists("wb_income")) stop("wb_income not found. Run 0201_load.R first.")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Map dimension codes to category labels
map_category <- function(sex, residence, wealth) {
  case_when(
    sex == "_T" & residence == "_T" & wealth == "_T" ~ "All",
    sex == "F" & residence == "_T" & wealth == "_T" ~ "Female",
    sex == "M" & residence == "_T" & wealth == "_T" ~ "Male",
    sex == "_T" & residence == "U" & wealth == "_T" ~ "Urban",
    sex == "_T" & residence == "R" & wealth == "_T" ~ "Rural",
    sex == "_T" & residence == "_T" & wealth == "Q1" ~ "Poorest",
    sex == "_T" & residence == "_T" & wealth == "Q2" ~ "Second",
    sex == "_T" & residence == "_T" & wealth == "Q3" ~ "Middle",
    sex == "_T" & residence == "_T" & wealth == "Q4" ~ "Fourth",
    sex == "_T" & residence == "_T" & wealth == "Q5" ~ "Richest",
    TRUE ~ NA_character_
  )
}

# Extract subject from indicator code
extract_subject <- function(indicator) {
  case_when(
    str_detect(indicator, "READ") ~ "reading",
    str_detect(indicator, "NUM") ~ "numeracy",
    TRUE ~ NA_character_
  )
}

# Check if indicator is weighted
is_weighted_indicator <- function(indicator) {
  str_detect(indicator, "_WTD$") & !str_detect(indicator, "_UWTD$")
}

# Map category to disaggregation type
map_disaggregation <- function(category) {
  case_when(
    category == "All" ~ "All",
    category %in% c("Female", "Male") ~ "Sex",
    category %in% c("Urban", "Rural") ~ "Area",
    category %in% c("Poorest", "Second", "Middle", "Fourth", "Richest") ~ "Wealth",
    TRUE ~ NA_character_
  )
}

# LOESS smoothing function (span = 1)
smooth_loess_span1 <- function(d, x_col, y_col) {
  d <- d[order(d[[x_col]]), ]
  x_seq <- sort(unique(d[[x_col]]))

  d_valid <- d[!is.na(d[[x_col]]) & !is.na(d[[y_col]]), ]

  if (nrow(d_valid) == 0) {
    return(tibble(!!x_col := x_seq, pct_weighted_loess_span1 = NA_real_))
  }

  if (n_distinct(d_valid[[x_col]]) >= 3) {
    fit <- suppressWarnings(loess(as.formula(paste(y_col, "~", x_col)), data = d_valid, span = 1))
    yhat <- predict(fit, newdata = setNames(data.frame(x_seq), x_col))
    return(tibble(!!x_col := x_seq, pct_weighted_loess_span1 = as.numeric(yhat)))
  }

  if (nrow(d_valid) >= 2) {
    approx_y <- approx(d_valid[[x_col]], d_valid[[y_col]], xout = x_seq, rule = 2)$y
    return(tibble(!!x_col := x_seq, pct_weighted_loess_span1 = as.numeric(approx_y)))
  }

  # Single point: repeat value

  tibble(!!x_col := x_seq, pct_weighted_loess_span1 = rep(d_valid[[y_col]][1], length(x_seq)))
}

# ============================================================
# PRE-PROCESSING: Keep only the most recent year per country
# ============================================================
most_recent_year <- dw_data %>%
  group_by(REF_AREA) %>%
  summarise(max_year = max(TIME_PERIOD), .groups = "drop")

dw_data_filtered <- dw_data %>%
  inner_join(most_recent_year, by = "REF_AREA") %>%
  filter(TIME_PERIOD == max_year) %>%
  select(-max_year)

message("Filtered to most recent year per country: ", nrow(dw_data_filtered), " rows")

# ============================================================
# PRE-PROCESSING: Pakistan territories
# ============================================================
# Keep only PAK-PJB (Punjab) and rename it to PAK; drop other territories
dw_data_filtered <- dw_data_filtered %>%
  filter(!REF_AREA %in% c("PAK-BLC", "PAK-KPW", "PAK-SND")) %>%
  mutate(REF_AREA = ifelse(REF_AREA == "PAK-PJB", "PAK", REF_AREA))

message("After Pakistan territory filter: ", nrow(dw_data_filtered), " rows")

# ============================================================
# ENRICHMENT LOOKUP (prepare once, use for both files)
# ============================================================
message("Preparing enrichment lookup...")

enrichment_lookup <- data.frame(iso3 = unique(dw_data_filtered$REF_AREA), stringsAsFactors = FALSE) %>%
  mutate(is_africa = iso3 %in% african_countries) %>%
  left_join(unicef_countries %>% select(iso3, country_name, Region_Code, Region), by = "iso3") %>%
  left_join(wb_income %>% select(iso3, income_level, income_level_code), by = "iso3")

message("Enrichment lookup prepared: ", nrow(enrichment_lookup), " countries")

# ============================================================
# GRADE-LEVEL TRANSFORMATION
# ============================================================
message("Processing grade-level data...")

grade_data <- dw_data_filtered %>%
  filter(
    str_detect(INDICATOR, "_GRD_") & !str_detect(INDICATOR, "_GRD_BND_"),
    str_detect(EDUCATION_LEVEL, "^G[1-8]$")
  ) %>%
  mutate(
    iso3 = REF_AREA,
    category = map_category(SEX, RESIDENCE, WEALTH_QUINTILE),
    subject = extract_subject(INDICATOR),
    grade = as.integer(str_extract(EDUCATION_LEVEL, "\\d+")),
    is_weighted = is_weighted_indicator(INDICATOR),
    obs_value = OBS_VALUE,
    n_obs = N_OBS
  ) %>%
  filter(!is.na(category)) %>%
  select(iso3, category, subject, grade, is_weighted, obs_value, n_obs)

# Pivot to wide format and add grade-specific columns
output_grade <- grade_data %>%
  pivot_wider(
    id_cols = c(iso3, category, subject, grade),
    names_from = is_weighted,
    values_from = c(obs_value, n_obs)
  ) %>%
  rename(
    pct_weighted = obs_value_TRUE,
    pct_unweighted = obs_value_FALSE,
    n_weighted = n_obs_TRUE,
    n_unweighted = n_obs_FALSE
  ) %>%
  mutate(
    disaggregation = map_disaggregation(category)
  ) %>%
  left_join(enrichment_lookup, by = "iso3")

# Add LOESS smoothing (per iso3, category, subject)
message("Adding LOESS smoothing to grade data...")
output_grade <- output_grade %>%
  group_by(iso3, category, subject) %>%
  group_modify(~ {
    sm <- smooth_loess_span1(.x, "grade", "pct_weighted")
    left_join(.x, sm, by = "grade")
  }) %>%
  ungroup() %>%
  select(
    iso3, country_name, disaggregation, category, subject, grade,
    is_africa, income_level, income_level_code, Region_Code, Region,
    n_unweighted, pct_weighted, n_weighted, pct_unweighted,
    pct_weighted_loess_span1
  ) %>%
  arrange(iso3, category, subject, grade)

message("Grade data complete: ", nrow(output_grade), " rows")

# ============================================================
# GRADE-BAND TRANSFORMATION
# ============================================================
message("Processing grade-band data...")

grade_band_labels <- c(
  "GB1" = "Early Primary (1-3)",
  "GB2" = "End of Primary (4-6)",
  "GB3" = "Lower Secondary (7-9)"
)

# Numeric positions for LOESS (midpoints of each band)
grade_band_numeric <- c(
  "Early Primary (1-3)" = 2,
  "End of Primary (4-6)" = 5,
  "Lower Secondary (7-9)" = 8
)

grade_band_data <- dw_data_filtered %>%
  filter(
    str_detect(INDICATOR, "_GRD_BND_"),
    EDUCATION_LEVEL %in% c("GB1", "GB2", "GB3")
  ) %>%
  mutate(
    iso3 = REF_AREA,
    category = map_category(SEX, RESIDENCE, WEALTH_QUINTILE),
    subject = extract_subject(INDICATOR),
    grade_band = grade_band_labels[EDUCATION_LEVEL],
    is_weighted = is_weighted_indicator(INDICATOR),
    obs_value = OBS_VALUE,
    n_obs = N_OBS
  ) %>%
  filter(!is.na(category)) %>%
  select(iso3, category, subject, grade_band, is_weighted, obs_value, n_obs)

# Pivot to wide format and add columns
output_grade_band <- grade_band_data %>%
  pivot_wider(
    id_cols = c(iso3, category, subject, grade_band),
    names_from = is_weighted,
    values_from = c(obs_value, n_obs)
  ) %>%
  rename(
    pct_weighted = obs_value_TRUE,
    pct_unweighted = obs_value_FALSE,
    n_weighted = n_obs_TRUE,
    n_unweighted = n_obs_FALSE
  ) %>%
  mutate(
    disaggregation = map_disaggregation(category),
    grade_band_numeric = grade_band_numeric[as.character(grade_band)]
  ) %>%
  left_join(enrichment_lookup, by = "iso3")

# Add LOESS smoothing (per iso3, category, subject)
message("Adding LOESS smoothing to grade band data...")
output_grade_band <- output_grade_band %>%
  group_by(iso3, category, subject) %>%
  group_modify(~ {
    sm <- smooth_loess_span1(.x, "grade_band_numeric", "pct_weighted")
    left_join(.x, sm, by = "grade_band_numeric")
  }) %>%
  ungroup() %>%
  mutate(grade_band = factor(grade_band, levels = c(
    "Early Primary (1-3)", "End of Primary (4-6)", "Lower Secondary (7-9)"
  ))) %>%
  select(
    iso3, country_name, disaggregation, category, subject, grade_band,
    is_africa, income_level, income_level_code, Region_Code, Region,
    n_unweighted, pct_weighted, n_weighted, pct_unweighted,
    pct_weighted_loess_span1
  ) %>%
  arrange(iso3, category, subject, grade_band)

message("Grade band data complete: ", nrow(output_grade_band), " rows")

# ============================================================
# EXPORT TO GLOBAL ENVIRONMENT
# ============================================================
assign("output_grade", output_grade, envir = .GlobalEnv)
assign("output_grade_band", output_grade_band, envir = .GlobalEnv)

# ============================================================
# SAVE TO CSV FILES
# ============================================================
tablesFolder <- file.path(outputFolder, "0301_tables")
if (!dir.exists(tablesFolder)) dir.create(tablesFolder, recursive = TRUE)

write.csv(output_grade,
  file.path(tablesFolder, "030101_output_grade.csv"),
  row.names = FALSE
)
write.csv(output_grade_band,
  file.path(tablesFolder, "030102_output_grade_band.csv"),
  row.names = FALSE
)

message("=== 0202_transform.R complete ===")
message("  output_grade: ", nrow(output_grade), " rows")
message("  output_grade_band: ", nrow(output_grade_band), " rows")
message("  Files saved to: ", outputFolder)
