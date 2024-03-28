#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

printenv | grep -v "no_proxy" >> /etc/environment

cron -f -l 2
