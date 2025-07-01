# Build FLARE-FaaSr container using existing FLARE base + FaaSr components
FROM rocker/geospatial:4.4

# Install system dependencies
RUN apt-get update && apt-get -y install libgd-dev libmagick++-dev git curl

# Install R packages for FLARE (keep your existing installation)
RUN install2.r devtools remotes arrow renv RNetCDF forecast imputeTS ncdf4 scoringRules tidybayes tidync udunits2 RcppRoll
RUN install2.r bench contentid yaml RCurl here feasts gsheet usethis tidymodels xgboost rMR
RUN sleep 180
RUN R -e "devtools::install_github('FLARE-forecast/FLAREr', ref = 'v3.0.3')"
RUN sleep 180
RUN R -e "devtools::install_github('cboettig/aws.s3')"
RUN sleep 180
RUN R -e "devtools::install_github('eco4cast/score4cast')"
RUN sleep 180
RUN R -e "devtools::install_github('eco4cast/neon4cast')"
RUN sleep 180
RUN R -e "devtools::install_github('rqthomas/glmtools')"
RUN sleep 180
RUN R -e "devtools::install_github('rqthomas/GLM3r')"

# Install specific tagged version of FaaSr
RUN sleep 180
RUN R -e "devtools::install_github('FaaSr/FaaSr-package', ref = 'v1.2.0')"

# Create the /action directory that FaaSr expects
RUN mkdir -p /action

# Download FaaSr entry point files directly from FaaSr-Docker repo
ADD https://raw.githubusercontent.com/FaaSr/FaaSr-Docker/refs/heads/main/base/faasr_start_invoke_github-actions.R /action/
ADD https://raw.githubusercontent.com/FaaSr/FaaSr-Docker/refs/heads/main/base/faasr_start_invoke_helper.R /action/

# Download FaaSr JSON schema
ADD https://raw.githubusercontent.com/FaaSr/FaaSr-package/refs/heads/main/schema/FaaSr.schema.json /action/

# Set working directory
WORKDIR /action

# Metadata
LABEL maintainer="Ashish Ramrakhiani <ramrakha@oregonstate.edu>"
LABEL description="Docker image for FLARE-FaaSr integration"
