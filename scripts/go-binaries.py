# SPDX-FileCopyrightText: 2026 PNED G.I.E.
#
# SPDX-License-Identifier: Apache-2.0

"""Lists the Go binaries in an image filesystem, read as a tar stream on stdin.

Prints "<path>\\t<go version>" per binary, like `go version <dir>`. Unlike Trivy, it also finds
Go binaries installed by apt, apk or rpm. Usage: docker export <container> | python3 go-binaries.py
"""

import sys
import tarfile

MAGIC = b"\xff Go buildinf:"


def uvarint(data, pos):
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if byte < 0x80:
            return value, pos
        shift += 7


def go_version(data):
    """The Go version in a Go 1.18+ build info header, "unknown" for older formats."""
    start = data.find(MAGIC)
    while start != -1:
        header = data[start : start + 32]
        if len(header) == 32 and header[14] in (4, 8):
            if header[15] & 0x2:
                length, pos = uvarint(data, start + 32)
                version = (
                    data[pos : pos + length].decode("ascii", "replace").split(" ")[0]
                )
                if version.startswith("go"):
                    return version
            else:
                return "unknown"
        start = data.find(MAGIC, start + 1)
    return None


with tarfile.open(fileobj=sys.stdin.buffer, mode="r|") as tar:
    for member in tar:
        if not member.isfile() or member.size < 4:
            continue
        f = tar.extractfile(member)
        if f.read(4) != b"\x7fELF":
            continue
        version = go_version(b"\x7fELF" + f.read())
        if version:
            name = member.name.removeprefix("./")
            print(f"/{name.lstrip('/')}\t{version}")
