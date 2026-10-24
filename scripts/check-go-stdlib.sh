#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

# CVE-2026-111943 (Go crypto/x509): fails if a Trivy CycloneDX SBOM contains a Go binary
# built with Go < 1.26.10, or 1.27.x < 1.27.3.
# Usage: scripts/check-go-stdlib.sh <image> <sbom.cdx.json>
# <image> is the image reference (for a built image, its final FROM). Accepted exceptions, with
# their reason and review-by date, are in scripts/go-stdlib-exceptions.txt.
set -euo pipefail

image=${1#docker.io/}
image=${image#library/}
sbom=$2
exceptions="$(dirname "$0")/go-stdlib-exceptions.txt"
today=$(date -u +%F)

fixed() {
  local v=${1#v} major minor patch
  [[ $v =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || return 1
  major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[3]}
  ((major > 1)) && return 0
  ((minor >= 28)) && return 0
  ((minor == 27 && patch >= 3)) && return 0
  ((minor == 26 && patch >= 10)) && return 0
  return 1
}

# Prints "valid" or "expired" for an exception matching image, binary and Go version exactly.
exception() {
  awk -v i="$image" -v b="$1" -v g="$2" -v today="$today" '
    BEGIN { RS = ""; FS = "\n" }
    {
      delete k
      for (n = 1; n <= NF; n++)
        if (match($n, /^[a-z-]+: /)) k[substr($n, 1, RLENGTH - 2)] = substr($n, RLENGTH + 1)
      if (k["image"] == i && k["binary"] == b && k["go"] == g && k["reason"] != "")
        status = (k["review-by"] >= today) ? "valid" : "expired"
    }
    END { print status }
  ' "$exceptions"
}

# One line per Go binary: path, then the Go version (stdlib) it was built with.
binaries=$(jq -r '
  ((.dependencies // []) | map({key: .ref, value: (.dependsOn // [])}) | from_entries) as $g
  | .components[]?
  | select(.type == "application" and any(.properties[]?; .name == "aquasecurity:trivy:Type" and .value == "gobinary"))
  | ($g[.["bom-ref"]] // []) as $direct
  | ([$direct[], ($direct[] | ($g[.] // [])[])] | map(select(startswith("pkg:golang/stdlib@")) | sub("^pkg:golang/stdlib@"; "")) | unique) as $std
  | "\(.name)\t\(if $std == [] then "unknown" else ($std | join(",")) end)"
' "$sbom")

{
  echo "### Go binaries in $image (CVE-2026-111943)"
  echo
  if [ -z "$binaries" ]; then
    echo "None."
  else
    echo "| Binary | Go | Result |"
    echo "| --- | --- | --- |"
  fi
} > go-check.md

failed=0
while IFS=$'\t' read -r path go; do
  [ -n "$path" ] || continue
  path=/$path
  [ "$go" = unknown ] || go=go${go#v}
  if fixed "${go#go}"; then
    result=ok
  else
    case $(exception "$path" "$go") in
      valid)
        result="accepted exception"
        echo "::warning::$image: $path is built with $go (accepted exception, see scripts/go-stdlib-exceptions.txt)"
        ;;
      expired)
        result="**exception past its review-by date**"
        echo "::error::$image: $path is built with $go; its exception in scripts/go-stdlib-exceptions.txt is past its review-by date"
        failed=1
        ;;
      *)
        result="**below 1.26.10 / 1.27.3**"
        echo "::error::$image: $path is built with $go, below the CVE-2026-111943 fix (go1.26.10 / go1.27.3)"
        failed=1
        ;;
    esac
  fi
  echo "| \`$path\` | $go | $result |" >> go-check.md
done <<< "$binaries"

cat go-check.md
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then cat go-check.md >> "$GITHUB_STEP_SUMMARY"; fi
rm go-check.md
exit "$failed"
