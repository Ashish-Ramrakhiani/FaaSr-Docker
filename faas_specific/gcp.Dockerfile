# BASE_IMAGE is the full name of the base image e.g. faasr/base-tidyverse:1.1.2
ARG BASE_IMAGE
# Start from specified base image
FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from - this must match a tag in the GitHub repository e.g. 1.1.2
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the name of the user's GitHub repository to install FaaSr from e.g. janedoe/FaaSr-Package-dev
ARG FAASR_INSTALL_REPO

# Install FaaSr from specified repo and tag
RUN Rscript -e "args <- commandArgs(trailingOnly=TRUE); library(devtools); install_github(paste0(args[1],'@',args[2]),force=TRUE)" $FAASR_INSTALL_REPO $FAASR_VERSION

# GCP Cloud Run Jobs specifics
WORKDIR /action

# Set execute permissions  
RUN chmod +x /action/faasr_start_invoke_gcp.R

# Entry point for GCP Cloud Run Jobs - direct R execution with command line args
ENTRYPOINT ["Rscript", "/action/faasr_start_invoke_gcp.R"]