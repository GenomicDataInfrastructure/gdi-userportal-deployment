# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/nginx:1.31.9-alpine@sha256:fb4658584bd9a916ffb6f6e365f97c25cfdb2923801f551ea08356e695f14ff7

# The image ships brotli-libs 1.2.0-r1; Alpine has the CVE-2026-111497 fix (1.2.1-r0).
RUN apk upgrade --no-cache

COPY ./ /etc/nginx/

EXPOSE 80
