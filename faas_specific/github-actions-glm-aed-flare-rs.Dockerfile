# BASE_IMAGE is the full name of the base image e.g. rocker/geospatial:4.4.2
ARG BASE_IMAGE
FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the GitHub repository to install FaaSr from
ARG FAASR_INSTALL_REPO
# FLARER_INSTALL_REPO is the GitHub repository to install FLAREr from
ARG FLARER_INSTALL_REPO
# FLARER_VERSION is the FLAREr branch / tag / commit
ARG FLARER_VERSION
# GITHUB_PAT to authenticate install_github calls and avoid 60/hr anonymous rate limit
ARG GITHUB_PAT
ENV GITHUB_PAT=${GITHUB_PAT}

# System libs: python for the FaaSr entry, libgd for plotting,
# libnetcdf + libgfortran for the prebuilt GLM binary.
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgd3 \
    libgd-dev \
    libnetcdf19t64 \
    libgfortran5 \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Drop in the prebuilt GLM binary that matches the Ubuntu 24.04 base.
RUN mkdir -p /opt/glm \
    && curl -sL https://raw.githubusercontent.com/rqthomas/GLM_devcontainer/main/binaries/ubuntu/24.04/glm \
       -o /opt/glm/glm \
    && chmod +x /opt/glm/glm
ENV GLM_PATH=/opt/glm/glm

RUN pip3 install --no-cache-dir "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}"

COPY glm_aed_flare_rs_packages.txt /tmp/required_packages.txt
RUN Rscript -e "packages <- readLines('/tmp/required_packages.txt'); install.packages(packages, dependencies = TRUE)"

RUN Rscript -e "library(remotes); install_github(paste0('${FLARER_INSTALL_REPO}', '@', '${FLARER_VERSION}'), dependencies = TRUE)"

RUN Rscript -e "library(remotes); install_github('eco4cast/neon4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/score4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/read4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('LTREB-reservoirs/vera4castHelpers', dependencies = TRUE)"

ENV FAASR_PLATFORM="github"

RUN mkdir -p /action

COPY faasr_entry_flare.py /action/faasr_entry.py

WORKDIR /action
CMD ["python3", "faasr_entry.py"]
