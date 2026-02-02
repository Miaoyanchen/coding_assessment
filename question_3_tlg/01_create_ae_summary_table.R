# Create AE summary table

# create log
sink("01_create_ae_summary_table.txt")

# Load libraries
library(pharmaverseadam)
library(gtsummary)
library(dplyr)
library(tidyverse)

# Load example datasets
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

# Note: some patients don't have any AEs reported, so we need to use adsl as denominator

# length(unique(adsl$USUBJID)) 306

View(adae %>% select(USUBJID, ACTARM, AESOC, AETERM, TRTEMFL, SAFFL))

# Create dataset with TEAEs
teae <- adae %>%
  filter(SAFFL == "Y") # Filter safety population

tbl <- teae %>%
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Primary System Organ Class Reported Term for the Adverse Event"
  )

# Save as HTML

tbl %>%
  as_flex_table() %>%
  flextable::save_as_html(path = "teae_summary_table.html")

sink()