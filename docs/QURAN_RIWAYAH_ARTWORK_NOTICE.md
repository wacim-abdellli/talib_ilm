# Quran page artwork source and coverage

Warsh and Qālūn reader pages are fetched page-by-page from the pinned
[`quran-ws/quran-svg`](https://github.com/quran-ws/quran-svg) source at commit
[`b4155f07e4aea087d2c458069acff9f7c7e749f6`](https://github.com/quran-ws/quran-svg/tree/b4155f07e4aea087d2c458069acff9f7c7e749f6).
The source project traces each edition to its named King Fahd Glorious Qur'an
Printing Complex (KFQC) digital master bundle and publishes per-page digests.
`assets/data/quran/riwayah_page_art_manifest.json` pins the compressed page
size and Git blob SHA-1; the app checks both before decoding a page.

The page artwork remains the KFQC edition. The repository's own ayah polygon
metadata is CC BY 4.0; its notice says attribution is waived for use inside a
product. The KFQC grants digital, software, web and media use of its digital
Mushaf editions. Physical printing for commercial sale has separate terms.
See the upstream [NOTICE](https://github.com/quran-ws/quran-svg/blob/b4155f07e4aea087d2c458069acff9f7c7e749f6/NOTICE.md),
[provenance](https://github.com/quran-ws/quran-svg/blob/b4155f07e4aea087d2c458069acff9f7c7e749f6/docs/PROVENANCE.md),
and [KFQC terms](https://dm.qurancomplex.gov.sa/rights/).

## Tajweed color coverage

Warsh and Qālūn pages are shown as their own printed page artwork. The
maintained Quran.ws coverage matrix currently lists its reviewed Tajweed
annotation layer for Ḥafṣ only. The app therefore does not apply Ḥafṣ
color-rules to Warsh or Qālūn. The settings sheet explains this to readers.

## Updating the pin

Change `REPOSITORY` and `COMMIT` in
`tool/generate_riwayah_page_manifest.py`, regenerate the manifest, and review
the upstream notice and provenance before shipping the new source. Keep the
page count at 604 for each supported edition and verify representative pages
from the beginning, a surah boundary, and the end of the Mushaf.
