# This is an option for extracting CIS level data directly
# We need the data to be sorted and to take the first and last for 
# each CIS - this is what causes issues.

cis_data <- tbl(smra_conn, "SMR01_PI") |>
  # Use a semi_join to select only episode which are part of
  # a CIS which has a discharge date after xxx
  # This ensures we get all the episodes from any relevant CISs
  semi_join(
    # Do any required filtering here
    # e.g. HB / HSCP diag codes etc.
    tbl(smra_conn, "SMR01_PI") |>
      filter(DISCHARGE_DATE >= To_date("2023-07-01", "YYYY-MM-DD")),
    by = c("LINK_NO", "CIS_MARKER")
  ) |>
  # Use window_order + mutate + distinct
  # This replicates arrange + summarise (which won't work for first/last)
  group_by(LINK_NO, CIS_MARKER) |>
  # Window order must come immediately before mutate
  window_order(
    LINK_NO,
    CIS_MARKER,
    ADMISSION_DATE,
    DISCHARGE_DATE,
    ADMISSION,
    DISCHARGE,
    URI
  ) |>
  mutate(
    cis_adm = first(ADMISSION_DATE),
    cis_dis = last(DISCHARGE_DATE),
    cis_adm_type = first(ADMISSION_TYPE)
  ) |>
  ungroup() |>
  # Now all episodes should have the same data (because of the mutate)
  # We can use distinct to reduce to one row
  distinct(LINK_NO, CIS_MARKER, .keep_all = T) |>
  # Now we have the rows we want, select only needed variables
  # You might also want to do additional filtering here:
  # e.g. Only CIS stays which began with an emergency adm_type
  select(
    LINK_NO,
    CIS_MARKER,
    cis_adm,
    cis_dis,
    cis_adm_type
  ) |>
  # Tidy the variable names (not needed, and could have gone anywhere)
  clean_names() |>
  show_query() |>
  collect()
