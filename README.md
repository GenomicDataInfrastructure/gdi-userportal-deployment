<!--
SPDX-FileCopyrightText: 2024 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->
[![REUSE status](https://api.reuse.software/badge/github.com/GenomicDataInfrastructure/gdi-userportal-deployment)](https://api.reuse.software/info/github.com/GenomicDataInfrastructure/gdi-userportal-deployment)
![example workflow](https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment/actions/workflows/test.yml/badge.svg)
[![GitHub contributors](https://img.shields.io/github/contributors/GenomicDataInfrastructure/gdi-userportal-deployment)](https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment/graphs/contributors)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

# GDI User Portal
This is a deployment example of all components needed for GDI User Portal, assuming a RHEL-based Linux distribution. For REMS, the keys for issuing Visas and passports are included, follow the instructions here [https://github.com/GenomicDataInfrastructure/starter-kit-rems](https://github.com/GenomicDataInfrastructure/starter-kit-rems) for the complete manual.


> [!IMPORTANT]
> This repository cannot be used directly for production. Please ensure you have carefully reviewed all requirements and environment variables, for each component, and have put all security measurements in place.

# Preparatory steps on the VM
```
# Install some tools
sudo dnf install git 

# Install, start and enable Docker
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# You can also [create a user](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/4/html/system_administration_guide/s2-users-add)
# And [add her to a docker group](https://docs.docker.com/engine/install/linux-postinstall/) so that docker can be run without sudo.

# Configure firewall
firewall-cmd --permanent --zone=public --add-port=8443/tcp
# If you intend to run a reverse proxy on the machine as well, ensure 80/443 are open and nginx is configured to proxy connection to port 8443.

# Access to GDI Github packages 
Make sure that the VM has access to GitHub packages. Follow the manual here: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic
```

# Installation
```
# Prepare the project files
mkdir -p /srv
cd /srv
git clone https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment.git
cd gdi-userportal-deployment/
cp .env.example .env
```

# Configuration
* Check and replace sensitive values in `.env`;
* Replace NGINX SSL certificates.

# Running
```bash
sudo su
cd /srv/gdi-userportal-deployment/
docker compose build
docker compose run --rm -e CMD="migrate;test-data" rems
docker compose up -d
```

If you want to test locally with another domain, you can generated a new self-signed certificate with the following command:

```bash
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -keyout ./nginx/ssl/server.key -out ./nginx/ssl/server.crt -config ./nginx/ssl/openssl.cnf
```

# Running locally

To run the whole stack on a workstation (for example to test a change before deploying it), use
`docker-compose.local.yml` on top of `docker-compose.yml`. It keeps the stack self-contained:
- nginx listens on `LOCAL_HTTP_PORT` (default 8088);
- server-to-server calls to Keycloak stay inside the network;
- the synchronizer syncs from the local CKAN, not the live catalogue;
- REMS never sends mail;
- the amd64-only GDI images get long health-check start periods, because on arm64 (Apple Silicon) they run under emulation.

```bash
# The GDI images are private: log in with a GitHub token that has read:packages
docker login ghcr.io            # or: podman login ghcr.io

cp .env.secrets.example .env.secrets   # fill in every value (any random strings work locally)
git update-index --skip-worktree .env.secrets   # .env.secrets is tracked: never commit real values

docker compose -f docker-compose.yml -f docker-compose.local.yml build
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d postgres
docker compose -f docker-compose.yml -f docker-compose.local.yml run --rm -e CMD="migrate;test-data" rems
docker compose -f docker-compose.yml -f docker-compose.local.yml run --rm -e CMD="api-key add <REMS_API_KEY> userportal" rems
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
```

With Podman, `podman login` doesn't apply to docker-compose: pull the GDI images first with
`podman pull --platform linux/amd64 ghcr.io/genomicdatainfrastructure/<image>:<tag>`.

nginx picks the virtual host from the `Host` header. Either send it:

```bash
curl -H "Host: portal.dev.gdi.lu" http://localhost:8088/
```

or point the five `*_HOSTNAME` names from `.env`, and `kong`, at `127.0.0.1` in `/etc/hosts` and
browse to `http://portal.dev.gdi.lu:8088/`. The portal's browser code calls the APIs at
`http://kong:8000` (`NEXT_PUBLIC_DDS_URL`, `NEXT_PUBLIC_DAAM_URL`), which the local override publishes
on `LOCAL_KONG_PORT` (default 8000). Logging in doesn't work locally: Keycloak, the frontend and REMS
redirect browsers to the `https://` hostnames in `.env`.

# Post configuration
* Add a new user to CKAN realm and REMS realm in Keycloak
* Ensure both CKAN and frontend are pointing to the same Keycloak;

## Contributing

We welcome contributions! If you would like to contribute, please follow these steps:

Fork the repository
Create a new branch for your changes
Make your changes
Run the tests to ensure they pass
Submit a pull request

## License

This work is licensed under multiple licences. Here is a brief summary as of January 2024:

- All original source code is licensed under [Apache-2.0](./LICENSES/Apache-2.0.txt).
- All documentation is licensed under [CC-BY-4.0](./LICENSES/CC-BY-4.0.txt).
- For more accurate information, check the individual files.
