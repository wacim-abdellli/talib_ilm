import sys
import json
import re
import os

if sys.stdout and hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from title_overrides import TITLE_OVERRIDES

COLLECTION_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data', 'hadith_collection.json')

with open(COLLECTION_FILE, 'r', encoding='utf-8') as f:
    hadiths = json.load(f)

print(f"Loaded {len(hadiths)} hadiths from {COLLECTION_FILE}.")

REPEATED_SALAWAT_REGEX = re.compile(
    r'(?:(?:صلى\s+)?الله\s+عليه\s+وسلم[ى]?[\s،]*){2,}',
    re.UNICODE
)

FEMALE_NAMES = [
    'عائشة', 'أم سلمة', 'حفصة', 'زينب', 'ميمونة', 'صفية', 'جويرية', 
    'سودة', 'أم حبيبة', 'خديجة', 'فاطمة', 'أسماء', 'أم عطية', 
    'أم الفضل', 'أم سليم', 'الربيع بنت معوذ', 'أم كرز', 'أم هانئ', 'أم عمارة',
    'فاطمة بنت قيس', 'أم الدرداء', 'خولة بنت ثعلبة', 'خولة بنت حكيم', 'بريرة',
    'أم قيس', 'حمنة بنت جحش', 'أم خالد', 'الشفاء بنت عبد الله', 'كبشة بنت كعب', 
    'أم معبد', 'مجيبة الباهلية'
]

DUAL_PATTERNS = [
    'ابن عباس', 'ابن عمر', 'ابن عمرو', 'أسامة بن زيد', 'ابن الزبير',
    'عبد الله بن عباس', 'عبد الله بن عمر', 'عبد الله بن عمرو', 'عبد الله بن الزبير',
    'جابر بن عبد الله', 'النعمان بن بشير', 'البراء بن عازب', 'عبد الله بن أبي أوفى',
    'الحسن بن علي', 'الحسين بن علي', 'عبد الله بن جعفر', 'شداد بن أوس',
    'سعد بن مالك بن سنان', 'أبي سعيد الخدري وأبي هريرة'
]

OCR_REPLACEMENTS = [
    ('؟فال:', '؟ قال:'),
    ('؟فال', '؟ قال:'),
    ('؟قال', '؟ قال:'),
    (' فال:', ' قال:'),
    ('الأنسان', 'الإنسان'),
    ('اشتكي', 'اشتكى'),
    ('اليمني', 'اليمنى'),
    ('حبلي', 'حبلى'),
    ('أبيسعيد', 'أبي سعيد'),
    ('أعرأبي', 'أعرابي'),
    ('عيينه', 'عيينة'),
    ('أيحنني', 'أينحني'),
    ('يتوضا', 'يتوضأ'),
    ('امراة', 'امرأة'),
    ('أتي النبي', 'أتى النبي'),
    ('لا أري', 'لا أرى'),
    ('أرسك؟', 'أرسلك؟'),
    ('انتيهت', 'انتهيت'),
    ('جأووا', 'جاؤوا'),
    ('لا اتسطعت', 'لا استطعت'),
    ('يلقي أخاه', 'يلقى أخاه'),
    ('يعذابان', 'يعذبان'),
    ('في سبييل الله', 'في سبيل الله'),
    ('بَِددًا', 'بِدَداً'),
    ('الرصغ', 'الرسغ'),
    (' ا نازل', ' أنا نازل'),
    ('فقال: "أنا نازل', 'فقال: "أنا نازل'),
    ('إلي سماء', 'إلى سماء'),
    ('إلي السماء', 'إلى السماء'),
    ('إلي هذا', 'إلى هذا'),
    ('إلي قوله', 'إلى قوله'),
    ('إلي أبيه', 'إلى أبيه'),
    ('إلي رسول الله', 'إلى رسول الله'),
    ('شكي إلي رسول الله', 'شكى إلى رسول الله'),
    ('إلي عمر', 'إلى عمر'),
    ('إلي بعض', 'إلى بعض'),
    ('إلي ربنا', 'إلى ربنا'),
    ('إلي النقص', 'إلى النقص'),
]

def clean_salawat(text):
    if not text:
        return text
    # 1. Replace repeated salawat
    res = REPEATED_SALAWAT_REGEX.sub('صلى الله عليه وسلم ', text)
    # 2. Fix isolated 'وسلمى'
    res = res.replace('وسلمى', 'وسلم')
    # 3. Fix 'الله عليه وسلم الله عليه وسلم'
    while 'الله عليه وسلم الله عليه وسلم' in res:
        res = res.replace('الله عليه وسلم الله عليه وسلم', 'الله عليه وسلم')
    while 'صلى الله عليه وسلم صلى الله عليه وسلم' in res:
        res = res.replace('صلى الله عليه وسلم صلى الله عليه وسلم', 'صلى الله عليه وسلم')
    # Normalize excessive spaces
    res = re.sub(r' +', ' ', res)
    return res.strip()

def clean_narrator(narrator):
    if not narrator:
        return narrator
    n = narrator.strip()
    # Truncated narrator strings
    if 'أسماء بنت يزيد ال ' in n:
        n = n.replace('أسماء بنت يزيد ال ', 'أسماء بنت يزيد الأنصارية ')
    
    # Dual first
    is_dual = False
    for dp in DUAL_PATTERNS:
        if dp in n:
            is_dual = True
            break
            
    if is_dual:
        n = re.sub(r'رضي\s+الله\s+عنه(?![ما])', 'رضي الله عنهما', n)
        n = re.sub(r'رضي\s+الله\s+عنها', 'رضي الله عنهما', n)
        return n

    # Female
    is_female = False
    for fn in FEMALE_NAMES:
        if fn in n:
            is_female = True
            break

    if is_female:
        n = re.sub(r'رضي\s+الله\s+عنه(?![ما])', 'رضي الله عنها', n)
        n = re.sub(r'رضي\s+الله\s+عنهما', 'رضي الله عنها', n)
        return n

    return n

def clean_matn(matn):
    if not matn:
        return matn
    # 1. Salawat
    m = clean_salawat(matn)
    
    # 2. Known OCR typos
    for src, dst in OCR_REPLACEMENTS:
        m = m.replace(src, dst)
        
    return m.strip()

def clean_title(hid, title):
    if hid in TITLE_OVERRIDES:
        return TITLE_OVERRIDES[hid]
        
    t = clean_salawat(title)
    # Apply OCR replacements to titles
    for src, dst in OCR_REPLACEMENTS:
        t = t.replace(src, dst)
    # Strip bad characters and trailing punctuation
    t = re.sub(r'^[\s«"\'\(\[\-\:\.\،\؛\؟]+|[\s»"\'\)\]\-\:\.\،\؛\؟]+$', '', t).strip()
    t = re.sub(r'[\?؟\:\،\-\“\”\"\{\}\(\)7]+$', '', t).strip()
    t = re.sub(r'\s*(?:قال|فال)\s*$', '', t).strip()
    return t

# Clean all hadiths
stats = {
    'salawat_fixed': 0,
    'matn_fixed': 0,
    'female_fixed': 0,
    'dual_fixed': 0,
    'title_fixed': 0,
}

cleaned_hadiths = []
for h in hadiths:
    hid = h['id']
    old_matn = h.get('matn', '')
    old_narrator = h.get('narrator', '')
    old_title = h.get('title', '')
    
    new_matn = clean_matn(old_matn)
    new_narrator = clean_narrator(old_narrator)
    new_title = clean_title(hid, old_title)
    
    if new_matn != old_matn:
        stats['matn_fixed'] += 1
    if new_narrator != old_narrator:
        if 'عنها' in new_narrator and 'عنها' not in old_narrator:
            stats['female_fixed'] += 1
        elif 'عنهما' in new_narrator and 'عنهما' not in old_narrator:
            stats['dual_fixed'] += 1
    if new_title != old_title:
        stats['title_fixed'] += 1

    h['matn'] = new_matn
    h['narrator'] = new_narrator
    h['title'] = new_title
    cleaned_hadiths.append(h)

print("\n--- Statistics of Sanitization ---")
print(f"Total Hadiths processed: {len(cleaned_hadiths)}")
print(f"  - Matn text cleaned / typos fixed: {stats['matn_fixed']}")
print(f"  - Female narrators corrected (عنها): {stats['female_fixed']}")
print(f"  - Dual narrators corrected (عنهما): {stats['dual_fixed']}")
print(f"  - Titles updated / polished: {stats['title_fixed']}")

# Save back to file
with open(COLLECTION_FILE, 'w', encoding='utf-8') as f:
    json.dump(cleaned_hadiths, f, ensure_ascii=False, indent=2)

print(f"\nSuccessfully wrote cleaned database to {COLLECTION_FILE}!")
