#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# Prints components.json: every GDI image this deployment runs (docker-compose.yml images and
# FROM lines of its build contexts), with its digest and a link to the SBOM attached to its
# release. Third-party images get their own SBOMs in .github/workflows/third-party-sbom.yml.
# A digest pinned in the image reference (name:tag@sha256:...) is used as is; otherwise the
# current digest of the tag is looked up and "pinned" is false.
# Usage: docker compose config --format json | scripts/gdi-components.sh > components.json
# Needs curl, jq and gh (GH_TOKEN set); GHCR_TOKEN is optional, see digest_of.
set -euo pipefail
# shellcheck source=scripts/gdi-release.sh
. "$(dirname "$0")/gdi-release.sh"

# Current digest of name:tag. Most GDI packages need auth: GHCR_TOKEN (a token with read:packages
# that can see the package) is used when set. Prints nothing when the registry refuses.
digest_of() {
  local name=$1 tag=$2 token auth=()
  if [ -n "${GHCR_TOKEN:-}" ]; then auth=(-u "token:$GHCR_TOKEN"); fi
  token=$(curl -fsS "${auth[@]}" "https://ghcr.io/token?service=ghcr.io&scope=repository:genomicdatainfrastructure/$name:pull" | jq -r .token) || return 0
  curl -fsSI -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json" \
    "https://ghcr.io/v2/genomicdatainfrastructure/$name/manifests/$tag" |
    tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2 }' || true
}

compose=$(cat)
{
  jq -r --arg p "$gdi_prefix" '.services | to_entries[] | select((.value.image // "") | startswith($p)) | "\(.key)\t\(.value.image)"' <<< "$compose"
  jq -r '.services | to_entries[] | select(.value.build) | "\(.key)\t\(.value.build.context)/\(.value.build.dockerfile // "Dockerfile")"' <<< "$compose" |
    while IFS=$'\t' read -r service dockerfile; do
      awk -v s="$service" -v p="$gdi_prefix" 'toupper($1) == "FROM" && index($2, p) == 1 { print s "\t" $2 }' "$dockerfile"
    done
} | while IFS=$'\t' read -r service ref; do
  gdi_parse "$ref"
  name=$gdi_name tag=$gdi_tag digest=$gdi_digest
  repo=$(gdi_repo "$name")

  pinned=true
  if [ -z "$digest" ]; then
    pinned=false
    digest=$(digest_of "$name" "$tag" 2>/dev/null)
    echo "::warning::$service: $ref is not pinned by digest${digest:+ (current digest looked up)}" >&2
  fi

  json=$(gdi_release "$repo" "$tag")
  release=$(jq -r '.html_url // empty' <<< "$json")
  sbom=$(jq -r '[.assets[]? | select(.name == "sbom.cdx.json") | .browser_download_url][0] // empty' <<< "$json")
  if [ -z "$sbom" ]; then echo "::warning::$service: no release SBOM found for $ref" >&2; fi

  jq -n --arg service "$service" --arg image "$gdi_prefix$name" --arg tag "$tag" --arg digest "$digest" \
    --argjson pinned "$pinned" --arg repository "https://github.com/$gdi_org/$repo" \
    --arg release "$release" --arg sbom "$sbom" \
    '{service: $service, image: $image, tag: $tag, digest: (if $digest == "" then null else $digest end), pinned: $pinned, repository: $repository,
      release: (if $release == "" then null else $release end), sbom: (if $sbom == "" then null else $sbom end)}'
done | jq -s '{components: .}'
