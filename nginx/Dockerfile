# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/nginx:1.31.8-alpine@sha256:fed7e14be83cbd2661a75cdc5b872d936cf155d46c327084d30b8df19ae88d72

# The image ships brotli-libs 1.2.0-r1; Alpine has the CVE-2026-111497 fix (1.2.1-r0).
RUN apk upgrade --no-cache

COPY ./ /etc/nginx/

EXPOSE 80
