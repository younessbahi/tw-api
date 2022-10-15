library(plumber)
library(tidyverse)
library(magrittr)
library(operator.tools)
library(chromote)
require(httr)
library(glue)
library(future)
library(rlist)
library(urltools)
library(na.tools)

source('data/load.R')
source('logic/err_handler.R')
source('logic/funs.R')

#port = Sys.getenv('PORT')
port = 8080 #testing/dev
server = plumber::plumb('api.R')
server$run(
  host = "0.0.0.0",
  port = as.numeric(port),
  docs = TRUE
)