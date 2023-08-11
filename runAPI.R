library(plumber)
library(mario)

root <- pr("inst/extdata/plumber.R") 
root

root %>% pr_run(host = "0.0.0.0", port = 9876)

