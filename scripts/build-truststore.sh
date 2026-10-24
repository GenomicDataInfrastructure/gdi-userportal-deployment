#!/usr/bin/env sh
# Builds truststore/cacerts (Java) and truststore/ca-bundle.pem (OpenSSL, Node, Python).
set -eu
cd "$(dirname "$0")/.."
mkdir -p truststore/extra
DOCKER="${DOCKER:-docker}"
UBI=registry.access.redhat.com/ubi9-minimal:1792742129
TEMURIN=eclipse-temurin:21-jdk@sha256:23cc5734ff46e776f51ce66eb9ee08444fd47caabec0a95b7eb6e94be2d3696d
# Roots to remove, matched by certificate subject: alias names differ between JDK vendors.
DISTRUST='^Owner: CN=(emSign ECC Root CA - G3|AAA Certificate Services),'
# Start from the patched RHEL store: newer than any JDK's own root list.
"$DOCKER" run --rm -v "$PWD/truststore:/out" "$UBI" sh -euc '
  microdnf update -y ca-certificates >/dev/null
  rpm -q ca-certificates
  cp /etc/pki/ca-trust/extracted/java/cacerts /out/cacerts'
"$DOCKER" run --rm -i -e DISTRUST="$DISTRUST" -v "$PWD/truststore:/out" "$TEMURIN" sh -eu <<'EOF'
ks() { keytool "$@" -keystore /out/cacerts -storepass changeit; }
# No pipes into keytool: sh has no pipefail, so a failing keytool would look like "nothing to remove".
ks -list -v > /tmp/list
awk -v re="$DISTRUST" '/^Alias name: /{a=substr($0,13)} $0 ~ re {print a}' /tmp/list > /tmp/distrust
while IFS= read -r a; do ks -delete -alias "$a"; done < /tmp/distrust
for f in /out/extra/*.pem; do
  [ -e "$f" ] || continue
  ks -importcert -noprompt -alias "lnds-$(basename "$f" .pem)" -file "$f"
done
ks -list -rfc > /tmp/rfc
sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" /tmp/rfc > /out/ca-bundle.pem
ks -list -v > /tmp/list
[ "$(grep -c '^Alias name: ' /tmp/list)" -ge 100 ]
[ "$(grep -c 'BEGIN CERTIFICATE' /out/ca-bundle.pem)" -ge 100 ]
! grep -qE "$DISTRUST" /tmp/list
EOF
chmod 644 truststore/cacerts truststore/ca-bundle.pem
