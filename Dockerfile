# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

FROM eclipse-temurin:21-jdk-noble@sha256:71f2d18eea2e834fad8b6b8d5c7ae6effca37b97f3a3da2df5de932ee540c060


# Make variable available to the build stage
ARG BASE_IMAGE

# Install:
# - screen for running the console in a headless server
# - tini for handling signals and reaping zombie processes
# - libjemalloc2 for debugging memory issues
RUN apt-get update \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y screen tini libjemalloc2 \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

COPY --from=grpcurl /bin/grpcurl /bin/grpcurl

# create and switch to a working directory
RUN mkdir /app
WORKDIR /app

COPY target/canton .

COPY LICENSE.txt monitoring.conf parameters.conf storage.conf entrypoint.sh bootstrap-entrypoint.sc tools.sh logback.xml /app/

# ── record which flavour this image was built from ─────────────
ARG CANTON_VARIANT=enterprise                # default to enterprise variant

LABEL org.opencontainers.image.ref.name="canton-${CANTON_VARIANT}"

# Add label for security scanners, compliance tools, and auditing purposes
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}"

# point entrypoint to the amulet executable
ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]

