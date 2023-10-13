library(dplyr) # We only need to load dplyr for this to work
library(dbplyr) # Sometimes we might need a specific dbplyr function...

# Some SQL to do a simple extract
sql <- paste(
  "SELECT LINK_NO, ADMISSION_DATE, DISCHARGE_DATE",
  "FROM ANALYSIS.SMR01_PI",
  "WHERE DISCHARGE_DATE >= To_date('2023-06-01', 'YYYY-MM-DD')"
)

# Do the extract using the usual dbGetQuery (from odbc)
simple_1_extract <- dbGetQuery(smra_conn, sql)

# Use dbplyr
# Note we have to use upper case variable names
simple_2_query <- tbl(smra_conn, "SMR01_PI") %>%
  select(LINK_NO, ADMISSION_DATE, DISCHARGE_DATE) %>%
  filter(DISCHARGE_DATE >= To_date("2019-06-01", "YYYY-MM-DD"))

# This will print the 'translated' SQL for us to see
simple_2_query %>% show_query()

# Up until this point we haven't actually got the data
simple_2_extract <- collect(simple_2_query)

# Let's make sure the extracts are really identical
waldo::compare(
  simple_1_extract,
  simple_2_extract
)
