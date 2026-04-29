# BASE_IMAGE is the full name of the base image e.g. rocker/geospatial:4.3.1
ARG BASE_IMAGE
FROM $BASE_IMAGE

# FAASR_VERSION FaaSr version to install from
ARG FAASR_VERSION
# FAASR_INSTALL_REPO is the GitHub repository to install FaaSr from
ARG FAASR_INSTALL_REPO

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgd3 \
    libgd-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}"

COPY glm_aed_flare_rs_packages.txt /tmp/required_packages.txt
RUN Rscript -e "packages <- readLines('/tmp/required_packages.txt'); install.packages(packages, dependencies = TRUE)"

RUN Rscript -e "library(remotes); install_github('Ashish-Ramrakhiani/FLAREr@v3.1-dev', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('rqthomas/GLM3r', dependencies = TRUE)"

ENV GLM_PATH=GLM3r

RUN Rscript -e "library(remotes); install_github('eco4cast/neon4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/score4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('eco4cast/read4cast', dependencies = TRUE)"
RUN Rscript -e "library(remotes); install_github('LTREB-reservoirs/vera4castHelpers', dependencies = TRUE)"

ENV FAASR_PLATFORM="github"

RUN mkdir -p /action

COPY faasr_entry_flare.py /action/faasr_entry.py

WORKDIR /action
CMD ["python3", "faasr_entry.py"]
