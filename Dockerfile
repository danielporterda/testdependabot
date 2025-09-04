# Copyright (c) 2024 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

FROM fullstorydev/grpcurl:v1.9.2@sha256:0c3796edc8b6bb1814da2f11a554996237c0dd98380fce182efb1dc44c556ac1 AS grpcurl

FROM eclipse-temurin:21-jdk-noble@sha256:f31b224f6e3094e4fa1957779c8602af1be15b982ec840d6dd7ff2fb1726bced

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

