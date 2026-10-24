#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# Downloads the SBOM attached to the GitHub release of a GDI image (Snippet S) to <out>, for the
# Go check. An image pinned to a release tag uses that release; an image on a branch tag (:main)
# uses the repository's latest release. A missing SBOM fails a pinned image and only warns
# otherwise (then <out> isn't written). A pinned digest must match the digest the SBOM describes.
# Usage: scripts/gdi-release-sbom.sh <image ref> <out>
set -euo pipefail
# shellcheck source=scripts/gdi-release.sh
. "$(dirname "$0")/gdi-release.sh"

ref=$1
out=$2
gdi_parse "$ref"
repo=$(gdi_repo "$gdi_name")

if gdi_is_release_tag "$gdi_tag"; then
  pinned=true
  release=$(gdi_release "$repo" "$gdi_tag")
else
  pinned=false
  release=$(gh api "repos/$gdi_org/$repo/releases/latest" 2>/dev/null || true)
fi
tag=$(jq -r '.tag_name // empty' <<< "${release:-null}")
url=$(jq -r '[.assets[]? | select(.name == "sbom.cdx.json") | .browser_download_url][0] // empty' <<< "${release:-null}")

if [ -z "$url" ]; then
  msg="$ref: no sbom.cdx.json on release ${tag:-(none found)} of $gdi_org/$repo, so its Go binaries can't be checked"
  if $pinned; then
    echo "::error::$msg"
    exit 1
  fi
  echo "::warning::$msg (not pinned yet, using the latest release)"
  exit 0
fi

curl -fsSL -o "$out" "$url"
if [ -n "$gdi_digest" ] && ! jq -e --arg d "$gdi_digest" \
  '[.metadata.component.properties[]? | select(.name == "aquasecurity:trivy:RepoDigest") | .value | endswith("@" + $d)] | any' "$out" > /dev/null; then
  echo "::error::$ref: the SBOM on release $tag of $gdi_org/$repo describes another digest"
  rm "$out"
  exit 1
fi
echo "$ref: using the SBOM on release $tag of $gdi_org/$repo$($pinned || echo ' (latest release, image not pinned yet)')"
