import json
import glob
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("==================================================")
print("COMPREHENSIVE DATA & ID AUDIT FOR ALL APP SECTIONS")
print("==================================================")

errors = []

# 1. Salaf Gems
with open('assets/data/salaf_gems.json', 'r', encoding='utf-8') as f:
    gems = json.load(f)['gems']
print(f"Salaf Gems: {len(gems)} items")
gem_ids = [g['id'] for g in gems]
if len(gem_ids) != len(set(gem_ids)):
    errors.append("Duplicate IDs in salaf_gems.json")
for g in gems:
    if not re.match(r'^gem_\d{4,}$', g['id']):
        errors.append(f"Invalid gem ID format: {g['id']}")
    if not g.get('text', '').strip():
        errors.append(f"Empty text in gem: {g['id']}")
    if not g.get('author', '').strip():
        errors.append(f"Empty author in gem: {g['id']}")
    if not g.get('role', '').strip():
        errors.append(f"Empty role in gem: {g['id']}")
    if not g.get('sourceRef', '').strip():
        errors.append(f"Empty sourceRef in gem: {g['id']}")

# 2. Hadith Collection
with open('assets/data/hadith_collection.json', 'r', encoding='utf-8') as f:
    hadiths = json.load(f)
print(f"Hadith Collection: {len(hadiths)} hadiths")
h_ids = [h['id'] for h in hadiths]
if len(h_ids) != len(set(h_ids)):
    errors.append("Duplicate IDs in hadith_collection.json")
for h in hadiths:
    if not h.get('matn', '').strip():
        errors.append(f"Empty matn in hadith: {h['id']}")

# 3. Adhkar
with open('assets/data/adhkar.json', 'r', encoding='utf-8') as f:
    adhkar_cats = json.load(f)['categories']
print(f"Adhkar: {len(adhkar_cats)} categories")
cat_ids = [c['id'] for c in adhkar_cats]
if len(cat_ids) != len(set(cat_ids)):
    errors.append("Duplicate category IDs in adhkar.json")
adhkar_items = []
for c in adhkar_cats:
    for it in c.get('items', []):
        adhkar_items.append(it['id'])
        if not it.get('content', '').strip():
            errors.append(f"Empty content in dhikr: {it['id']}")
print(f"Adhkar Items: {len(adhkar_items)} items")
if len(adhkar_items) != len(set(adhkar_items)):
    errors.append("Duplicate dhikr item IDs in adhkar.json")


# 4. Quiz Questions
with open('assets/data/quiz_questions_dump.json', 'r', encoding='utf-8') as f:
    questions = json.load(f)['questions']
print(f"Quiz Questions: {len(questions)} questions")
q_ids = [q['id'] for q in questions]
if len(q_ids) != len(set(q_ids)):
    errors.append("Duplicate question IDs in quiz_questions_dump.json")

# 5. Quran Radios
with open('assets/data/quran_radios.json', 'r', encoding='utf-8') as f:
    radios_data = json.load(f)
    radios = radios_data if isinstance(radios_data, list) else radios_data.get('radios', [])
print(f"Quran Radios: {len(radios)} stations")
r_ids = [r['id'] for r in radios]
if len(r_ids) != len(set(r_ids)):
    errors.append("Duplicate radio IDs in quran_radios.json")


# 6. Quran Surahs
with open('assets/data/quran/surahs.json', 'r', encoding='utf-8') as f:
    surahs_data = json.load(f)
    surahs = surahs_data if isinstance(surahs_data, list) else surahs_data.get('surahs', [])
print(f"Quran Surahs: {len(surahs)} surahs")
s_ids = [s['id'] for s in surahs]
if len(s_ids) != len(set(s_ids)):
    errors.append("Duplicate surah IDs in surahs.json")


# 7. Quran Juz
with open('assets/data/quran/juz.json', 'r', encoding='utf-8') as f:
    juzs = json.load(f)
print(f"Quran Juzs: {len(juzs)} juzs")

# 8. Daily Motivation
with open('assets/data/daily_motivation.json', 'r', encoding='utf-8') as f:
    dm = json.load(f)
print(f"Daily Motivation: {len(dm)} items")
for i, d in enumerate(dm):
    if not d.get('text', '').strip():
        errors.append(f"Empty text in daily_motivation item #{i}")

# 9. Mutun Lessons
with open('assets/data/mutun_lessons.json', 'r', encoding='utf-8') as f:
    lessons = json.load(f)
total_lessons = 0
for bk, l_list in lessons.items():
    total_lessons += len(l_list)
    for l in l_list:
        if not l.get('title', '').strip():
            errors.append(f"Empty title in mutun lesson in {bk}")
print(f"Mutun Lessons: {total_lessons} lessons across {len(lessons)} books")

print("\n--------------------------------------------------")
if errors:
    print(f"TOTAL ERRORS FOUND: {len(errors)}")
    for e in errors[:20]:
        print("  -", e)
    sys.exit(1)
else:
    print("AUDIT RESULT: 0 ERRORS! PERFECT DATA INTEGRITY ACROSS ALL SECTIONS!")
    print("--------------------------------------------------")
