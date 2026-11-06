#!/usr/bin/env python3
"""Generate the pinned Warsh/Qalun page-art manifest from GitHub's tree API."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path


# Pin the canonical vector repository rather than a derived mirror. The
# repository documents the official KFQC source bundles and their checksums.
REPOSITORY = "quran-ws/quran-svg"
COMMIT = "b4155f07e4aea087d2c458069acff9f7c7e749f6"
EDITIONS = {"warsh": "warsh", "qalun": "qalon"}
OUTPUT = Path(__file__).resolve().parents[1] / "assets/data/quran/riwayah_page_art_manifest.json"


def main() -> None:
    editions: dict[str, object] = {}
    for app_id, source_id in EDITIONS.items():
        prefix = f"mushafs/{source_id}/kfqc/svg-br/"
        url = (
            f"https://api.github.com/repos/{REPOSITORY}/contents/{prefix}"
            f"?ref={COMMIT}"
        )
        request = urllib.request.Request(
            url, headers={"User-Agent": "TalibIlm-QuranManifest"}
        )
        with urllib.request.urlopen(request, timeout=45) as response:
            directory = json.load(response)
        pages = []
        for entry in directory:
            basename = entry["name"]
            if not basename.endswith(".svg.br"):
                continue
            number_text = basename.removesuffix(".svg.br")
            if len(number_text) != 3 or not number_text.isdigit():
                continue
            pages.append(
                {
                    "page": int(number_text),
                    "bytes": entry["size"],
                    "gitBlobSha1": entry["sha"],
                }
            )
        pages.sort(key=lambda page: page["page"])
        if len(pages) != 604 or [page["page"] for page in pages] != list(range(1, 605)):
            raise RuntimeError(f"Expected pages 1–604 for {app_id}; found {len(pages)}")
        editions[app_id] = {
            "sourceEdition": source_id,
            "pageCount": len(pages),
            "compressedBytes": sum(page["bytes"] for page in pages),
            "pages": pages,
        }

    manifest = {
        "schemaVersion": 1,
        "source": {
            "repository": REPOSITORY,
            "commit": COMMIT,
            "repositoryUrl": f"https://github.com/{REPOSITORY}",
            "noticeUrl": f"https://github.com/{REPOSITORY}/blob/{COMMIT}/NOTICE.md",
            "assetPattern": "mushafs/{sourceEdition}/kfqc/svg-br/{page:03d}.svg.br",
        },
        "editions": editions,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    for edition, data in editions.items():
        print(f"{edition}: {data['pageCount']} pages, {data['compressedBytes']:,} bytes")


if __name__ == "__main__":
    main()
