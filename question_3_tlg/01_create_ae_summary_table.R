# Create AE summary table

# Load libraries
library(pharmaverseadam)
library(gtsummary)
library(dplyr)
library(tidyverse)

# Load example datasets
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

# data preparation
# Note: some patients don't have any AEs reported, so we need to create a dataset with all subjects using adsl

# length(unique(adsl$USUBJID)) 306

View(adae %>%
  select(USUBJID, ACTARM, AESOC, AETERM, TRTEMFL, SAFFL)
)

# Create dataset with TEAEs
teae <- adae %>%
  filter(SAFFL == "Y") %>% # Filter safety population
  distinct(USUBJID, ACTARM, AESOC, AETERM)

tbl <- adae %>%
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Any SAE"
  )

tbl

# Create dataset with any TEAE indicator
any_teae <- teae %>%
  distinct(USUBJID, ACTARM) %>%
  mutate(any_teae = 1)

all_subj <- adsl %>%
  left_join(any_teae, by = c("USUBJID", "ACTARM")) %>%
  select(USUBJID, ACTARM, any_teae) %>%
  mutate(any_teae = ifelse(is.na(any_teae), 0, any_teae)) %>%
  filter(ACTARM != "Screen Failure")

# ---- Table 1: Any TEAE (TRTEMFL = Y) ----
tbl_trtemfl <- all_subj %>%
  tbl_summary(
    by = ACTARM,
    include = any_teae,
    statistic = all_dichotomous() ~ "{n} ({p}%)",
    label = list(any_teae ~ "Treatment-emergent AEs")
  ) %>%
  modify_header(label ~ "**Primary System Organ Class Reported Term for the Adverse Event**")

soc_lvl <- adae %>%
  distinct(USUBJID, AESOC) %>%
  count(AESOC, name = "total") %>%
  arrange(desc(total)) %>%
  pull(AESOC)

soc <- teae %>%
  mutate(AESOC = factor(AESOC, levels = soc_lvl)) %>%
  pivot_wider(
    names_from = AESOC,
    values_from = AETERM
  )

# ---- Table 2: TEAE by SOC ----

tbl_soc <- soc %>%
  select(-USUBJID) %>%
  tbl_summary(
    by = ACTARM,
    statistic = all_dichotomous() ~ "{n} ({p}%)"
  ) %>%
  modify_header(label ~ "**Primary System Organ Class Reported Term for the Adverse Event**")
