"""Synthetic tests for the pinned Quran pack builder."""

from __future__ import annotations

import hashlib
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

from tool.build_kfgqpc_mirror_packs import (
    build_sqlite_database,
    git_blob_sha1_file,
    parse_page_range,
    validate_rows,
    verify_asset,
)


def synthetic_spec() -> dict[str, object]:
    return {
        "expectedAyahCount": 3,
        "expectedSurahCount": 2,
        "pageCount": 2,
        "dataVersion": "fixture",
        "fields": {
            "id": "id",
            "surah": "surah",
            "ayah": "ayah",
            "displayText": "display",
            "searchText": "search",
            "juz": "juz",
            "page": "page",
            "lineStart": "line_start",
            "lineEnd": "line_end",
            "surahNameAr": "surah_ar",
            "surahNameEn": "surah_en",
        },
    }


def synthetic_rows() -> list[dict[str, object]]:
    return [
        {
            "id": 1,
            "surah": 1,
            "ayah": 1,
            "display": "synthetic source text A",
            "search": "synthetic A",
            "juz": 1,
            "page": 1,
            "line_start": 1,
            "line_end": 2,
            "surah_ar": "fixture one",
            "surah_en": "Fixture One",
        },
        {
            "id": 2,
            "surah": 1,
            "ayah": 2,
            "display": "synthetic source text B",
            "search": "synthetic B",
            "juz": 1,
            "page": "1-2",
            "line_start": 15,
            "line_end": 1,
            "surah_ar": "fixture one",
            "surah_en": "Fixture One",
        },
        {
            "id": 3,
            "surah": 2,
            "ayah": 1,
            "display": "synthetic source text C",
            "search": "synthetic C",
            "juz": 1,
            "page": 2,
            "line_start": 2,
            "line_end": 3,
            "surah_ar": "fixture two",
            "surah_en": "Fixture Two",
        },
    ]


class QuranMirrorPackBuilderTests(unittest.TestCase):
    def test_accepts_single_and_cross_page_coordinates(self) -> None:
        self.assertEqual(parse_page_range(12, 20), (12, 12))
        self.assertEqual(parse_page_range("12-13", 20), (12, 13))
        self.assertEqual(parse_page_range("12–13", 20), (12, 13))

    def test_rejects_unsupported_or_out_of_range_page_coordinates(self) -> None:
        for value in ("0", "2-4", "2/a", True, 21):
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_page_range(value, 20)

    def test_validates_and_preserves_cross_page_line_coordinates(self) -> None:
        edition = validate_rows(
            synthetic_rows(),
            "fixture",
            synthetic_spec(),
            "A" * 64,
            "B" * 64,
        )

        self.assertEqual(len(edition.rows), 3)
        self.assertEqual(edition.rows[1].page_start, 1)
        self.assertEqual(edition.rows[1].page_end, 2)
        self.assertEqual(edition.rows[1].line_start, 15)
        self.assertEqual(edition.rows[1].line_end, 1)
        self.assertEqual(edition.rows[1].display_text, "synthetic source text B")

    def test_rejects_missing_ayah_number_without_guessing(self) -> None:
        rows = synthetic_rows()
        rows[1]["ayah"] = 3
        with self.assertRaisesRegex(ValueError, "numbering has a gap"):
            validate_rows(rows, "fixture", synthetic_spec(), "A" * 64, "B" * 64)

    def test_rejects_page_mapping_that_moves_backwards(self) -> None:
        rows = synthetic_rows()
        rows[0]["page"] = 2
        with self.assertRaisesRegex(ValueError, "move backwards"):
            validate_rows(rows, "fixture", synthetic_spec(), "A" * 64, "B" * 64)

    def test_verifies_asset_against_both_sha256_and_git_blob_pin(self) -> None:
        content = b"synthetic pinned fixture"
        with tempfile.TemporaryDirectory(prefix="quran_source_pin_test_") as folder:
            source_dir = Path(folder)
            source_path = source_dir / "fixture.json"
            source_path.write_bytes(content)
            asset = {
                "filename": source_path.name,
                "repositoryPath": "fixture.json",
                "sizeBytes": len(content),
                "sha256": hashlib.sha256(content).hexdigest(),
                "gitBlobSha1": git_blob_sha1_file(source_path),
            }
            sources = {
                "sourceRepository": "https://example.invalid/source",
                "sourceCommit": "fixture-commit",
            }

            self.assertEqual(
                verify_asset(source_dir, asset, sources, fetch_missing=False),
                source_path,
            )
            asset["sha256"] = "0" * 64
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                verify_asset(source_dir, asset, sources, fetch_missing=False)

    def test_sqlite_pack_stores_text_and_page_spans_without_rewriting(self) -> None:
        edition = validate_rows(
            synthetic_rows(),
            "fixture",
            synthetic_spec(),
            "A" * 64,
            "B" * 64,
        )
        sources = {
            "sourceRepository": "https://example.invalid/source",
            "sourceCommit": "fixture-commit",
            "sourceCommitDate": "2000-01-01T00:00:00Z",
            "sourceVerificationStatus": "synthetic-fixture",
        }

        with tempfile.TemporaryDirectory(prefix="quran_pack_builder_test_") as folder:
            database_path = Path(folder) / "content" / "quran.sqlite"
            build_sqlite_database(edition, database_path, sources)

            with closing(sqlite3.connect(database_path)) as database:
                self.assertEqual(
                    database.execute("PRAGMA integrity_check").fetchone()[0],
                    "ok",
                )
                row = database.execute(
                    """SELECT display_text, page_start, page_end,
                              line_start, line_end
                       FROM ayahs WHERE surah_number = 1 AND ayah_number = 2"""
                ).fetchone()
                self.assertEqual(
                    row,
                    ("synthetic source text B", 1, 2, 15, 1),
                )
                self.assertEqual(
                    database.execute(
                        "SELECT value FROM pack_metadata WHERE key = 'edition_id'"
                    ).fetchone()[0],
                    "fixture",
                )


if __name__ == "__main__":
    unittest.main()
