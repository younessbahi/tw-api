pacman::p_load(
  plumber, tidyverse, magrittr, operator.tools, chromote, httr, glue, future, rlist, urltools, na.tools
)

source('data/load.R')
source('logic/err_handler.R')
source('logic/funs.R')

#port = Sys.getenv('PORT')
server = plumber::plumb('api.R')
server$run(
  host = "0.0.0.0",
  port = as.numeric(port),
  docs = TRUE
)