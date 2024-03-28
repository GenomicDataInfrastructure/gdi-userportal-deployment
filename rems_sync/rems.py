# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

import requests
import hashlib


def create_or_return_organization_in_rems(
    name: str, short_name: str, rems_base_url: str
) -> str:
    id = hashlib.md5(name.encode())
    response = requests.get(f"{rems_base_url}/api/organizations/{id}")
    if response.status_code == 200:
        print(f"Organization found: {id}")
        return id
    else:
        print(f"Organization found failed: {response.text}")
    response = requests.post(
        f"{rems_base_url}/api/organizations/create",
        {
            "organization/id": id,
            "organization/name": {"en": name},
            "organization/short-name": {"en": short_name},
        },
    )
    if response.status_code == 200:
        print(f"Organization created: {id}")
    else:
        raise Exception(f"Organization creation failed: {response.text}")
    return id


def create_or_return_resource_in_rems(
    organization_id: str, resource_id: str, rems_base_url: str
) -> str:
    response = requests.get(f"{rems_base_url}/api/resources?resid={resource_id}")
    if response.status_code != 200 or len(response.json()) != 1:
        raise Exception(f"Resource found failed: {response.text}")
    elif response.status_code == 200:
        id = response.json()[0]["id"]
        print(f"Resource found: {id}")
        return id
    response = requests.post(
        f"{rems_base_url}/api/resources/create",
        {
            "resid": resource_id,
            "organization": {"organization/id": organization_id},
            "licenses": [],
        },
    )
    if response.status_code != 200:
        raise Exception(f"Resource creation failed: {response.text}")
    id = response.json()["id"]
    print(f"Resource created: {id}")
    return id


def create_or_return_workflow_in_rems(organization_id: str, rems_base_url: str) -> int:
    response = requests.get(
        f"{rems_base_url}/api/workflows?disabled=false&archived=false"
    )
    if response.status_code != 200:
        raise Exception(f"Workflow found failed: {response.text}")

    result = [
        workflow
        for workflow in response.json()
        if workflow["organization"]["organization/id"] == organization_id
    ]

    if len(result) > 0:
        id = result[0]["id"]
        print(f"Workflow found: {id}")
        return id

    response = requests.post(
        f"{rems_base_url}/api/workflows/create",
        {
            "type": "workflow/default",
            "organization": {"organization/id": organization_id},
            "title": "Default Workflow",
        },
    )
    if response.status_code != 200:
        raise Exception(f"Workflow creation failed: {response.text}")
    id = response.json()["id"]
    print(f"Workflow created: {id}")
    return id


def create_or_return_catalogue_item_in_rems(
    organization_id: str,
    resource_id: int,
    workflow_id: int,
    resource_title: str,
    rems_base_url: str,
) -> str:
    response = requests.get(
        f"{rems_base_url}/api/catalogue-items?resource={resource_id}"
    )
    if response.status_code != 200 or len(response.json()) != 1:
        raise Exception(f"Catalogue Item found failed: {response.text}")
    elif response.status_code == 200:
        id = response.json()[0]["id"]
        print(f"Catalogue Item found: {id}")
        return id
    response = requests.post(
        f"{rems_base_url}/api/catalogue-items/create",
        {
            "resid": resource_id,
            "wfid": workflow_id,
            "organization": {"organization/id": organization_id},
            "localizations": {"en": {"title": resource_title}},
            "enabled": True,
        },
    )
    if response.status_code != 200:
        raise Exception(f"Catalogue Item creation failed: {response.text}")
    id = response.json()["id"]
    print(f"Catalogue Item created: {id}")
    return id
