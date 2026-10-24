# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# Helpers for GDI images (ghcr.io/genomicdatainfrastructure/*), sourced by gdi-components.sh.
# Needs jq and gh (GH_TOKEN set).
# shellcheck shell=bash disable=SC2034 # sets gdi_* for the caller

gdi_org=GenomicDataInfrastructure
gdi_prefix=ghcr.io/genomicdatainfrastructure/

# Splits an image reference into gdi_name, gdi_tag and gdi_digest (empty when not pinned).
gdi_parse() {
  local rest=${1#"$gdi_prefix"}
  gdi_digest=""
  if [[ $rest == *@* ]]; then gdi_digest=${rest#*@}; rest=${rest%%@*}; fi
  gdi_name=${rest%%:*}
  gdi_tag=latest
  if [[ $rest == *:* ]]; then gdi_tag=${rest#*:}; fi
}

# Repository that publishes an image (most are named after their image).
gdi_repo() {
  case "$1" in
    gdi-userportal-solr) echo gdi-userportal-ckanext-gdi-userportal ;;
    *) echo "$1" ;;
  esac
}

# Prints the release for a repository and image tag (tag or vtag) as JSON, or nothing.
gdi_release() {
  local t
  for t in "$2" "v$2"; do
    if gh api "repos/$gdi_org/$1/releases/tags/$t" 2>/dev/null; then return 0; fi
  done
}
