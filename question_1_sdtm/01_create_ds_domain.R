# ---- SDTM Disposition (DS) domain ----
sink("01_create_ds_domain.txt", append = FALSE, split = TRUE)

# load packages
library(sdtm.oak)
library(pharmaverseraw)
library(dplyr)

setwd("/Users/itzcmy/Desktop/Genentech")

# input raw data & controlled terminology
ds_raw <- pharmaverseraw::ds_raw
dm <- pharmaversesdtm::dm
study_ct <- read.csv("~/Desktop/Genentech/sdtm_ct.csv")

View(ds_raw)
View(study_ct)

# generate oak id variables
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

# ---- Derive topic variable - DSTERM ----

# if othersp is null then map the value in IT.DSTERM to DSTERM
ds01 <- assign_no_ct(
  raw_dat = condition_add(ds_raw, is.na(OTHERSP)),
  raw_var = "IT.DSTERM",
  tgt_var = "DSTERM",
  id_vars = oak_id_vars()
)

# ---- Map qualifiers, identifiers, and timing variable ----

ds02 <- ds01 %>%
  assign_ct(
    raw_dat = condition_add(ds_raw, is.na(OTHERSP)),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  )


ds03 <- ds02 %>%
  #If IT.DSDECOD = Randomized then map DSCAT = PROTOCOL MILESTONE 
  hardcode_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "PROTOCOL MILESTONE",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  )  %>%
  # ... else DSCAT = DISPOSITION EVENT
  hardcode_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD != "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "DISPOSITION EVENT",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  ) %>%
  # Map DSCAT using hardcode_ct, raw_var=OTHERSP
  # If OTHERSP is not null then map DSCAT = OTHER EVENT
  hardcode_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSCAT",
    tgt_val = "OTHER EVENT",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  )

# If OTHERSP is not null then map the value in OTHERSP to DSDECOD and also to DSTERM
ds04 <- ds03 %>% 
  # If OTHERSP is null then map the value in IT.DSDECOD to DSDECOD 
  assign_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  ) %>%
  # If OTHERSP is null then map the value in IT.DSDECOD to DSTERM
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )


ds05 <- ds04 %>%
  # Map the value in IT.DSSDAT to DSSTDTC in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("d-m-y"),
    id_vars = oak_id_vars()
  ) %>%
  # Map DSDTC using assign_datetime, raw_var=c("DSDTCOL", "DSTMCOL") in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("d-m-y", "H:M"),
    id_vars = oak_id_vars()
  )  

# View(ds05)

ds06 <- ds05 %>% 
  # Map VISIT from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISITNUM from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  )

# Final DS domain dataset creation ----

ds07 <- ds06 %>%
  # Derive standard variables
  mutate(
    STUDYID = ds_raw$STUDY,
    DOMAIN = "DS",
    USUBJID = paste0("01", "-", ds_raw$PATNUM)
  ) %>%
  arrange(STUDYID,USUBJID) %>%
  # Derive DSSEQ
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("STUDYID", "USUBJID") 
  ) %>%
  # Derive DSSTDY
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    merge_key = c("USUBJID"),
    tgdt = "DSSTDTC", # Date/Time of Start of Disposition Event
    refdt = "RFXSTDTC", # Date/Time of First Study Treatment
    study_day_var = "DSSTDY" # Study day of start of disposition event
  ) %>%
  # Rearrange and select variables
  dplyr::select("STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM", "DSDECOD", "DSCAT", "VISITNUM", "VISIT", "DSDTC", "DSSTDTC", "DSSTDY")

View(ds07)

print("Writing DS domain to CSV file...")
write.csv(ds07, file = "ds_domain.csv", row.names = FALSE)

sink()
