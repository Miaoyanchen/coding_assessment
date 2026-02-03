sink("02_create_visualizations.txt", type = c("output", "message"))

library(pharmaverseadam)
library(ggplot2)
library(dplyr)
library(tidyverse)

adae <- pharmaverseadam::adae

# ---- Plot 1 ----
# AE severity distribution by treatment (bar chart or heatmap). 
# AE Severity is captured in the AESEV variable in pharmaverseadam::adae dataset.

ggplot(adae, aes(x = ACTARM, fill = AESEV)) +
  geom_bar(stat = "count", position = "stack") +
  labs(
    title = "AE Severity Distribution by Treatment",
    x = "Treatment Group",
    y = "Count of AEs",
    fill = "AE Severity"
  ) +
  theme_bw() +
  scale_fill_manual(
    values = c(
      "MILD" = "#A6CEE3",
      "MODERATE" = "#1F78B4",
      "SEVERE" = "#B2182B"
    )
  ) +
  theme(
    legend.position = "right"
  )


# ---- Plot 2 ----
# Top 10 most frequent AEs (with 95% CI for incidence rates). 
# AEs are captured in the AETERM variable in the pharmaverseadam::adae dataset.

# total number of subjects in safety population
n_subj <- adae %>%
  filter(SAFFL == "Y") %>%
  distinct(USUBJID) %>%
  nrow()

# calculate incidence rates and Clopper–Pearson CI
ae_10 <- adae %>%
  distinct(USUBJID, AETERM) %>%
  count(AETERM, name = "total") %>%
  arrange(desc(total)) %>%
  slice_head(n = 10) %>%
  mutate(n_subj = n_subj)

plot_df <- ae_10 %>%
  rowwise() %>%
  mutate(
    ci = list(binom.test(total, n_subj, conf.level = 0.95)$conf.int),
    incidence_pct = total / n_subj,
    lower_pct = ci[1],
    upper_pct = ci[2]
  ) 

plot_df <- plot_df %>%
  mutate(AETERM = factor(AETERM, levels = AETERM)) %>%
  arrange(incidence_pct)


ggplot(plot_df, aes(x = incidence_pct, y = AETERM)) +
  geom_point(size = 2, color = "steelblue") +
  geom_errorbar(
    aes(xmin = lower_pct, xmax = upper_pct),
    width = 0.2,
    color = "steelblue"
  ) +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = "n = 225, 95% Clopper-Pearson CI",
    x = "Percentage of Patients(%)",
    y = "AEs",
  ) +
  theme_bw()


sink()
