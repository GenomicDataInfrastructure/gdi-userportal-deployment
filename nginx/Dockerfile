# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/nginx:1.31.8-alpine@sha256:1ef7ca94d7879df82421428ce13bd1eaa412404953859cf7a5b6512c25e67a60

# The image ships brotli-libs 1.2.0-r1; Alpine has the CVE-2026-111497 fix (1.2.1-r0).
RUN apk upgrade --no-cache

COPY ./ /etc/nginx/

EXPOSE 80
