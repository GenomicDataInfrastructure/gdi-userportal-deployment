#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

set -e

echo "Creating $KC_DB_NAME for $KC_DB_USERNAME"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE "$KC_DB_USERNAME" NOSUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD '$KC_DB_PASSWORD';
    CREATE DATABASE "$KC_DB_NAME" OWNER "$KC_DB_USERNAME" ENCODING 'utf-8';
EOSQL
