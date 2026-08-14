# Layer a Kubernetes-capable FaaSr_py onto the existing GLM-AED-FLAREr image.
# Reuses the base image's GLM/AED/FLAREr, R environment, and FLARE entrypoint;
# only replaces FaaSr_py with a K8s-capable version (+ pyjwt for JWT cluster auth).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG FAASR_INSTALL_REPO=FaaSr/FaaSr-Backend
ARG FAASR_VERSION=main
RUN pip3 install --no-cache-dir --break-system-packages --force-reinstall \
    "git+https://github.com/${FAASR_INSTALL_REPO}.git@${FAASR_VERSION}" pyjwt
