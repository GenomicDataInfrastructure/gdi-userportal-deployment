# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

from ckan import get_packages_count, get_packages
from rems import (
    create_or_return_organization_in_rems,
    create_or_return_workflow_in_rems,
    create_or_return_form_in_rems,
    create_or_return_resource_in_rems,
    create_or_return_catalogue_item_in_rems,
)
import os

ckan_base_url = os.environ.get(
    "CKAN_URL", "http://catalogue.local.onemilliongenomes.eu"
)
print(f"CKAN base url: {ckan_base_url}")
rems_base_url = os.environ.get("REMS_URL", "http://daam.local.onemilliongenomes.eu")
print(f"REMS base url: {rems_base_url}")
rems_api_key = os.environ.get("REMS_API_KEY", "42")
print(f"REMS api key: **********")
rems_user_id = os.environ.get("REMS_BOT_USER", "owner")
print(f"REMS user id: {rems_user_id}")

rows = 100
start = 0
headers = {
    "Content-Type": "application/json",
    "x-rems-api-key": rems_api_key,
    "x-rems-user-id": rems_user_id,
}

organization_id = create_or_return_organization_in_rems(rems_base_url, headers)
print(f"Organization id: {organization_id}")

form_id = create_or_return_form_in_rems(organization_id, rems_base_url, headers)
print(f"Form id: {form_id}")

workflow_id = create_or_return_workflow_in_rems(
    organization_id, form_id, rems_base_url, headers
)
print(f"Workflow id: {workflow_id}")

count = get_packages_count(ckan_base_url)
print(f"packages found: {count}")

while start < count:
    packages = get_packages(start, rows, ckan_base_url)
    for package in packages:
        if "identifier" not in package or package["identifier"] is None:
            continue
        dataset_id = package["identifier"]
        dataset_title = package["title"]
        resource_id = create_or_return_resource_in_rems(
            organization_id, dataset_id, rems_base_url, headers
        )
        print(f"resource id: {resource_id}")
        catalogue_item_id = create_or_return_catalogue_item_in_rems(
            organization_id,
            workflow_id,
            dataset_id,
            resource_id,
            dataset_title,
            rems_base_url,
            headers,
        )
        print(f"catalogue item id: {catalogue_item_id}")
    start += rows
