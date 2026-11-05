"""Synthetic safety tests for the official KFGQPC archive inspector."""

from __future__ import annotations

import hashlib
import tempfile
import unittest
import warnings
import zipfile
from pathlib import Path

from tool.inspect_kfgqpc_quran_archive import inspect_archive


class InspectKfgqpcArchiveTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory(prefix="kfgqpc_archive_test_")
        self.root = Path(self.temp_dir.name)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _zip(self, entries: list[tuple[str, bytes]]) -> Path:
        path = self.root / "synthetic-source.zip"
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for name, content in entries:
                archive.writestr(name, content)
        return path

    def test_matches_pinned_hash_and_lists_members_without_extracting(self) -> None:
        archive_path = self._zip(
            [
                ("developer/data.csv", b"synthetic fixture only"),
                ("developer/font.ttf", b"synthetic font placeholder"),
                ("README.txt", b"metadata fixture"),
            ]
        )
        expected = hashlib.sha256(archive_path.read_bytes()).hexdigest()

        report = inspect_archive(
            archive_path,
            "warsh",
            expected_sha256=expected,
        )

        self.assertEqual(report["sha256"], expected.upper())
        self.assertEqual(report["memberCount"], 3)
        self.assertIn(
            "developer/data.csv",
            [
                member["path"]
                for member in report["members"]["structuredData"]
            ],
        )
        self.assertEqual(
            report["members"]["other"][0]["path"], "README.txt"
        )
        self.assertEqual(report["members"]["fonts"][0]["path"], "developer/font.ttf")
        self.assertFalse((self.root / "developer").exists())
        self.assertEqual(
            report["contentReviewStatus"], "not-performed-by-archive-inspector"
        )

    def test_rejects_checksum_mismatch_before_reading_archive_members(self) -> None:
        archive_path = self._zip([("data.csv", b"synthetic fixture")])

        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            inspect_archive(archive_path, "warsh")

    def test_rejects_path_traversal_even_when_archive_hash_matches(self) -> None:
        archive_path = self._zip([("../outside.csv", b"synthetic fixture")])
        expected = hashlib.sha256(archive_path.read_bytes()).hexdigest()

        with self.assertRaisesRegex(ValueError, "Unsafe ZIP member path"):
            inspect_archive(archive_path, "qalun", expected_sha256=expected)

    def test_rejects_duplicate_normalized_paths(self) -> None:
        archive_path = self.root / "duplicate.zip"
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr("data/entry.csv", b"first")
                archive.writestr("data/entry.csv", b"second")
        expected = hashlib.sha256(archive_path.read_bytes()).hexdigest()

        with self.assertRaisesRegex(ValueError, "Duplicate ZIP member path"):
            inspect_archive(archive_path, "hafs", expected_sha256=expected)

    def test_rejects_symlink_members(self) -> None:
        archive_path = self.root / "symlink.zip"
        entry = zipfile.ZipInfo("data/link.csv")
        entry.external_attr = 0o120777 << 16
        with zipfile.ZipFile(archive_path, "w") as archive:
            archive.writestr(entry, b"../outside.csv")
        expected = hashlib.sha256(archive_path.read_bytes()).hexdigest()

        with self.assertRaisesRegex(ValueError, "symlinks are not allowed"):
            inspect_archive(archive_path, "hafs", expected_sha256=expected)


if __name__ == "__main__":
    unittest.main()
