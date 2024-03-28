# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

import requests


def get_packages_count(ckan_base_url: str) -> int:
    response = requests.get(
        f"{ckan_base_url}/api/3/action/package_search?rows=0"
    ).json()
    return response["result"]["count"]


def get_packages(start, rows, ckan_base_url: str) -> list:
    response = requests.get(
        f"{ckan_base_url}/api/3/action/package_search?rows={rows}&start={start}"
    ).json()
    return response["result"]["results"]
