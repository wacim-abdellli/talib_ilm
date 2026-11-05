#!/usr/bin/env python3
"""Compare indexed SQLite with one-file compressed JSON for Quran pack reads.

This is a storage-layout benchmark only. Its input is the locally cached
``quran`` package's Tanzil "Simple (Plain)" Hafs text, not the accepted
KFGQPC release source. Never use its generated temporary files as app content.

Run from the repository root:
  python tool/quran_pack_format_benchmark.py --source-dart <quran_text.dart>

The benchmark writes all generated content under a temporary directory and
prints metrics only. It intentionally does not print or retain Quran text.
"""

from __future__ import annotations

import argparse
import gzip
import json
import random
import re
import sqlite3
import statistics
import tempfile
import time
import tracemalloc
import unicodedata
from pathlib import Path
from typing import Any


SURAH_LINE = re.compile(r"^\s{2}(\d+): \{$")
AYAH_LINE = re.compile(r"^\s{4}(\d+): '((?:\\.|[^'])*)',?\s*$")
AYAH_KEY_ONLY = re.compile(r"^\s{4}(\d+):\s*$")
AYAH_CONTINUATION = re.compile(r"^\s{8}'((?:\\.|[^'])*)',?\s*$")


def load_legacy_hafs_proxy(source_path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    current_surah: int | None = None
    pending_ayah_number: int | None = None
    for line_number, line in enumerate(
        source_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if pending_ayah_number is not None:
            continuation_match = AYAH_CONTINUATION.match(line)
            if continuation_match is None:
                raise ValueError(
                    f"Expected wrapped ayah text immediately after line {line_number - 1}"
                )
            append_ayah(rows, current_surah, pending_ayah_number, continuation_match.group(1))
            pending_ayah_number = None
            continue
        surah_match = SURAH_LINE.match(line)
        if surah_match:
            current_surah = int(surah_match.group(1))
            continue
        ayah_key_match = AYAH_KEY_ONLY.match(line)
        if ayah_key_match:
            pending_ayah_number = int(ayah_key_match.group(1))
            continue
        ayah_match = AYAH_LINE.match(line)
        if not ayah_match:
            continue
        if current_surah is None:
            raise ValueError(f"Ayah appears before a surah at line {line_number}")
        encoded_text = ayah_match.group(2)
        if "\\" in encoded_text:
            raise ValueError(
                "Unexpected Dart string escape; inspect the source parser before benchmarking"
            )
        append_ayah(rows, current_surah, int(ayah_match.group(1)), encoded_text)
    if pending_ayah_number is not None:
        raise ValueError("Source ended before a wrapped ayah text value")
    if len(rows) != 6236:
        raise ValueError(
            f"Expected the legacy proxy to contain 6,236 verses; found {len(rows)}"
        )
    if {row["surahNumber"] for row in rows} != set(range(1, 115)):
        raise ValueError("Legacy proxy must include all 114 surahs")
    return rows


def append_ayah(
    rows: list[dict[str, Any]],
    surah_number: int | None,
    ayah_number: int,
    encoded_text: str,
) -> None:
    if surah_number is None:
        raise ValueError("Ayah appears before a surah declaration")
    if "\\" in encoded_text:
        raise ValueError("Unexpected Dart string escape in source text")
    rows.append(
        {
            "surahNumber": surah_number,
            "ayahNumber": ayah_number,
            "sequence": len(rows) + 1,
            "displayText": encoded_text,
            "searchText": normalize_search(encoded_text),
        }
    )


def normalize_search(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text)
    return "".join(
        char
        for char in decomposed
        if char != "ـ" and not unicodedata.category(char).startswith("M")
    )


def percentile(samples_ns: list[int], fraction: float) -> float:
    ordered = sorted(samples_ns)
    index = min(len(ordered) - 1, round((len(ordered) - 1) * fraction))
    return ordered[index] / 1_000_000


def measure_repeated(operation: Any, count: int = 1000) -> dict[str, float]:
    samples: list[int] = []
    for _ in range(count):
        started = time.perf_counter_ns()
        operation()
        samples.append(time.perf_counter_ns() - started)
    return {
        "p50_ms": round(percentile(samples, 0.50), 4),
        "p95_ms": round(percentile(samples, 0.95), 4),
        "mean_ms": round(statistics.fmean(samples) / 1_000_000, 4),
        "iterations": count,
    }


def build_sqlite(path: Path, rows: list[dict[str, Any]]) -> None:
    with sqlite3.connect(path) as connection:
        connection.execute("PRAGMA page_size = 4096")
        connection.execute("PRAGMA journal_mode = OFF")
        connection.execute("PRAGMA synchronous = OFF")
        connection.executescript(
            """
            CREATE TABLE surah (
              surah_number INTEGER PRIMARY KEY,
              first_ayah_number INTEGER NOT NULL,
              last_ayah_number INTEGER NOT NULL
            );
            CREATE TABLE ayah (
              surah_number INTEGER NOT NULL,
              ayah_number INTEGER NOT NULL,
              sequence INTEGER NOT NULL UNIQUE,
              display_text TEXT NOT NULL,
              search_text TEXT NOT NULL,
              PRIMARY KEY (surah_number, ayah_number),
              FOREIGN KEY (surah_number) REFERENCES surah(surah_number)
            ) WITHOUT ROWID;
            CREATE INDEX ayah_sequence_idx ON ayah(sequence);
            CREATE INDEX ayah_search_idx ON ayah(search_text);
            """
        )
        surah_bounds: dict[int, list[int]] = {}
        for row in rows:
            bounds = surah_bounds.setdefault(row["surahNumber"], [])
            bounds.append(row["ayahNumber"])
        connection.executemany(
            "INSERT INTO surah VALUES (?, ?, ?)",
            [
                (number, min(ayahs), max(ayahs))
                for number, ayahs in sorted(surah_bounds.items())
            ],
        )
        connection.executemany(
            "INSERT INTO ayah VALUES (?, ?, ?, ?, ?)",
            [
                (
                    row["surahNumber"],
                    row["ayahNumber"],
                    row["sequence"],
                    row["displayText"],
                    row["searchText"],
                )
                for row in rows
            ],
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dart",
        required=True,
        type=Path,
        help="Path to the locally cached quran package's lib/quran_text.dart",
    )
    args = parser.parse_args()
    source_path = args.source_dart.resolve(strict=True)
    rows = load_legacy_hafs_proxy(source_path)
    json_bytes = json.dumps(
        {"schemaVersion": 1, "surahCount": 114, "ayahs": rows},
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")
    random.seed(20261105)
    sample = random.choice(rows)

    with tempfile.TemporaryDirectory(prefix="quran_pack_benchmark_") as temp:
        temp_dir = Path(temp)
        json_path = temp_dir / "proxy.json"
        database_path = temp_dir / "proxy.sqlite"
        json_path.write_bytes(json_bytes)
        build_sqlite(database_path, rows)
        json_gzip = gzip.compress(json_bytes, compresslevel=9, mtime=0)
        sqlite_bytes = database_path.read_bytes()
        sqlite_gzip = gzip.compress(sqlite_bytes, compresslevel=9, mtime=0)

        tracemalloc.start()
        parse_started = time.perf_counter_ns()
        decoded = json.loads(json_path.read_text(encoding="utf-8"))
        json_parse_ms = (time.perf_counter_ns() - parse_started) / 1_000_000
        _, json_peak_memory_bytes = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        json_lookup = {
            (row["surahNumber"], row["ayahNumber"]): row
            for row in decoded["ayahs"]
        }
        if json_lookup[(sample["surahNumber"], sample["ayahNumber"])][
            "displayText"
        ] != sample["displayText"]:
            raise ValueError("JSON lookup did not preserve source proxy text")

        connection = sqlite3.connect(database_path)
        sqlite_value = connection.execute(
            "SELECT display_text FROM ayah WHERE surah_number = ? AND ayah_number = ?",
            (sample["surahNumber"], sample["ayahNumber"]),
        ).fetchone()
        if sqlite_value is None or sqlite_value[0] != sample["displayText"]:
            raise ValueError("SQLite lookup did not preserve source proxy text")

        json_surahs: dict[int, list[dict[str, Any]]] = {}
        for row in decoded["ayahs"]:
            json_surahs.setdefault(row["surahNumber"], []).append(row)

        results = {
            "warning": "Tanzil Simple (Plain) Hafs proxy only; not an accepted KFGQPC pack or release-size result.",
            "records": len(rows),
            "surahs": len({row['surahNumber'] for row in rows}),
            "sampleCoordinate": {
                "surah": sample["surahNumber"],
                "ayah": sample["ayahNumber"],
            },
            "bytes": {
                "json": len(json_bytes),
                "jsonGzip9": len(json_gzip),
                "sqlite": len(sqlite_bytes),
                "sqliteGzip9": len(sqlite_gzip),
            },
            "json": {
                "parseMs": round(json_parse_ms, 3),
                "pythonPeakBytesDuringParse": json_peak_memory_bytes,
                "randomAyahLookup": measure_repeated(
                    lambda: json_lookup[(sample["surahNumber"], sample["ayahNumber"])]
                ),
                "fullSurahRead": measure_repeated(
                    lambda: json_surahs[sample["surahNumber"]]
                ),
            },
            "sqlite": {
                "randomAyahLookup": measure_repeated(
                    lambda: connection.execute(
                        "SELECT display_text FROM ayah WHERE surah_number = ? AND ayah_number = ?",
                        (sample["surahNumber"], sample["ayahNumber"]),
                    ).fetchone()
                ),
                "fullSurahRead": measure_repeated(
                    lambda: connection.execute(
                        "SELECT ayah_number, display_text FROM ayah WHERE surah_number = ? ORDER BY ayah_number",
                        (sample["surahNumber"],),
                    ).fetchall()
                ),
            },
        }
        connection.close()
        print(json.dumps(results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
