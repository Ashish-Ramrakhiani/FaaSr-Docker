#!/usr/local/bin/Rscript
#' @title Set an entrypoint / Source R codes - for Slurm
#' @description When the docker containers run in Slurm, they start this R code first.
#'              This is necessary because it sets library("FaaSr") so that users code can use the FaaSr library and
#'              user's functions would be downloaded from the user's github repository and then they are sourced by
#'              this function. 
#' @param JSON payload is passed as an environment variable FAASR_PAYLOAD when the docker container starts.
library("jsonlite")
library("httr")
library("FaaSr")
source("faasr_start_invoke_helper.R")

# Get arguments - Slurm passes payload via environment variable
.faasr_payload <- Sys.getenv("FAASR_PAYLOAD", unset = NA)

if (is.na(.faasr_payload)) {
  # Fallback to command line arguments if env var not found 
  .faasr <- commandArgs(TRUE)
} else {
  .faasr <- .faasr_payload
}

# start FaaSr
.faasr <- FaaSr::faasr_start(.faasr)
if (.faasr[1]=="abort-on-multiple-invocation"){
  q("no")
}

# Download the dependencies
funcname <- .faasr$FunctionList[[.faasr$FunctionInvoke]]$FunctionName
faasr_dependency_install(.faasr, funcname)

# Execute User function
.faasr <- FaaSr::faasr_run_user_function(.faasr)

# Trigger the next functions
FaaSr::faasr_trigger(.faasr)

# Leave logs - Enhanced for Slurm environment
msg_1 <- paste0('{\"faasr\":\"Finished execution of User Function ',.faasr$FunctionInvoke,'\"}', "\n")
cat(msg_1)
result <- faasr_log(msg_1)

msg_2 <- paste0('{\"faasr\":\"With Action Invocation ID is ',.faasr$InvocationID,'\"}', "\n")
cat(msg_2)
result <- faasr_log(msg_2)

# Slurm-specific logging - include job information if available
if (!is.na(Sys.getenv("SLURM_JOB_ID", unset = NA))) {
  msg_3 <- paste0('{\"faasr\":\"SLURM Job ID: ',Sys.getenv("SLURM_JOB_ID"),'\"}', "\n")
  cat(msg_3)
  result <- faasr_log(msg_3)
}

if (!is.na(Sys.getenv("SLURM_NODELIST", unset = NA))) {
  msg_4 <- paste0('{\"faasr\":\"SLURM Node(s): ',Sys.getenv("SLURM_NODELIST"),'\"}', "\n")
  cat(msg_4)
  result <- faasr_log(msg_4)
}