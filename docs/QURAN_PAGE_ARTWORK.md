# Warsh and Qalun page artwork

Warsh and Qalun now use the pinned King Fahd Complex page vectors from
[`quran-svg-with-aya-clickable-layer`](https://github.com/AhmedAbuelenin/quran-svg-with-aya-clickable-layer)
at commit `5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2`. Each edition has 604
compressed SVG pages. The page vectors preserve the printed edition's glyph
shapes, line breaks, surah plaques, ayah markers, and page proportions instead
of reconstructing a page from verse text.

The app ships only a small manifest containing the page sizes and pinned Git
blob hashes. It fetches a page from GitHub Raw, then jsDelivr as a mirror, the
first time that page is opened. Verified compressed pages stay in the edition's
local Quran pack directory. Users can optionally download all pages from the
reader settings for offline access; the full artwork is about 69.5 MiB for
Warsh and 74.4 MiB for Qalun. The APK does not bundle these page files.

The manifest can be regenerated with:

```powershell
python tool/generate_riwayah_page_manifest.py
```

The upstream repository's `NOTICE.md` records its source and licensing notes.
Review that notice and the King Fahd Complex terms before changing the pinned
edition or reusing these assets outside the app.
