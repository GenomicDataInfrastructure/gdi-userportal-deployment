<!--
SPDX-FileCopyrightText: 2026 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->
# LNDS trust store

One trust store for every service in this deployment that makes outbound TLS calls.
`docker-compose.yml` mounts these files over each image's own store, so changing trust
for the whole stack is one commit here plus a redeploy, without rebuilding images.

| File | Format | Used by |
| --- | --- | --- |
| `cacerts` | Java keystore, password `changeit` | keycloak (`/etc/pki/ca-trust/extracted/java/cacerts`), rems (`/opt/java/openjdk/lib/security/cacerts`), access-management-service and dataset-discovery-service (`/work/cacerts`, read once their images pass `-Djavax.net.ssl.trustStore=/work/cacerts`) |
| `ca-bundle.pem` | PEM bundle | frontend (Node, `--use-openssl-ca` + `SSL_CERT_FILE`), ckan and synchronizer (Python, `REQUESTS_CA_BUNDLE` + `SSL_CERT_FILE`), mounted at `/etc/lnds/ca-bundle.pem` |

Both files are written from the same keystore in one run, so they always hold the same roots.

## Current version

- **Generated:** 2026-10-24
- **Source:** `/etc/pki/ca-trust/extracted/java/cacerts` from `registry.access.redhat.com/ubi9-minimal:1792742129`
  after `microdnf update -y ca-certificates`, which installed
  `ca-certificates-2026.2.92_v9.0.319-90.3.el9_8` (RHSA-2026:88459, the RHEL fix for the eMudhra/emSign incident)
- **keytool from:** `eclipse-temurin:21-jdk@sha256:23cc5734ff46e776f51ce66eb9ee08444fd47caabec0a95b7eb6e94be2d3696d`
  (multi-arch index digest; only its `keytool` is used, not its own root list)
- **Contents:** 118 trusted roots in `cacerts`, 118 certificates in `ca-bundle.pem`
- **SHA-256:**
  - `cacerts`: `f433065ee320a3caa59937138aadea5a95c822889c16dfb25a1ff2f637a07c9b`
  - `ca-bundle.pem`: `956b1bdf902a47aeedf751a771f6562078a16222b112a75fa6a66ec5dc362756`

## Distrust rule

Roots are removed by certificate subject, because alias names differ between JDK vendors and stores:

- `CN=emSign ECC Root CA - G3`: anchors the compromised eMudhra intermediates
  (CVE-2026-91403, CVE-2026-111943, Red Hat CVE-2026-114406).
- `CN=AAA Certificate Services` (Comodo AAA): cross-signs that chain, so removing emSign alone
  would leave it valid (Red Hat RHSB-2026-012). Current Sectigo chains anchor at the USERTrust roots, which stay.

Both roots are already absent from the patched RHEL store, so the removal is a guard: the script
deletes them if a future source store brings them back, and fails if either is still present at the end.
It also fails if `cacerts` or `ca-bundle.pem` has fewer than 100 certificates. keytool's output is
written to a file before it is searched: `sh` has no `pipefail`, so in `! keytool … | grep` a failing
keytool (for example on a truncated store) would print nothing and the guard would pass.

## Private CAs added

None. To trust a private CA (for example of a harvested catalogue), put its certificate in
`truststore/extra/NAME.pem` (with a `NAME.pem.license` file for REUSE). The script imports it into both
files under the alias `lnds-NAME`. Record each one here with its owner and why it is needed.

## Regenerate

```bash
scripts/build-truststore.sh
```

Use `DOCKER=podman scripts/build-truststore.sh` where Podman is the container runtime. Then update
"Current version" above (date, the `ca-certificates` version the script prints, entry counts and hashes),
commit `cacerts` and `ca-bundle.pem`, and redeploy (`docker compose up -d`). No image rebuild is needed.

To change the distrust rule, edit `DISTRUST` in the script. To move to a newer RHEL root list, bump the
`UBI` tag in the script.

## Check

Inside a Java container with the store mounted, this prints `118` (the number of roots; anything
below 100 means the store is broken) and then `0` (distrusted roots):

```bash
keytool -list -v -cacerts -storepass changeit > /tmp/cacerts.txt && grep -c '^Alias name: ' /tmp/cacerts.txt && grep -cE "^Owner: CN=(emSign ECC Root CA - G3|AAA Certificate Services)," /tmp/cacerts.txt
```

If keytool fails, nothing is printed: never pipe keytool straight into `grep`, because a failing
keytool then looks like "0 distrusted roots". For a store file, use `-keystore <file>` instead of `-cacerts`. In containers that use the PEM bundle,
`sha256sum /etc/lnds/ca-bundle.pem` must match the hash above.
