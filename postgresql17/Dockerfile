# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

FROM docker.io/postgres:18-alpine

# Include extra setup scripts (eg datastore)
COPY --chown=postgres:postgres docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
