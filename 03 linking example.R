# Doing more complicated extracts

# Previewing the table / object
# Use `colnames()` to just print the variable names

# Without dbplyr (just odbc)
odbcPreviewObject(
  smra_conn,
  rowLimit = 10,
  table = "ANALYSIS.GRO_DEATHS_C"
) |>
  as_tibble() 

# If we just run a dbplyr query it will give us a sample of the data
tbl(
  smra_conn,
  dbplyr::in_schema("ANALYSIS", "GRO_DEATHS_C")
)

# Use `colnames()` to just print a list of the columns
tbl(
  smra_conn,
  dbplyr::in_schema("ANALYSIS", "GRO_DEATHS_C")
) |>
  colnames()

# Set up a deaths extract
deaths_query <- tbl(smra_conn, in_schema("ANALYSIS", "GRO_DEATHS_C")) |>
  select(LINK_NO, DATE_OF_DEATH) |>
  filter(DATE_OF_DEATH >= To_date("2023-06-01", "YYYY-MM-DD"))

# See a sample of the data
deaths_query

# See what the SQL looks like
deaths_query |>
  show_query()

# Set up a simple SMR01 extract (similar to the previous example)
simple_smr01_query <- tbl(smra_conn, "SMR01_PI") |>
  select(
    LINK_NO,
    ADMISSION_DATE,
    DISCHARGE_DATE,
    HBRES_KEYDATE,
    AGE_IN_YEARS
  ) |>
  filter(DISCHARGE_DATE >= To_date("2023-07-01", "YYYY-MM-DD"))

# Do a link using dplyr joins
# Alternative is (getting) complicated SQL
# Or extract separately and then join which is to be avoided!
linked_1_query <- simple_smr01_query |>
  inner_join(deaths_query, by = "LINK_NO")

# We could probably write some slightly better SQL but not as easily!
linked_1_query |> show_query()

# Do the extract
linked_1_extract <- collect(linked_1_query)

# The larger the extracts the faster this method is compared to joining separate
# extracts

# We can keep adding more manipulation code and create a complicated SQL query
# using only dbplyr.
library(lubridate)
library(janitor)

smr01_deaths <- simple_smr01_query |>
  # Lothian
  filter(HBRES_KEYDATE == "S08000024") |>
  filter(AGE_IN_YEARS >= 18) |>
  mutate(dis_month = month(DISCHARGE_DATE)) |>
  inner_join(deaths_query, by = "LINK_NO") |>
  clean_names() |>
  show_query() |>
  collect()

# Even group and do aggregation
smr01_lothian <- simple_smr01_query |>
  # Lothian
  filter(HBRES_KEYDATE == "S08000024") |>
  filter(AGE_IN_YEARS >= 18) |>
  mutate(age_gpr = case_when(
    between(AGE_IN_YEARS, 18, 64) ~ "18-64",
    between(AGE_IN_YEARS, 65, 89) ~ "65-89",
    AGE_IN_YEARS >= 90 ~ "90+"
  )) |>
  mutate(dis_month = month(DISCHARGE_DATE)) |>
  group_by(age_gpr, dis_month) |>
  summarise(
    admissions = n(),
    patients = n_distinct(LINK_NO),
    .groups = "drop"
  ) |>
  show_query() |>
  collect()


