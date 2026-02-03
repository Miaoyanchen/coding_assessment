# Assessment Overview

## Question 1: SDTM DS Domain Creation using {sdtm.oak}

This question demonstrates the creation of an **SDTM Disposition (DS) domain** using R, following CDISC SDTM standards and controlled terminology–driven mappings.

### Objectives

1.  Generate an SDTM-compliant DS domain

2.  Apply controlled terminology (CT) consistently

3.  Implement explicit mapping rules for disposition categories and terms

4.  Demonstrate reproducible, auditable SDTM programming in R

### Dependencies

**Packages:**

-   `sdtm.oak`

-   `pharmaverseraw`

-   `dplyr`

**Input datasets are sourced from `pharmaverse` packages:**

| Dataset                  | Description                         |
|--------------------------|-------------------------------------|
| stdm_ct.csv              | CSV file for controlled terminology |
| `pharmaverseraw::ds_raw` | Subject Disposition Raw Dataset     |
| `pharmaversesdtm::dm`    | Demographics                        |

### Output Files

| File | Description |
|------------------------------------|------------------------------------|
| 01_create_ds_domain.R | R script generates SDTM DS domain |
| 01_create_ds_domain.txt | Log file capturing all console output from the dataset creation process |
| ds_domain.csv | SDTM DS output file generated as csv |

## Question 2: Create an ADaM Subject-Level Analysis Dataset (ADSL) using {admiral}

This question demonstrates the creation of an ADaM Subject-Level Analysis Dataset (ADSL) using the admiral package in R, following CDISC ADaM principles and derivation specifications.

### Objectives

1.  Create an ADSL dataset using SDTM domains as inputs.
2.  Derive subject-level variables according to provided specifications, including:
    -   Treatment start datetime (TRTSDTM, TRTSTMF)
    -   Intent-to-Treat population flag (ITTFL)
    -   Last known alive date (LSTAVLDT)
    -   Age group variables (AGEGR9, AGEGR9N)
3.  Demonstrate correct use of admiral derivation functions, including:
    -   derive_vars_dtm()
    -   derive_vars_merged()
    -   derive_vars_extreme_event()

### Dependencies

**Packages:**

-   `admiral`

-   `stringr`

-   `dplyr`

-   `pharmaversesdtm`

**Data Source**

Input datasets are sourced from the **`pharmaversesdtm`** package:

| Dataset | Description    |
|---------|----------------|
| dm      | Demographics   |
| ex      | Exposure       |
| vs      | Vital Signs    |
| ae      | Adverse Events |
| ds      | Disposition    |

All datasets undergo preprocessing to convert blank character values to `NA` prior to derivation.

### Output Files

| File | Description |
|------------------------------------|------------------------------------|
| `create_adsl.R` | R script for generating ADSL |
| `creat_adsl.txt` | Log file capturing all console output from the dataset creation process |
| `adsl.rda` | Final ADaM ADSL dataset (one record per subject) |

## Question 3: Adverse Event Summary Tables and Visualizations

This task generates **treatment-emergent adverse event (TEAE) summary tables** and **exploratory visualizations** using ADaM-style clinical trial data in R.\

### Objectives

1.  Create a treatment-emergent adverse event (TEAE) summary table

2.  Produce visualizations of adverse events by treatment group

### Dependencies

**Packages:**

-   `pharmaverseadam`

-   `gtsummary`

-   `dplyr`

-   `tidyverse`

**Data source:**

Example datasets from the `pharmaverseadam` package:

-   `adae`: Adverse Events (ADaM-style)

-   `adsl`: Subject-Level Analysis Dataset (used as denominator)

### Output Files

| File | Description |
|------------------------------------|------------------------------------|
| `01_create_ae_summary_tables.R` | R script for generating AE summary table |
| `01_create_ae_summary_tables.txt` | Log file capturing all console output from the table creation process |
| `ae_summary_tables.csv` | CSV file containing the generated AE summary tables |
| `02_create_visualizations.R` | R scripts for generating visualizations |
| `plot1.png` | PNG file containing bar chart of AE severity distribution by treatment |
| `plot2.png` | PNG file containing top 10 most frequent AEs (with 95% CI for incidence rates) |
| `02_create_visualizations.txt` | Log file capturing all console output from the graph creation process |
