# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# keycloak-ga4gh-visa-issuer is published for linux/amd64 only. Both stages pin that platform so the
# curl rootfs matches the image it's copied into, also when building on arm64 (e.g. Apple Silicon).

# First stage: Install curl
FROM --platform=linux/amd64 registry.access.redhat.com/ubi9:1793179250@sha256:5f08e80aa970ae77712e75e5e857ac0b396abc900823c4d041c1150a9538a13f AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs curl --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

# Second stage: build keycloak image
FROM --platform=linux/amd64 ghcr.io/genomicdatainfrastructure/keycloak-ga4gh-visa-issuer:1.0.5
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
