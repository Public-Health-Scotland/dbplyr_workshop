# Install libraries (if required)
install.packages("tidyverse") # Core Tidyverse includes many packages
install.packages("odbc") # Used for connecting to databases
install.packages("dbplyr") # Needs to be installed

#  Load Libraries
library(odbc)

# Create a connection to SMRA
smra_conn <- dbConnect(
  drv = odbc(),
  dsn = "SMRA",
  uid = Sys.getenv("USER"),
  pwd = rstudioapi::askForPassword("SMRA Password:")
)
