# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# First stage: Install curl
FROM registry.access.redhat.com/ubi9:1792742326@sha256:217dd5692d369799d34d09ffb6f5f3404efebc7900834490fdf9ae92fd6721d4 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

# Second stage: build keycloak image
FROM ghcr.io/genomicdatainfrastructure/keycloak-ga4gh-visa-issuer:main
# Copy curl from the first stage
COPY --from=ubi-micro-build /mnt/rootfs /
# The rootfs brings its own ca-certificates, which replaces Keycloak's Java trust store. Fail the
# build if the result is broken or trusts a distrusted root (CVE-2026-91403). keytool writes to a
# file first: sh has no pipefail, so a failing keytool piped into grep would pass the check.
RUN keytool -list -v -cacerts -storepass changeit > /tmp/cacerts.txt \
 && [ "$(grep -c '^Alias name: ' /tmp/cacerts.txt)" -ge 100 ] \
 && ! grep -qE "^Owner: CN=(emSign ECC Root CA - G3|AAA Certificate Services)," /tmp/cacerts.txt \
 && rm /tmp/cacerts.txt

USER keycloak

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true

ENV KC_DB=postgres
ENV KC_DB_URL=<DBURL>
ENV KC_DB_USERNAME=<DBUSERNAME>
ENV KC_DB_PASSWORD=<DBPASSWORD>
ENTRYPOINT ["/opt/keycloak/bin/kc.sh","start-dev", "--import-realm"]
