# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/nginx:1.31.10-alpine@sha256:7fc0fb4af7bf006aeb31aea88069976060f8f0a0a86b667126742cc17f4e31ae

# The image ships brotli-libs 1.2.0-r1; Alpine has the CVE-2026-111497 fix (1.2.1-r0).
RUN apk upgrade --no-cache

COPY ./ /etc/nginx/

EXPOSE 80
