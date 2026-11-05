#!/usr/bin/env python3
"""Verify and inventory an official KFGQPC developer archive without extracting it.

The published source SHA-256 is checked before ZIP metadata is trusted. This
tool does not read, emit, or transform Quran text. A passing archive digest
proves the downloaded bytes match the published package; it does not replace
the later corpus/schema/content review required by the pack builder.

Usage:
  python tool/inspect_kfgqpc_quran_archive.py --edition warsh --archive path/to/archive.zip
"""

from __future__ import annotations

import argparse
import hashlib
import json
import stat
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any


OFFICIAL_SOURCE_PAGE = "https://qurancomplex.gov.sa/quran-dev/"
MAX_ARCHIVE_BYTES = 128 * 1024 * 1024
MAX_MEMBER_COUNT = 20_000
MAX_MEMBER_BYTES = 256 * 1024 * 1024
MAX_TOTAL_UNCOMPRESSED_BYTES = 1024 * 1024 * 1024
MAX_COMPRESSION_RATIO = 2_000


@dataclass(frozen=True)
class OfficialSource:
    archive_version: str
    displayed_archive_size: str
    sha256: str


# Values are the package versions/checksums displayed by the official KFGQPC
# developer portal, not hashes guessed from a third-party mirror.
OFFICIAL_SOURCES = {
    "hafs": OfficialSource(
        archive_version="15.0",
        displayed_archive_size="9.68 MB",
        sha256="227E6B1564D980F2BD09C2C35EBFB0330AC268C79A7C247CD1AB665BC635F245",
    ),
    "warsh": OfficialSource(
        archive_version="8.0",
        displayed_archive_size="8.49 MB",
        sha256="D79B0E9D71696E6967A8F9051E62DA87E3AD797E76C6B9D931D66FCF7739BBDA",
    ),
    "qalun": OfficialSource(
        archive_version="7.0",
        displayed_archive_size="8.21 MB",
        sha256="32552185FDA5520EB4CAE741CC01162DC866FE3A224D921F4C182DE4A7B965D9",
    ),
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest().upper()


def _validate_member_name(name: str) -> str:
    if not name or "\\" in name or name.startswith("/") or ":" in name:
        raise ValueError(f"Unsafe ZIP member path: {name!r}")
    canonical_name = name[:-1] if name.endswith("/") else name
    parts = canonical_name.split("/")
    if not canonical_name or any(part in {"", ".", ".."} for part in parts):
        raise ValueError(f"Unsafe ZIP member path: {name!r}")
    if PurePosixPath(canonical_name).is_absolute():
        raise ValueError(f"Unsafe ZIP member path: {name!r}")
    return canonical_name


def inspect_archive(
    archive_path: Path,
    edition_id: str,
    *,
    expected_sha256: str | None = None,
) -> dict[str, Any]:
    """Verify a package hash and return a content-free, safe member inventory.

    ``expected_sha256`` exists for synthetic unit tests. Production CLI calls
    always use the hash published for ``edition_id`` in ``OFFICIAL_SOURCES``.
    """
    source = OFFICIAL_SOURCES.get(edition_id)
    if source is None:
        raise ValueError(f"Unsupported KFGQPC edition ID: {edition_id}")
    expected = (expected_sha256 or source.sha256).upper()
    if len(expected) != 64 or any(char not in "0123456789ABCDEF" for char in expected):
        raise ValueError("Expected SHA-256 must be exactly 64 hexadecimal characters")

    archive_path = archive_path.resolve(strict=True)
    archive_size = archive_path.stat().st_size
    if not archive_path.is_file():
        raise ValueError("Archive path must point to a regular file")
    if archive_size <= 0 or archive_size > MAX_ARCHIVE_BYTES:
        raise ValueError(
            f"Archive size must be between 1 byte and {MAX_ARCHIVE_BYTES} bytes"
        )

    actual_sha256 = sha256_file(archive_path)
    if actual_sha256 != expected:
        raise ValueError(
            "Archive checksum mismatch; refusing to inspect as official content. "
            f"Expected {expected}; received {actual_sha256}"
        )

    try:
        archive = zipfile.ZipFile(archive_path)
    except (OSError, zipfile.BadZipFile) as error:
        raise ValueError(f"Verified bytes are not a readable ZIP archive: {error}") from error

    with archive:
        members = archive.infolist()
        if not members or len(members) > MAX_MEMBER_COUNT:
            raise ValueError(
                f"ZIP member count must be between 1 and {MAX_MEMBER_COUNT}"
            )

        seen_names: set[str] = set()
        total_uncompressed = 0
        candidates: dict[str, list[dict[str, Any]]] = {
            "structuredData": [],
            "fonts": [],
            "documentation": [],
            "other": [],
        }
        extension_groups = {
            ".csv": "structuredData",
            ".json": "structuredData",
            ".sql": "structuredData",
            ".xml": "structuredData",
            ".xlsx": "structuredData",
            ".ttf": "fonts",
            ".otf": "fonts",
            ".woff": "fonts",
            ".woff2": "fonts",
            ".pdf": "documentation",
            ".doc": "documentation",
            ".docx": "documentation",
        }

        for member in members:
            canonical_name = _validate_member_name(member.filename)
            if canonical_name in seen_names:
                raise ValueError(f"Duplicate ZIP member path: {canonical_name}")
            seen_names.add(canonical_name)

            unix_mode = (member.external_attr >> 16) & 0o170000
            if unix_mode == stat.S_IFLNK:
                raise ValueError(f"ZIP symlinks are not allowed: {canonical_name}")
            if member.flag_bits & 0x1:
                raise ValueError(f"Encrypted ZIP members are not allowed: {canonical_name}")
            if member.is_dir():
                continue
            if member.file_size > MAX_MEMBER_BYTES:
                raise ValueError(f"ZIP member exceeds per-file limit: {canonical_name}")

            total_uncompressed += member.file_size
            if total_uncompressed > MAX_TOTAL_UNCOMPRESSED_BYTES:
                raise ValueError("ZIP exceeds the total uncompressed size limit")
            if member.file_size and not member.compress_size:
                raise ValueError(f"Invalid compressed size for {canonical_name}")
            if member.compress_size and member.file_size / member.compress_size > MAX_COMPRESSION_RATIO:
                raise ValueError(f"ZIP member compression ratio is unsafe: {canonical_name}")

            category = extension_groups.get(
                PurePosixPath(canonical_name).suffix.lower(), "other"
            )
            candidates[category].append(
                {
                    "path": canonical_name,
                    "bytes": member.file_size,
                    "compressedBytes": member.compress_size,
                }
            )

        corrupt_member = archive.testzip()
        if corrupt_member is not None:
            raise ValueError(f"ZIP CRC validation failed for {corrupt_member}")

    for entries in candidates.values():
        entries.sort(key=lambda entry: entry["path"])

    return {
        "editionId": edition_id,
        "archiveVersion": source.archive_version,
        "officialDisplayedArchiveSize": source.displayed_archive_size,
        "officialSourcePage": OFFICIAL_SOURCE_PAGE,
        "archiveBytes": archive_size,
        "sha256": actual_sha256,
        "memberCount": len(members),
        "uncompressedBytes": total_uncompressed,
        "members": candidates,
        "contentReviewStatus": "not-performed-by-archive-inspector",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--edition", choices=sorted(OFFICIAL_SOURCES), required=True)
    parser.add_argument("--archive", type=Path, required=True)
    args = parser.parse_args()

    try:
        report = inspect_archive(args.archive, args.edition)
    except (OSError, ValueError) as error:
        print(f"Archive inspection failed: {error}", file=sys.stderr)
        return 1

    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
