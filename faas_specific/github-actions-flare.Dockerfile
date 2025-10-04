# BASE_IMAGE is the full name of the base image e.g. rocker/geospatial:4.3.1
ARG BASE_IMAGE
FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the GitHub repository to install FaaSr from
ARG FAASR_INSTALL_REPO

# Install Python (minimal - only what FaaSr Python needs)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install FaaSr Python package
RUN pip3 install --no-cache-dir "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}"

# Copy package list and install missing CRAN packages
COPY flare_packages.txt /tmp/required_packages.txt
RUN Rscript -e "packages <- readLines('/tmp/required_packages.txt'); install.packages(packages, dependencies = TRUE)"

# Install FLARE-specific packages (match old syntax)
RUN Rscript -e "library(remotes); install_github('Ashish-Ramrakhiani/FLAREr@v3.1-dev', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('rqthomas/GLM3r')"

# Set GLM environment variable
ENV GLM_PATH=GLM3r

# Install supporting forecast packages (no dependencies flag like old version)
RUN Rscript -e "library(remotes); install_github('eco4cast/neon4cast')"
RUN Rscript -e "library(remotes); install_github('eco4cast/score4cast')"
RUN Rscript -e "library(remotes); install_github('eco4cast/read4cast')"

# Set environment variable for platform
ENV FAASR_PLATFORM="github"

# Create runtime directory
RUN mkdir -p /action

# Copy FLARE-specific FaaSr entry point
COPY faasr_entry_flare.py /action/faasr_entry.py

# GitHub Actions specifics
WORKDIR /action
CMD ["python3", "faasr_entry.py"]
