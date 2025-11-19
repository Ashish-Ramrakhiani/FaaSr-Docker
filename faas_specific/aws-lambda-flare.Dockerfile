ARG BASE_IMAGE=rocker/geospatial:4.3.1

FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the GitHub repository to install FaaSr from
ARG FAASR_INSTALL_REPO

# Install AWS Lambda Runtime Interface Client and other dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgd3 \
    libgd-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install AWS Lambda Runtime Interface Client (required for Lambda)
RUN pip3 install --no-cache-dir awslambdaric

# Install FaaSr Python package
RUN pip3 install --no-cache-dir "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}"

# Copy package list and install missing CRAN packages
COPY flare_packages.txt /tmp/required_packages.txt
RUN Rscript -e "packages <- readLines('/tmp/required_packages.txt'); install.packages(packages, dependencies = TRUE)"

# Install FLARE-specific packages
RUN Rscript -e "library(remotes); install_github('Ashish-Ramrakhiani/FLAREr@v3.1-dev', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('rqthomas/GLM3r', dependencies = TRUE)"

# Set GLM environment variable
ENV GLM_PATH=GLM3r

# Install supporting forecast packages
RUN Rscript -e "library(remotes); install_github('eco4cast/neon4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/score4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/read4cast', dependencies = TRUE)"

# Set environment variable for platform
ENV FAASR_PLATFORM="lambda"

# Lambda requires workdir at /var/task
WORKDIR /var/task

# Copy FLARE-specific FaaSr entry point for Lambda
COPY faasr_entry_flare.py ./faasr_entry.py

# Lambda entry point (required)
ENTRYPOINT ["python3", "-m", "awslambdaric"]

# Lambda handler (required format: filename.function_name)
CMD ["faasr_entry.handler"]
