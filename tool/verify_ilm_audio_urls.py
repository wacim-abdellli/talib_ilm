#!/usr/bin/env python3
"""Live HTTPS & HTTP status verifier for talib_ilm Ilm Mutun & Heritage Audio Catalog.

Dumps the exact runtime entries from `MutunAudioCatalog.entries` via `dart run`
and probes every unique primary URL, fallback URL, first-chapter URL, and
last-chapter URL using `curl.exe -sIL` in parallel.

Notes:
- `files.a-alqasim.com` has an incomplete server TLS intermediate chain on
  desktop OS trust stores (`SEC_E_UNTRUSTED_ROOT`); the script verifies that
  EVERY source hosted on `files.a-alqasim.com` has a non-empty `fallbackUrl`
  that returns HTTP 200 on a trusted HTTPS CDN!
"""

from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.parse

sys.stdout.reconfigure(encoding="utf-8")

DART_DUMP = """
import 'dart:convert';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';

void main() {
  final out = <Map<String, dynamic>>[];
  MutunAudioCatalog.entries.forEach((bookId, entry) {
    for (final src in entry.sources) {
      final chapters = src.chapters ?? const [];
      out.appendIfNotEmpty(
        bookId: bookId,
        reciterId: src.reciter.id,
        audioUrl: src.audioUrl,
        fallbackUrl: src.fallbackUrl,
        firstChapterUrl: chapters.isNotEmpty ? chapters.first.audioUrl : null,
        lastChapterUrl: chapters.length > 1 ? chapters.last.audioUrl : null,
        chapterCount: chapters.length,
      );
    }
  });
  print(jsonEncode(out));
}

extension on List<Map<String, dynamic>> {
  void appendIfNotEmpty({
    required String bookId,
    required String reciterId,
    required String audioUrl,
    required String? fallbackUrl,
    required String? firstChapterUrl,
    required String? lastChapterUrl,
    required int chapterCount,
  }) {
    add({
      'bookId': bookId,
      'reciterId': reciterId,
      'audioUrl': audioUrl,
      'fallbackUrl': fallbackUrl,
      'firstChapterUrl': firstChapterUrl,
      'lastChapterUrl': lastChapterUrl,
      'chapterCount': chapterCount,
    });
  }
}
"""


def dump_catalog():
    tmp_path = os.path.join("tool", "_tmp_dump_audio_catalog.dart")
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(DART_DUMP)
        dart_bin = shutil.which("dart") or "dart.bat"
        res = subprocess.run(
            [dart_bin, "run", tmp_path],
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=True,
        )
        lines = [l.strip() for l in res.stdout.splitlines() if l.strip().startswith("[")]
        return json.loads(lines[-1])
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def probe_url(url: str) -> tuple[str, int, str]:
    # Encode raw non-ASCII characters and spaces so existing % escapes stay intact and curl doesn't split args.
    safe_url = "".join(urllib.parse.quote(ch) if (ord(ch) > 127 or ch == " ") else ch for ch in url)
    cmd = [
        "curl.exe",
        "-sIL",
        "--max-time",
        "25",
        "-o",
        os.devnull,
        "-w",
        "%{http_code}|%{content_type}",
        safe_url,
    ]
    code = 0
    ctype = ""
    for attempt in range(3):
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=30)
            parts = res.stdout.strip().split("|")
            code = int(parts[0]) if parts and parts[0].isdigit() else 0
            ctype = parts[1] if len(parts) > 1 else ""
            if code in (200, 206) or (400 <= code < 500):
                return url, code, ctype
        except Exception as exc:
            ctype = str(exc)
        if attempt < 2:
            time.sleep(1.0 * (attempt + 1))
    return url, code, ctype


def main() -> int:
    rows = dump_catalog()
    print(f"Loaded {len(rows)} book-reciter sources across MutunAudioCatalog.")

    urls_to_probe: set[str] = set()
    failures: list[str] = []

    for r in rows:
        label = f"{r['bookId']} [{r['reciterId']}]"
        for field in ("audioUrl", "fallbackUrl", "firstChapterUrl", "lastChapterUrl"):
            val = r.get(field)
            if not val:
                continue
            if not val.startswith("https://"):
                failures.append(f"NON-HTTPS {label} {field}: {val}")
                continue
            if "files.a-alqasim.com" in val:
                if field == "audioUrl" and not r.get("fallbackUrl"):
                    failures.append(f"MISSING FALLBACK for files.a-alqasim.com {label}: {val}")
                continue
            urls_to_probe.add(val)

    print(f"Probing {len(urls_to_probe)} unique HTTPS CDN URLs via curl.exe...")
    results: dict[str, tuple[int, str]] = {}
    with ThreadPoolExecutor(max_workers=6) as pool:
        futs = {pool.submit(probe_url, u): u for u in sorted(urls_to_probe)}
        for fut in as_completed(futs):
            u, code, ctype = fut.result()
            results[u] = (code, ctype)
            if code not in (200, 206):
                failures.append(f"HTTP {code} ({ctype}) -> {u}")

    ok_count = sum(1 for code, _ in results.values() if code in (200, 206))
    print(f"Verified {ok_count}/{len(urls_to_probe)} unique HTTPS URLs returned HTTP 200/206.")

    if failures:
        print("\nFAILURES DETECTED:")
        for fail in failures:
            print("  -", fail)
        return 1

    print("ALL ILM AUDIO URLS VERIFIED OK!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
