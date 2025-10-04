# Stage 1: Build FaaSr base image with R support
ARG BASE_IMAGE=rocker/geospatial:4.3.1
FROM $BASE_IMAGE AS build

# Install Python and essential tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for python commands
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Install Python FaaSr dependencies
RUN pip3 install --no-cache-dir \
    boto3 \
    requests \
    jsonschema \
    cryptography

# Install required CRAN packages for FLARE
COPY flare_packages.txt /tmp/required_packages.txt
RUN Rscript -e "\
    packages <- readLines('/tmp/required_packages.txt'); \
    cat('Installing', length(packages), 'CRAN packages...\n'); \
    install.packages(packages, dependencies = TRUE, repos='https://cloud.r-project.org'); \
    cat('CRAN package installation complete.\n')"

# Install FLARE-specific GitHub packages
RUN Rscript -e "library(remotes); \
    install_github('Ashish-Ramrakhiani/FLAREr@v3.1-dev', dependencies = TRUE, force=TRUE)"

RUN Rscript -e "library(remotes); \
    install_github('rqthomas/GLM3r', force=TRUE)"

# Set GLM environment variable
ENV GLM_PATH=GLM3r

# Install supporting forecast packages
RUN Rscript -e "library(remotes); \
    install_github('eco4cast/neon4cast', force=TRUE)"

RUN Rscript -e "library(remotes); \
    install_github('eco4cast/score4cast', force=TRUE)"

RUN Rscript -e "library(remotes); \
    install_github('eco4cast/read4cast', force=TRUE)"

# Stage 2: Add FaaSr Python runtime
FROM build AS runtime

# Set environment variable for platform
ENV FAASR_PLATFORM="github"

# Create runtime directory
RUN mkdir -p /action

# Copy FLARE-specific FaaSr entry point
COPY faasr_entry_flare.py /action/faasr_entry.py

# FaaSr version and installation repo arguments
ARG FAASR_VERSION
ARG FAASR_INSTALL_REPO

# Install FaaSr Python package
RUN pip3 install --no-cache-dir "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}"

# Create directory for R libraries
RUN mkdir -p /tmp/Rlibs
ENV R_LIBS_USER=/tmp/Rlibs

# GitHub Actions specifics
WORKDIR /action
CMD ["python3", "faasr_entry.py"]

# Metadata
LABEL description="FLARE workflow Docker image for FaaSr Python runtime"
LABEL flare.version="v3.1-dev"
LABEL faasr.platform="github"
