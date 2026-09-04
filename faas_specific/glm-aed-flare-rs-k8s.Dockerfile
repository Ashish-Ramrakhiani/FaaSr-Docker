# Layer a Kubernetes-capable FaaSr_py onto the existing GLM-AED-FLAREr image.
# Reuses the base image's GLM/AED/FLAREr, R environment, and FLARE entrypoint;
# only replaces FaaSr_py with a K8s-capable version (+ pyjwt for JWT cluster auth).
# --no-deps avoids re-touching apt-managed deps (e.g. packaging) that lack a pip RECORD;
# main shares FaaSr's existing deps, so only pyjwt is newly required.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG FAASR_INSTALL_REPO=FaaSr/FaaSr-Backend
ARG FAASR_VERSION=main
# Swap the baked-in FLAREr for the canonical public release so the image tracks
# FLARE-forecast/FLAREr (FaaSr integration is on main). dependencies=TRUE pulls any
# newly-required packages; upgrade='never' keeps the base's working package set stable.
ARG FLARER_INSTALL_REPO=FLARE-forecast/FLAREr
ARG FLARER_VERSION=main
ARG GITHUB_PAT
ENV GITHUB_PAT=${GITHUB_PAT}
RUN Rscript -e "library(remotes); install_github(paste0('${FLARER_INSTALL_REPO}', '@', '${FLARER_VERSION}'), dependencies = TRUE, upgrade = 'never')"
RUN pip3 install --no-cache-dir --break-system-packages --force-reinstall --no-deps \
      "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}" \
 && pip3 install --no-cache-dir --break-system-packages pyjwt
