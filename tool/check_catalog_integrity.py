# -*- coding: utf-8 -*-
import sys
import glob
import re

sys.stdout.reconfigure(encoding='utf-8')

# Check all Dart files in catalogs
catalog_files = glob.glob('lib/features/ilm/data/catalogs/*catalog.dart')
print(f"Checking {len(catalog_files)} catalog files...")

books_by_id = {}
shuruh_by_id = {}

for f in catalog_files:
    if 'quiz' in f or 'mutun' in f:
        continue
    content = open(f, encoding='utf-8').read()
    # Find ShamelaBook blocks
    blocks = re.findall(r'ShamelaBook\((.*?)\),', content, re.DOTALL)
    for b in blocks:
        id_m = re.search(r'id:\s*(\d+)', b)
        title_m = re.search(r"title:\s*['\"]([^'\"]+)['\"]", b)
        parent_m = re.search(r'parentBookId:\s*(\d+)', b)
        if id_m and title_m:
            bid = int(id_m.group(1))
            btitle = title_m.group(1).strip()
            parent = int(parent_m.group(1)) if parent_m else None
            if bid in books_by_id:
                print(f"DUPLICATE ID {bid}: '{btitle}' vs '{books_by_id[bid]['title']}'")
            books_by_id[bid] = {'title': btitle, 'file': f, 'parent': parent}

print(f"Total Turath books found: {len(books_by_id)}")

# Check parentBookIds
for bid, binfo in books_by_id.items():
    if binfo['parent']:
        pid = binfo['parent']
        if pid not in books_by_id:
            print(f"ORPHAN SHARH: Book {bid} '{binfo['title']}' points to missing parent {pid} in {binfo['file']}")

# Check duplicate titles
titles = {}
for bid, binfo in books_by_id.items():
    t = binfo['title']
    if t in titles:
        print(f"DUPLICATE TITLE: '{t}' (ID {bid} in {binfo['file']} vs ID {titles[t]['id']} in {titles[t]['file']})")
    else:
        titles[t] = {'id': bid, 'file': binfo['file']}

