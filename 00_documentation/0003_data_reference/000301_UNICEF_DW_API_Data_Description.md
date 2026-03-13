# UNICEF Data Warehouse API – Learning Gradient Data Description

**Purpose**: This document describes the **data returned by the UNICEF Data Warehouse API** for the Learning Gradient dataflow. This repo consumes that payload by calling the API via `rsdmx::readSDMX`.

---

## 1. Dataflow

**Dataflow name:**  
EDUCATION_LG – EDU – Learning Gradient (MICS FLS)

The API serves one dataset per dataflow. Each row is one indicator observation for a given geography, time, and dimension breakdown.

---

## 2. Indicators (returned by the API)

### By grade (progression step)

| Code | Description |
|------|-------------|
| ED_LG_READ_GRD_WTD | Reading, by grade, weighted |
| ED_LG_READ_GRD_UWTD | Reading, by grade, unweighted |
| ED_LG_NUM_GRD_WTD | Numeracy, by grade, weighted |
| ED_LG_NUM_GRD_UWTD | Numeracy, by grade, unweighted |

### By grade band

| Code | Description |
|------|-------------|
| ED_LG_READ_GRD_BND_WTD | Reading, by grade band, weighted |
| ED_LG_READ_GRD_BND_UWTD | Reading, by grade band, unweighted |
| ED_LG_NUM_GRD_BND_WTD | Numeracy, by grade band, weighted |
| ED_LG_NUM_GRD_BND_UWTD | Numeracy, by grade band, unweighted |

Weighted and unweighted are separate indicator codes; the API returns one row per (indicator, dimensions, time).

---

## 3. Response structure (same as DW CSV layout)

The API returns data in a **tabular layout** (or equivalent JSON/CSV with the same column names and semantics). When the response is CSV, it matches the following layout. The API may include additional columns with human-readable labels (e.g. Geographic area, Indicator, Sex, Residence, Wealth Quintile, Education Level, Unit multiplier, Unit of measure) alongside the dimension codes.

**Columns:**

| Column | Type / Description |
|--------|---------------------|
| DATAFLOW | Dataflow identifier (e.g. `EDUCATION_LG – EDU – Learning Gradient (MICS FLS)`) |
| REF_AREA | Reference area – country ISO3 code (e.g. AFG, NGA, PAK) |
| Geographic area | Human-readable area name (e.g. Pakistan) – optional |
| INDICATOR | Indicator code (e.g. ED_LG_READ_GRD_WTD) |
| Indicator | Human-readable indicator label (optional) |
| SEX | Sex dimension (F, M, _T) |
| Sex | Human-readable sex label (e.g. Total) – optional |
| RESIDENCE | Residence dimension (R, U, _T) |
| Residence | Human-readable residence label (e.g. Total) – optional |
| WEALTH_QUINTILE | Wealth quintile (_T, Q1–Q5) |
| Wealth Quintile | Human-readable wealth label (e.g. Total) – optional |
| EDUCATION_LEVEL | Grade or grade band (_T, G1–G15, GB1–GB3) |
| Education Level | Human-readable education label (e.g. Total) – optional |
| UNIT_MULTIPLIER | Unit multiplier (e.g. 0 = Units) |
| Unit multiplier | Human-readable unit multiplier label – optional |
| UNIT_MEASURE | Unit of measure (e.g. PCNT for %) |
| Unit of measure | Human-readable unit label (e.g. %) – optional |
| TIME_PERIOD | Time period – survey year (integer) |
| OBS_VALUE | Observed value – proficiency as percentage 0–100 |
| OBS_FOOTNOTE | Footnote or methodology note (e.g. geographic coverage caveats); may be empty |
| N_OBS | Observation count (sample size for the cell) |
| DATA_SOURCE | Source survey (e.g. "Multiple Indicator Cluster Surveys Round 6 (2017-2025)") |

**Encoding**: UTF-8 when delivered as CSV.

---

## 4. Dimension values (same as DW format)

### SEX

| Code | Meaning |
|------|---------|
| F | Female |
| M | Male |
| _T | Total (all) |

### RESIDENCE

| Code | Meaning |
|------|---------|
| _T | Total (urban + rural) |
| R | Rural |
| U | Urban |

### WEALTH_QUINTILE

| Code | Meaning |
|------|---------|
| _T | Total (all quintiles) |
| Q1 | Poorest |
| Q2 | Second |
| Q3 | Middle |
| Q4 | Fourth |
| Q5 | Richest |

### EDUCATION_LEVEL (grade or grade band)

| Code | Meaning |
|------|---------|
| _T | Total (all grades) |
| G1 … G8 | Grade 1 … Grade 8 |
| G9 … G15 | Grade 9 … Grade 15 |
| GB1 | Grade band 1 (Early Primary 1–3) |
| GB2 | Grade band 2 (End of Primary 4–6) |
| GB3 | Grade band 3 (Lower Secondary 7–9) |

---

## 5. Content semantics

- **OBS_VALUE**: Proficiency rate as percentage 0–100 (same as source proportion × 100). Raw aggregated means only; no LOESS, no minimum-n filtering at source.
- **OBS_FOOTNOTE**: Optional footnote with methodology or coverage caveats (e.g. "Pakistan is represented by Punjab Province only, which accounts for roughly half of the national population and is used here as a proxy for national learning patterns."). May be empty for many rows.
- **N_OBS**: For weighted indicators, the subject-specific count (reading or numeracy); for unweighted indicators, the total unweighted N for the cell.
- **One row per** (DATAFLOW, REF_AREA, INDICATOR, SEX, RESIDENCE, WEALTH_QUINTILE, EDUCATION_LEVEL, TIME_PERIOD). Each combination has a single OBS_VALUE, N_OBS, and optionally OBS_FOOTNOTE.
- **Grade vs grade-band**: Rows with INDICATOR in `ED_LG_*_GRD_*` use EDUCATION_LEVEL as grade (G1–G15, _T). Rows with INDICATOR in `ED_LG_*_GRD_BND_*` use EDUCATION_LEVEL as grade band (GB1–GB3, _T).

---

## 6. Use in this repo

- **0201_load.R** loads this structure from the API via `readSDMX(dw_api_url)`. Set `dw_api_url` in `project_config.R`.
- **0202_transform.R** converts this 14-column layout back into two output tables (grade-level and grade-band-level), enriches with country metadata, applies LOESS smoothing, and writes final tables to `03_output/0301_tables/`.
- **0203_produce_charts.R** reads the output tables and exports PNG charts to `03_output/0302_figures/`.

For the full export specification (including source→DW mapping), see **`prev_docs/UNICEF_DW_Learning_Gradient_CSV_Format.md`**.
