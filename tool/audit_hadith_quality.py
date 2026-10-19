import sys
import json
import re

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/hadith_collection.json', 'r', encoding='utf-8') as f:
    hadiths = json.load(f)

print(f"Total hadiths loaded: {len(hadiths)}")

repeated_salawat = []
sallallahu_typos = []
female_narrators = []
dual_narrators = []
bad_titles = []
ocr_typos = []

female_keywords = [
    'عائشة', 'أم سلمة', 'حفصة', 'زينب', 'ميمونة', 'جويرية', 'صفية', 
    'سودة', 'أم حبيبة', 'خديجة', 'فاطمة', 'أسماء', 'أم عطية', 
    'أم الفضل', 'أم سليم', 'الربيع بنت معوذ', 'أم كرز', 'أم هانئ', 'أم عمارة'
]

dual_keywords = [
    'ابن عباس', 'ابن عمر', 'ابن عمرو', 'أسامة بن زيد', 'ابن الزبير',
    'عبد الله بن عباس', 'عبد الله بن عمر', 'عبد الله بن عمرو', 'عبد الله بن الزبير',
    'جابر بن عبد الله', 'النعمان بن بشير', 'البراء بن عازب', 'عبد الله بن أبي أوفى'
]

ocr_words = [
    '؟فال', ' فال:', 'الأنسان', 'اليمني', 'حبلي', 'أبيسعيد',
    'أعرأبي', 'عيينه', 'أيحنني', 'يتوضا', 'امراة', 'لا اتسطعت',
    'يعذابان', 'في سبييل الله'
]

for h in hadiths:
    hid = h.get('id', '')
    matn = h.get('matn', '')
    title = h.get('title', '')
    narrator = h.get('narrator', '')
    
    # 1. Repeated Salawat
    if re.search(r'(?:صلى\s+)?الله\s+عليه\s+وسلم[ى]?\s+(?:صلى\s+)?الله\s+عليه\s+وسلم', matn):
        repeated_salawat.append((hid, "Repeated salawat in matn"))
        
    if 'وسلمى' in matn or 'وسلمى' in title:
        sallallahu_typos.append((hid, "وسلمى typo"))
        
    # 2. Female Narrator Honorific
    for f in female_keywords:
        if f in narrator:
            if re.search(r'رضي\s+الله\s+عنه(?![ماهم])', narrator) and 'عنها' not in narrator:
                female_narrators.append((hid, narrator))
            break
            
    # 3. Dual Narrator Honorific
    for d in dual_keywords:
        if d in narrator:
            if re.search(r'رضي\s+الله\s+عنه(?![ماهم])', narrator) and 'عنهما' not in narrator and 'عنهم' not in narrator:
                dual_narrators.append((hid, narrator))
            break

    # 4. Bad Titles
    if (re.search(r'[؟?]\s*(?:قال|فال)?$', title) or 
        title.endswith('؟') or 
        title.endswith('?') or 
        title.endswith('قال') or 
        title.endswith('فال') or
        title.endswith('فال:') or
        title.endswith('قال:') or
        '؟فال' in title or
        '؟قال' in title or
        len(title.strip()) < 5):
        bad_titles.append((hid, title))
        
    # 5. OCR errors in matn
    for w in ocr_words:
        if w in matn or w in title:
            ocr_typos.append((hid, w))

print(f"1. Repeated salawat occurrences: {len(repeated_salawat)}")
print(f"2. 'وسلمى' typo occurrences: {len(sallallahu_typos)}")
print(f"3. Female narrators with 'عنه' instead of 'عنها': {len(female_narrators)}")
print(f"4. Dual narrators with 'عنه' instead of 'عنهما': {len(dual_narrators)}")
print(f"5. Bad/corrupt titles: {len(bad_titles)}")
print(f"6. Known OCR typos in matn or title: {len(ocr_typos)}")

if ocr_typos:
    print("\n--- SAMPLE OCR TYPOS ---")
    for hid, w in ocr_typos[:10]:
        print(f"  [{hid}]: {w}")

if bad_titles:
    print("\n--- SAMPLE BAD TITLES ---")
    for hid, t in bad_titles[:10]:
        print(f"  [{hid}]: {t}")

print("\nQuality Audit Verdict: ALL CHECKS PASSED PERFECTLY!" if not (repeated_salawat or sallallahu_typos or female_narrators or dual_narrators or bad_titles or ocr_typos) else "\nSome issues remain.")
