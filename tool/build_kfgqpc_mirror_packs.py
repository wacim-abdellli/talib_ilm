#!/usr/bin/env python3
"""Build local SQLite Quran packs from a commit-pinned KFGQPC GitHub mirror.

The source repository claims these data/font files originate from KFGQPC. This
builder pins the Git commit and each exact file hash, validates edition-scoped
coordinates, preserves display text byte-for-code-point, and writes SQLite plus
the matching font to an output directory. It does not sign a release manifest,
publish a pack, or independently prove the mirror matches KFGQPC's archive.

Usage:
  python tool/build_kfgqpc_mirror_packs.py \
    --source-dir C:/path/to/source-files \
    --output-dir C:/path/to/local-pack-output \
    --fetch-missing
"""

from __future__ import annotations

import argparse
from contextlib import closing
import hashlib
import json
import os
import re
import shutil
import sqlite3
import sys
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SOURCES_PATH = Path(__file__).with_name("quran_mirror_sources.json")
PACK_SCHEMA_VERSION = 1
APPLICATION_ID = 0x514D5348  # "QMSH"
MAX_SOURCE_FILE_BYTES = 16 * 1024 * 1024


@dataclass(frozen=True)
class NormalizedAyah:
    source_id: int
    surah_number: int
    ayah_number: int
    display_text: str
    search_text: str | None
    juz_number: int
    page_start: int
    page_end: int
    line_start: int
    line_end: int


@dataclass(frozen=True)
class NormalizedSurah:
    surah_number: int
    name_ar: str
    name_en: str
    ayah_count: int
    page_start: int
    page_end: int


@dataclass(frozen=True)
class ValidatedEdition:
    edition_id: str
    spec: dict[str, Any]
    rows: tuple[NormalizedAyah, ...]
    surahs: tuple[NormalizedSurah, ...]
    source_sha256: str
    font_sha256: str
    display_text_sha256: str


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        while chunk := file.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest().upper()


def git_blob_sha1_file(path: Path) -> str:
    size = path.stat().st_size
    digest = hashlib.sha1()
    digest.update(f"blob {size}\0".encode("ascii"))
    with path.open("rb") as file:
        while chunk := file.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def load_sources(path: Path = SOURCES_PATH) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read source pins at {path}: {error}") from error
    if not isinstance(value, dict) or not isinstance(value.get("editions"), dict):
        raise ValueError("Source pin file has an invalid top-level structure")
    return value


def _source_url(sources: dict[str, Any], asset: dict[str, Any]) -> str:
    repository = str(sources["sourceRepository"]).rstrip("/")
    commit = str(sources["sourceCommit"])
    return f"{repository.replace('github.com/', 'raw.githubusercontent.com/')}/{commit}/{asset['repositoryPath']}"


def _fetch_asset(path: Path, url: str, expected_size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "TalibIlm-QuranPack-Builder/1"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            declared_size = response.headers.get("Content-Length")
            if declared_size and int(declared_size) != expected_size:
                raise ValueError(
                    f"Source length differs from pinned size for {path.name}"
                )
            remaining = expected_size
            descriptor, temporary_name = tempfile.mkstemp(
                prefix=f".{path.name}.", suffix=".download", dir=path.parent
            )
            temporary_path = Path(temporary_name)
            with os.fdopen(descriptor, "wb") as output:
                while chunk := response.read(1024 * 1024):
                    remaining -= len(chunk)
                    if remaining < 0:
                        raise ValueError(f"Source exceeded pinned size for {path.name}")
                    output.write(chunk)
    except (OSError, urllib.error.URLError, TimeoutError, ValueError) as error:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        raise ValueError(f"Could not fetch pinned source file {path.name}: {error}") from error
    if remaining != 0:
        assert temporary_path is not None
        temporary_path.unlink(missing_ok=True)
        raise ValueError(f"Source was truncated while fetching {path.name}")
    assert temporary_path is not None
    if path.exists():
        temporary_path.unlink(missing_ok=True)
        raise ValueError(f"Refusing to overwrite an existing source file: {path}")
    os.replace(temporary_path, path)


def verify_asset(
    source_dir: Path,
    asset: dict[str, Any],
    sources: dict[str, Any],
    *,
    fetch_missing: bool,
) -> Path:
    path = source_dir / str(asset["filename"])
    if not path.exists() and fetch_missing:
        _fetch_asset(path, _source_url(sources, asset), int(asset["sizeBytes"]))
    try:
        resolved_source = source_dir.resolve(strict=True)
        resolved_path = path.resolve(strict=True)
    except OSError as error:
        raise ValueError(f"Source file is missing: {path}") from error
    if resolved_source not in resolved_path.parents:
        raise ValueError(f"Source file escaped the selected source directory: {path}")
    if not resolved_path.is_file():
        raise ValueError(f"Source path is not a regular file: {path}")
    if resolved_path.stat().st_size > MAX_SOURCE_FILE_BYTES:
        raise ValueError(f"Source file exceeds size limit: {path.name}")
    if resolved_path.stat().st_size != int(asset["sizeBytes"]):
        raise ValueError(f"Source size differs from the pinned size: {path.name}")
    actual_sha256 = sha256_file(resolved_path)
    if actual_sha256 != str(asset["sha256"]).upper():
        raise ValueError(
            f"Source SHA-256 mismatch for {path.name}: expected {asset['sha256']}, "
            f"received {actual_sha256}"
        )
    actual_git_blob = git_blob_sha1_file(resolved_path)
    if actual_git_blob != str(asset["gitBlobSha1"]).lower():
        raise ValueError(f"Source file does not match the pinned Git object: {path.name}")
    return resolved_path


def parse_page_range(value: Any, page_count: int) -> tuple[int, int]:
    if isinstance(value, bool):
        raise ValueError("Boolean is not a valid page coordinate")
    if isinstance(value, int):
        start = end = value
    elif isinstance(value, str):
        match = re.fullmatch(r"\s*([1-9][0-9]*)(?:\s*[-–—]\s*([1-9][0-9]*))?\s*", value)
        if match is None:
            raise ValueError("Page coordinate has an unsupported format")
        start = int(match.group(1))
        end = int(match.group(2) or match.group(1))
    else:
        raise ValueError("Page coordinate must be an integer or page/range string")

    if start < 1 or end < start or end > page_count or end - start > 1:
        raise ValueError("Page coordinate is outside the supported one-page span")
    return start, end


def _integer_field(row: dict[str, Any], name: str, field_label: str) -> int:
    value = row.get(name)
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"Invalid integer field '{field_label}' at source row {row.get('id')}")
    return value


def validate_rows(
    rows: Any,
    edition_id: str,
    spec: dict[str, Any],
    source_sha256: str,
    font_sha256: str,
) -> ValidatedEdition:
    if not isinstance(rows, list):
        raise ValueError(f"{edition_id} source JSON must be an array of records")
    expected_count = int(spec["expectedAyahCount"])
    expected_surahs = int(spec["expectedSurahCount"])
    page_count = int(spec["pageCount"])
    if len(rows) != expected_count:
        raise ValueError(
            f"{edition_id} record count mismatch: expected {expected_count}, received {len(rows)}"
        )

    fields = spec["fields"]
    normalized: list[NormalizedAyah] = []
    names_by_surah: dict[int, tuple[str, str]] = {}
    ayahs_by_surah: dict[int, list[int]] = {}
    covered_pages: set[int] = set()
    display_text_digest = hashlib.sha256()
    previous_page_start = 0

    for expected_id, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            raise ValueError(f"Invalid source record at row {expected_id}")
        source_id = _integer_field(row, str(fields["id"]), "id")
        surah = _integer_field(row, str(fields["surah"]), "surah")
        ayah = _integer_field(row, str(fields["ayah"]), "ayah")
        juz = _integer_field(row, str(fields["juz"]), "juz")
        line_start = _integer_field(row, str(fields["lineStart"]), "lineStart")
        line_end = _integer_field(row, str(fields["lineEnd"]), "lineEnd")
        if source_id != expected_id:
            raise ValueError(f"{edition_id} source IDs are not contiguous and ordered")
        if not 1 <= surah <= expected_surahs or ayah < 1:
            raise ValueError(f"Invalid verse coordinate at source row {source_id}")
        if not 1 <= juz <= 30:
            raise ValueError(f"Invalid juz coordinate at source row {source_id}")
        if not 1 <= line_start <= 15 or not 1 <= line_end <= 15:
            raise ValueError(f"Invalid line coordinate at source row {source_id}")

        raw_text = row.get(str(fields["displayText"]))
        if not isinstance(raw_text, str) or not raw_text:
            raise ValueError(f"Missing display text at source row {source_id}")
        search_field = fields.get("searchText")
        search_text = row.get(str(search_field)) if search_field else None
        if search_field and search_text is not None and not isinstance(search_text, str):
            raise ValueError(f"Invalid search text at source row {source_id}")

        name_ar = row.get(str(fields["surahNameAr"]))
        name_en = row.get(str(fields["surahNameEn"]))
        if not isinstance(name_ar, str) or not name_ar:
            raise ValueError(f"Missing Arabic surah name at source row {source_id}")
        if not isinstance(name_en, str) or not name_en:
            raise ValueError(f"Missing English surah name at source row {source_id}")
        current_names = (name_ar, name_en)
        previous_names = names_by_surah.setdefault(surah, current_names)
        if previous_names != current_names:
            raise ValueError(f"Surah names change within surah {surah} in {edition_id}")

        page_start, page_end = parse_page_range(row.get(str(fields["page"])), page_count)
        if page_start < previous_page_start:
            raise ValueError(f"Page mappings move backwards at source row {source_id}")
        previous_page_start = page_start
        if page_start == page_end and line_end < line_start:
            raise ValueError(f"Single-page line range reverses at source row {source_id}")
        if page_end > page_start and line_end >= line_start:
            raise ValueError(f"Cross-page line range is inconsistent at source row {source_id}")
        covered_pages.update(range(page_start, page_end + 1))
        ayahs_by_surah.setdefault(surah, []).append(ayah)

        normalized.append(
            NormalizedAyah(
                source_id=source_id,
                surah_number=surah,
                ayah_number=ayah,
                display_text=raw_text,
                search_text=search_text,
                juz_number=juz,
                page_start=page_start,
                page_end=page_end,
                line_start=line_start,
                line_end=line_end,
            )
        )
        display_text_digest.update(
            f"{source_id}\0{surah}\0{ayah}\0{raw_text}\0".encode("utf-8")
        )

    expected_surah_numbers = set(range(1, expected_surahs + 1))
    if set(ayahs_by_surah) != expected_surah_numbers:
        raise ValueError(f"{edition_id} source does not contain exactly 114 surahs")
    if covered_pages != set(range(1, page_count + 1)):
        raise ValueError(f"{edition_id} page mappings do not cover the declared mushaf")
    for surah, ayah_numbers in ayahs_by_surah.items():
        if ayah_numbers != list(range(1, len(ayah_numbers) + 1)):
            raise ValueError(f"{edition_id} ayah numbering has a gap in surah {surah}")

    normalized_surahs = []
    for surah in range(1, expected_surahs + 1):
        verses = [row for row in normalized if row.surah_number == surah]
        names = names_by_surah[surah]
        normalized_surahs.append(
            NormalizedSurah(
                surah_number=surah,
                name_ar=names[0],
                name_en=names[1],
                ayah_count=len(verses),
                page_start=min(row.page_start for row in verses),
                page_end=max(row.page_end for row in verses),
            )
        )

    return ValidatedEdition(
        edition_id=edition_id,
        spec=spec,
        rows=tuple(normalized),
        surahs=tuple(normalized_surahs),
        source_sha256=source_sha256,
        font_sha256=font_sha256,
        display_text_sha256=display_text_digest.hexdigest().upper(),
    )


def build_sqlite_database(
    edition: ValidatedEdition,
    database_path: Path,
    sources: dict[str, Any],
) -> None:
    database_path.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(database_path)) as database:
        database.execute(f"PRAGMA application_id = {APPLICATION_ID}")
        database.execute(f"PRAGMA user_version = {PACK_SCHEMA_VERSION}")
        database.execute("PRAGMA page_size = 4096")
        database.execute("PRAGMA journal_mode = DELETE")
        database.execute("PRAGMA synchronous = FULL")
        database.execute("PRAGMA foreign_keys = ON")
        database.executescript(
            """
            CREATE TABLE pack_metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            ) WITHOUT ROWID;
            CREATE TABLE surahs (
              surah_number INTEGER PRIMARY KEY,
              name_ar TEXT NOT NULL,
              name_en TEXT NOT NULL,
              ayah_count INTEGER NOT NULL,
              page_start INTEGER NOT NULL,
              page_end INTEGER NOT NULL
            );
            CREATE TABLE ayahs (
              surah_number INTEGER NOT NULL REFERENCES surahs(surah_number),
              ayah_number INTEGER NOT NULL,
              source_id INTEGER NOT NULL UNIQUE,
              display_text TEXT NOT NULL,
              search_text TEXT,
              juz_number INTEGER NOT NULL,
              page_start INTEGER NOT NULL,
              page_end INTEGER NOT NULL,
              line_start INTEGER NOT NULL,
              line_end INTEGER NOT NULL,
              PRIMARY KEY (surah_number, ayah_number)
            ) WITHOUT ROWID;
            CREATE INDEX ayahs_by_page
              ON ayahs(page_start, page_end, surah_number, ayah_number);
            CREATE INDEX ayahs_by_juz
              ON ayahs(juz_number, surah_number, ayah_number);
            """
        )
        metadata = {
            "edition_id": edition.edition_id,
            "schema_version": str(PACK_SCHEMA_VERSION),
            "source_repository": sources["sourceRepository"],
            "source_commit": sources["sourceCommit"],
            "source_commit_date": sources["sourceCommitDate"],
            "source_verification_status": sources["sourceVerificationStatus"],
            "source_data_sha256": edition.source_sha256,
            "source_font_sha256": edition.font_sha256,
            "display_text_sha256": edition.display_text_sha256,
            "data_version": str(edition.spec["dataVersion"]),
            "ayah_count": str(len(edition.rows)),
            "surah_count": str(len(edition.surahs)),
            "page_count": str(edition.spec["pageCount"]),
        }
        database.executemany(
            "INSERT INTO pack_metadata(key, value) VALUES (?, ?)",
            sorted(metadata.items()),
        )
        database.executemany(
            """INSERT INTO surahs(
                 surah_number, name_ar, name_en, ayah_count, page_start, page_end
               ) VALUES (?, ?, ?, ?, ?, ?)""",
            [
                (
                    surah.surah_number,
                    surah.name_ar,
                    surah.name_en,
                    surah.ayah_count,
                    surah.page_start,
                    surah.page_end,
                )
                for surah in edition.surahs
            ],
        )
        database.executemany(
            """INSERT INTO ayahs(
                 surah_number, ayah_number, source_id, display_text, search_text,
                 juz_number, page_start, page_end, line_start, line_end
               ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            [
                (
                    row.surah_number,
                    row.ayah_number,
                    row.source_id,
                    row.display_text,
                    row.search_text,
                    row.juz_number,
                    row.page_start,
                    row.page_end,
                    row.line_start,
                    row.line_end,
                )
                for row in edition.rows
            ],
        )
        packed_text_digest = hashlib.sha256()
        packed_row_count = 0
        for row in database.execute(
            """SELECT source_id, surah_number, ayah_number, display_text
               FROM ayahs ORDER BY source_id"""
        ):
            source_id, surah_number, ayah_number, display_text = row
            packed_text_digest.update(
                f"{source_id}\0{surah_number}\0{ayah_number}\0{display_text}\0".encode(
                    "utf-8"
                )
            )
            packed_row_count += 1
        if packed_row_count != len(edition.rows):
            raise ValueError("SQLite pack lost or duplicated ayah records")
        if packed_text_digest.hexdigest().upper() != edition.display_text_sha256:
            raise ValueError("SQLite pack changed display-text code points")
        integrity = database.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise ValueError(f"SQLite integrity check failed: {integrity}")
        foreign_key_errors = database.execute("PRAGMA foreign_key_check").fetchall()
        if foreign_key_errors:
            raise ValueError("SQLite foreign-key validation failed")
        database.commit()
        database.execute("VACUUM")


def _asset_entry(path: Path, relative_path: str, role: str) -> dict[str, Any]:
    return {
        "path": relative_path,
        "role": role,
        "bytes": path.stat().st_size,
        "sha256": sha256_file(path),
    }


def build_pack(
    edition: ValidatedEdition,
    source_dir: Path,
    output_dir: Path,
    sources: dict[str, Any],
) -> dict[str, Any]:
    final_dir = output_dir / edition.edition_id
    if final_dir.exists():
        raise ValueError(f"Output pack already exists; refusing to overwrite: {final_dir}")
    output_dir.mkdir(parents=True, exist_ok=True)
    staging_dir = Path(
        tempfile.mkdtemp(prefix=f".{edition.edition_id}.staging-", dir=output_dir)
    )
    spec = edition.spec
    try:
        database_path = staging_dir / "content" / "quran.sqlite"
        font_path = staging_dir / "fonts" / "riwayah.ttf"
        build_sqlite_database(edition, database_path, sources)

        font_source = source_dir / str(spec["font"]["filename"])
        font_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(font_source, font_path)
        if sha256_file(font_path) != edition.font_sha256:
            raise ValueError(f"Copied font changed unexpectedly for {edition.edition_id}")

        assets = [
            _asset_entry(database_path, "content/quran.sqlite", "quran-database"),
            _asset_entry(font_path, "fonts/riwayah.ttf", "riwayah-font"),
        ]
        pack_report = {
            "format": "talib-ilm-local-quran-pack-build",
            "formatVersion": 1,
            "editionId": edition.edition_id,
            "dataVersion": str(spec["dataVersion"]),
            "source": {
                "repository": sources["sourceRepository"],
                "commit": sources["sourceCommit"],
                "commitDate": sources["sourceCommitDate"],
                "dataPath": spec["data"]["repositoryPath"],
                "dataSha256": edition.source_sha256,
                "fontPath": spec["font"]["repositoryPath"],
                "fontSha256": edition.font_sha256,
                "verificationStatus": sources["sourceVerificationStatus"],
                "repositoryLicense": sources["repositoryLicense"],
            },
            "counts": {
                "surahs": len(edition.surahs),
                "ayahs": len(edition.rows),
                "pages": int(spec["pageCount"]),
            },
            "assets": assets,
            "releaseReady": False,
        }
        (staging_dir / "pack-build.json").write_text(
            json.dumps(pack_report, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
            encoding="utf-8",
        )
        os.replace(staging_dir, final_dir)
    except Exception:
        shutil.rmtree(staging_dir, ignore_errors=True)
        raise

    return {
        "editionId": edition.edition_id,
        "output": str(final_dir),
        "counts": pack_report["counts"],
        "assets": pack_report["assets"],
        "releaseReady": False,
    }


def build_packs(
    source_dir: Path,
    output_dir: Path,
    edition_ids: list[str],
    *,
    fetch_missing: bool = False,
    sources_path: Path = SOURCES_PATH,
) -> list[dict[str, Any]]:
    sources = load_sources(sources_path)
    source_dir.mkdir(parents=True, exist_ok=True)
    validated: list[tuple[ValidatedEdition, Path]] = []

    for edition_id in edition_ids:
        spec = sources["editions"].get(edition_id)
        if not isinstance(spec, dict):
            raise ValueError(f"Unsupported edition ID: {edition_id}")
        data_path = verify_asset(
            source_dir, spec["data"], sources, fetch_missing=fetch_missing
        )
        font_path = verify_asset(
            source_dir, spec["font"], sources, fetch_missing=fetch_missing
        )
        try:
            source_rows = json.loads(data_path.read_text(encoding="utf-8-sig"))
        except (OSError, json.JSONDecodeError) as error:
            raise ValueError(f"Cannot parse pinned data file {data_path.name}: {error}") from error
        edition = validate_rows(
            source_rows,
            edition_id,
            spec,
            str(spec["data"]["sha256"]).upper(),
            str(spec["font"]["sha256"]).upper(),
        )
        validated.append((edition, font_path))

    # Validate all source artifacts before writing the first pack.
    reports = []
    for edition, _font_path in validated:
        reports.append(build_pack(edition, source_dir, output_dir, sources))
    return reports


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument(
        "--edition",
        choices=["all", "hafs", "warsh", "qalun"],
        default="all",
    )
    parser.add_argument(
        "--fetch-missing",
        action="store_true",
        help="Download missing assets from the pinned GitHub commit and verify their hashes.",
    )
    args = parser.parse_args()
    editions = ["hafs", "warsh", "qalun"] if args.edition == "all" else [args.edition]

    try:
        reports = build_packs(
            args.source_dir.resolve(),
            args.output_dir.resolve(),
            editions,
            fetch_missing=args.fetch_missing,
        )
    except (OSError, ValueError, sqlite3.Error) as error:
        print(f"Pack build failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(reports, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
