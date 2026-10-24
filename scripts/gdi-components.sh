#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# Prints components.json: every GDI image this deployment runs (docker-compose.yml images and
# FROM lines of its build contexts), with its release, the SBOM attached to that release and the
# image digest. Third-party images get their own SBOMs in .github/workflows/third-party-sbom.yml.
# "pinned" means the reference names a release tag. The digest comes from the reference
# (name:tag@sha256:...), else from the release SBOM, else from an anonymous registry lookup;
# digest_source says which.
# Usage: docker compose config --format json | scripts/gdi-components.sh > components.json
#        docker compose config --format json | scripts/gdi-components.sh --list   (images only)
# Needs curl, jq and gh (GH_TOKEN set).
set -euo pipefail
# shellcheck source=scripts/gdi-release.sh
. "$(dirname "$0")/gdi-release.sh"

# Current digest of name:tag, looked up anonymously. Prints nothing for a private package.
digest_of() {
  local name=$1 tag=$2 token
  token=$(curl -fsS "https://ghcr.io/token?service=ghcr.io&scope=repository:genomicdatainfrastructure/$name:pull" | jq -r .token) || return 0
  curl -fsSI -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json" \
    "https://ghcr.io/v2/genomicdatainfrastructure/$name/manifests/$tag" |
    tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2 }' || true
}

# One line per GDI image: compose service, then image reference.
gdi_images() {
  jq -r --arg p "$gdi_prefix" '.services | to_entries[] | select((.value.image // "") | startswith($p)) | "\(.key)\t\(.value.image)"' <<< "$compose"
  jq -r '.services | to_entries[] | select(.value.build) | "\(.key)\t\(.value.build.context)/\(.value.build.dockerfile // "Dockerfile")"' <<< "$compose" |
    while IFS=$'\t' read -r service dockerfile; do
      awk -v s="$service" -v p="$gdi_prefix" 'toupper($1) == "FROM" {
        for (i = 2; i <= NF; i++) if ($i !~ /^--/) { if (index($i, p) == 1) print s "\t" $i; break }
      }' "$dockerfile"
    done
}

compose=$(cat)
if [ "${1:-}" = --list ]; then
  gdi_images
  exit 0
fi

gdi_images | while IFS=$'\t' read -r service ref; do
  gdi_parse "$ref"
  name=$gdi_name tag=$gdi_tag digest=$gdi_digest
  repo=$(gdi_repo "$name")

  pinned=false
  json=""
  if gdi_is_release_tag "$tag"; then
    pinned=true
    json=$(gdi_release "$repo" "$tag")
  else
    echo "::warning::$service: $ref is not pinned to a release" >&2
  fi
  release=$(jq -r '.html_url // empty' <<< "${json:-null}")
  sbom=$(jq -r '[.assets[]? | select(.name == "sbom.cdx.json") | .browser_download_url][0] // empty' <<< "${json:-null}")
  if $pinned && [ -z "$sbom" ]; then echo "::warning::$service: no SBOM on the release of $ref" >&2; fi

  source=compose
  if [ -z "$digest" ] && [ -n "$sbom" ]; then
    source="release SBOM"
    digest=$(curl -fsSL "$sbom" | jq -r '[.metadata.component.properties[]? | select(.name == "aquasecurity:trivy:RepoDigest") | .value | sub(".*@"; "")][0] // empty')
  fi
  if [ -z "$digest" ]; then
    source=registry
    digest=$(digest_of "$name" "$tag" 2>/dev/null)
  fi
  if [ -z "$digest" ]; then source=""; fi

  jq -n --arg service "$service" --arg image "$gdi_prefix$name" --arg tag "$tag" --arg digest "$digest" \
    --arg source "$source" --argjson pinned "$pinned" --arg repository "https://github.com/$gdi_org/$repo" \
    --arg release "$release" --arg sbom "$sbom" \
    'def nullable: if . == "" then null else . end;
     {service: $service, image: $image, tag: $tag, pinned: $pinned, digest: ($digest | nullable),
      digest_source: ($source | nullable), repository: $repository, release: ($release | nullable),
      sbom: ($sbom | nullable)}'
done | jq -s '{components: .}'
