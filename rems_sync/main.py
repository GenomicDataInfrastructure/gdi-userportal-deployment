# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

from ckan import get_packages_count, get_packages
from rems import (
    create_or_return_organization_in_rems,
    create_or_return_resource_in_rems,
    create_or_return_workflow_in_rems,
    create_or_return_catalogue_item_in_rems,
)

org_name = "Genomic Data Infrastructure"
org_short_name = "GDI"
rems_base_url = "http://daam.local.onemilliongenomes.eu"
ckan_base_url = "https://ckan-test.healthdata.nl"
rows = 100
start = 0

count = get_packages_count(ckan_base_url)
print(f"packages found: {count}")

while start < count:
    packages = get_packages(start, rows, ckan_base_url)
    for package in packages:
        organization_id = create_or_return_organization_in_rems(
            org_name, org_short_name, rems_base_url
        )
        print(f"Organization id: {organization_id}")
        dataset_id = package["id"]
        resource_id = create_or_return_resource_in_rems(
            organization_id, dataset_id, rems_base_url
        )
        workflow_id = create_or_return_workflow_in_rems(organization_id, rems_base_url)
        catalogue_id = create_or_return_catalogue_item_in_rems(
            organization_id, resource_id, workflow_id, rems_base_url
        )
    start += rows
