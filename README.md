<!--
SPDX-FileCopyrightText: 2024 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->
[![REUSE status](https://api.reuse.software/badge/github.com/GenomicDataInfrastructure/gdi-userportal-deployment)](https://api.reuse.software/info/github.com/GenomicDataInfrastructure/gdi-userportal-deployment)
![example workflow](https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment/actions/workflows/test.yml/badge.svg)
[![GitHub contributors](https://img.shields.io/github/contributors/GenomicDataInfrastructure/gdi-userportal-deployment)](https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment/graphs/contributors)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

# GDI User Portal
This is a deployment example of GDI User Portal, assuming RHEL-based Linux distribution.

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
```

# Installation
```
# Prepare the project files
mkdir -p /srv
cd /srv
git clone https://github.com/GenomicDataInfrastructure/gdi-userportal-deployment.git
cd gdi-userportal-ckan-deployment/
cp .env.example .env
```

# Configuration
* Check and fill .env values;
* If you want SSL, configure NGINX templates and add certificates.

# Running
```
sudo su
cd /srv/gdi-userportal-deployment/
docker compose up -d --build
```

# Post configuration
* Add a new user to CKAN realm in Keycloak;
* Ensure both CKAN and frontend are pointing to the same Keycloak;

## License

This work is licensed under multiple licences. Here is a brief summary as of January 2024:

- All original source code is licensed under [Apache-2.0](./LICENSES/Apache-2.0.txt).
- All documentation is licensed under [CC-BY-4.0](./LICENSES/CC-BY-4.0.txt).
- For more accurate information, check the individual files.