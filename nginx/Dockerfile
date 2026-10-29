# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/nginx:1.31.8-alpine@sha256:785835ea65db4bba6f021acc0f3be91b0fef76a53fe41f8588c6698d2aed0606

# The image ships brotli-libs 1.2.0-r1; Alpine has the CVE-2026-111497 fix (1.2.1-r0).
RUN apk upgrade --no-cache

COPY ./ /etc/nginx/

EXPOSE 80
