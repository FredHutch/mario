library(plumber)


root <- pr("plumber_functions.R") 
root

root %>% pr_run(host = "0.0.0.0", port = 9876)

