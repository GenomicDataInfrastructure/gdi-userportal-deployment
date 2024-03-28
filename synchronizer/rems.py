# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

import requests
import hashlib


def create_or_return_organization_in_rems(rems_base_url: str, headers: dict) -> str:
    name = "Genomic Data Institute"
    short_name = "GDI"
    id = hashlib.md5(name.encode()).hexdigest()
    response = requests.get(
        url=f"{rems_base_url}/api/organizations/{id}", headers=headers
    )
    if response.status_code == 200:
        return id
    elif response.status_code != 404:
        raise Exception(f"Organization found failed: {response.text}")
    response = requests.post(
        url=f"{rems_base_url}/api/organizations/create",
        json={
            "organization/id": id,
            "organization/name": {"en": name},
            "organization/short-name": {"en": short_name},
        },
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Organization creation failed: {response.text}")
    return id


def create_or_return_form_in_rems(
    organization_id: str, rems_base_url: str, headers: dict
) -> int:
    response = requests.get(
        url=f"{rems_base_url}/api/forms?disabled=false&archived=false",
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Workflow found failed: {response.text}")

    result = [
        form
        for form in response.json()
        if form["organization"]["organization/id"] == organization_id
    ]

    if len(result) > 0:
        id = result[0]["form/id"]
        return id

    response = requests.post(
        url=f"{rems_base_url}/api/forms/create",
        json={
            "form/external-title": {"en": "GDI Default Form"},
            "form/internal-name": "GDI Default Form",
            "organization": {"organization/id": organization_id},
            "form/fields": [
                {
                    "field/type": "attachment",
                    "field/title": {"en": "Attachment 1"},
                    "field/optional": False,
                }
            ],
        },
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Workflow creation failed: {response.text}")
    id = response.json()["id"]
    return id


def create_or_return_workflow_in_rems(
    organization_id: str, form_id: int, rems_base_url: str, headers: dict
) -> int:
    response = requests.get(
        url=f"{rems_base_url}/api/workflows?disabled=false&archived=false",
        headers=headers,
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
        return id

    response = requests.post(
        url=f"{rems_base_url}/api/workflows/create",
        json={
            "type": "workflow/default",
            "organization": {"organization/id": organization_id},
            "title": "GDI Default Workflow",
            "forms": [{"form/id": form_id}],
        },
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Workflow creation failed: {response.text}")
    id = response.json()["id"]
    return id


def create_or_return_resource_in_rems(
    organization_id: str, dataset_id: str, rems_base_url: str, headers: dict
) -> str:
    response = requests.get(
        url=f"{rems_base_url}/api/resources?resid={dataset_id}", headers=headers
    )
    if response.status_code != 200 or len(response.json()) > 1:
        raise Exception(f"Resource found failed: {response.text}")
    elif len(response.json()) == 1:
        id = response.json()[0]["id"]
        return id
    response = requests.post(
        url=f"{rems_base_url}/api/resources/create",
        json={
            "resid": dataset_id,
            "organization": {"organization/id": organization_id},
            "licenses": [],
        },
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Resource creation failed: {response.text}")
    id = response.json()["id"]
    return id


def create_or_return_catalogue_item_in_rems(
    organization_id: str,
    workflow_id: int,
    dataset_id: str,
    resource_id: int,
    title: str,
    rems_base_url: str,
    headers: dict,
) -> str:
    response = requests.get(
        url=f"{rems_base_url}/api/catalogue-items?resource={dataset_id}",
        headers=headers,
    )
    if response.status_code != 200 or len(response.json()) > 1:
        raise Exception(f"Catalogue Item found failed: {response.text}")
    elif len(response.json()) == 1:
        id = response.json()[0]["id"]
        return id
    response = requests.post(
        url=f"{rems_base_url}/api/catalogue-items/create",
        json={
            "resid": resource_id,
            "wfid": workflow_id,
            "organization": {"organization/id": organization_id},
            "localizations": {"en": {"title": title}},
            "enabled": True,
        },
        headers=headers,
    )
    if response.status_code != 200:
        raise Exception(f"Catalogue Item creation failed: {response.text}")
    id = response.json()["id"]
    return id
