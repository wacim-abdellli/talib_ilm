# Quran Data Assets

This folder contains JSON data files for the Quran feature.

## Files Included

### Core Data
- `surahs.json` - All 114 Surah metadata (names, verse counts, revelation type, pages)
- `juz.json` - All 30 Juz with start/end positions and names
- `surah_1.json` - Al-Fatiha verses (sample - add more as needed)

### Audio
- `audio_urls.json` - Reciter data and audio URL patterns

### Translations
- `translations.json` - Available translation sources

## Data Sources

### Recommended APIs

1. **AlQuran.cloud API** (Free, no auth required)
   - Base URL: `https://api.alquran.cloud/v1`
   - Full Quran: `GET /quran/quran-uthmani`
   - Surah: `GET /surah/{surahNumber}/quran-uthmani`
   - Translation: `GET /quran/{edition}`

2. **Quran.com API v4**
   - Base URL: `https://api.quran.com/api/v4`
   - Chapters: `GET /chapters`
   - Verses: `GET /verses/by_chapter/{chapter_number}`
   - Tafsir: `GET /tafsirs/{tafsir_id}/by_ayah/{ayah_key}`

3. **Islamic Network CDN** (Audio)
   - Base URL: `https://cdn.islamic.network/quran/audio`
   - Quality options: `64`, `128`, `192`
   - Pattern: `/{quality}/{reciter}/{ayahNumber}.mp3`

## Adding Full Quran Data

To download and bundle full Quran data:

```dart
// Example: Fetch all verses for a surah
final response = await http.get(
  Uri.parse('https://api.alquran.cloud/v1/surah/$surahId/quran-uthmani'),
);
final data = jsonDecode(response.body);
final ayahs = data['data']['ayahs'];
```

### Recommended editions:
- `quran-uthmani` - Uthmani script
- `quran-simple` - Simple Arabic
- `en.sahih` - Sahih International (English)
- `fr.hamidullah` - Hamidullah (French)
- `ar.muyassar` - Tafsir Al-Muyassar (Arabic)

## File Naming Convention

- Surah verses: `surah_{1-114}.json`
- Page verses: `page_{1-604}.json`
- Translation: `translations_{lang_code}.json`

## JSON Schema

### Ayah Object
```json
{
  "id": 1,
  "surahId": 1,
  "ayahNumber": 1,
  "textUthmani": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
  "textSimple": "بسم الله الرحمن الرحيم",
  "juzNumber": 1,
  "pageNumber": 1,
  "translations": {
    "en": "In the name of Allah...",
    "fr": "Au nom d'Allah..."
  }
}
```

## Notes

- Total Ayahs in Quran: 6,236
- Total Pages: 604
- Total Juz: 30
- Total Hizb: 60
