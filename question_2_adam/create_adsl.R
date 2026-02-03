# ---- ADaM ADSL Dataset Creation'

sink("create_adsl.txt", append = FALSE, split = TRUE)

# Load libraries
library(dplyr)
library(stringr)
library(admiral)
library(pharmaversesdtm)

# Load source datasets
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

# Convert blank character values to NA
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)

# Using DM as the basis for ADSL

adsl <- dm %>%
  select(-DOMAIN)

# Age grouping into categorical variable AGEGR9 and numeric variable AGEGR9N

agegr9_lookup <- exprs(
  ~condition,           ~AGEGR9,
  AGE < 18,               "<18",
  between(AGE, 18, 50), "18-50",
  AGE > 50,               ">50",
  is.na(AGE),         "Missing"
)

adsl <- adsl %>%
  # Create categorical age groups
  derive_vars_cat(
    definition = agegr9_lookup
  ) %>%
  # Create numerical categories
  mutate(
    AGEGR9N = case_when(
      AGEGR9 == "<18" ~ 1,
      AGEGR9 == "18-50" ~ 2,
      AGEGR9 == ">50" ~ 3,
      AGEGR9 == "Missing" ~ NA_real_
    )
  )


# Derive treatment start date-time (TRTSDTM) and time flag (TRTSTMF) from EX

ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
    time_imputation = "first", # start with 00:00:00 if time is missing,
    flag_imputation = "time"
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last",
    flag_imputation = "time"
  )

# View(ex_ext)

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  )

View(adsl %>% select(USUBJID, starts_with("TRT")))  

# Flag identifying patients who have been randomized (ITTFL)
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = dm,
    by = exprs(STUDYID, USUBJID),
    new_var = ITTFL,
    false_value = "N",
    missing_value = "N",
    condition = !is.na(ARM)
  )

# Set to the last date patient has documented clinical data

# Check for last known live date 
adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    # last complete date of vital assessment with a valid test result 
    # ([VS.VSSTRESN] and [VS.VSSTRESC] not both missing) and datepart of
    # [VS.VSDTC] not missing.
    events = list(
      event(
        dataset_name = "vs",
        order = exprs(VSDTC, VSSEQ),
        condition = !is.na(VSDTC) & !(is.na(VSSTRESN) & is.na(VSSTRESC)),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(VSDTC, highest_imputation = "M"),
          seq = VSSEQ
        )
      ),
      #  last complete onset date of AEs (datepart of Start Date/Time of Adverse Event [AE.AESTDTC])
      event(
        dataset_name = "ae",
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(AESTDTC, highest_imputation = "M"),
          seq = AESEQ
        )
      ),
      #last complete disposition date (datepart of Start Date/Time of Disposition Event [DS.DSSTDTC]).
      event(
        dataset_name = "ds",
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(DSSTDTC, highest_imputation = "M"),
          seq = DSSEQ
        )
      ),
      # last date of treatment administration where patient received a valid
      # dose (datepart of Datetime of Last Exposure to Treatment
      # [ADSL.TRTEDTM]).
      event(
        dataset_name = "adsl",
        order = exprs(TRTEDTM),
        condition = !is.na(TRTEDTM),
        set_values_to = exprs(
          LSTALVDT = as.Date(TRTEDTM),
          seq = 0
        )
      )
    ),
    # Set to the max of Vitals Complete, AE onset complete, disposition complete, treatment complete)
    source_datasets = list(ae = ae, vs = vs, ds = ds, adsl = adsl),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, seq, event_nr),
    mode = "last", # take max
    new_vars = exprs(LSTALVDT)
  )

save(adsl, file = file.path("adsl.rda"))

sink()