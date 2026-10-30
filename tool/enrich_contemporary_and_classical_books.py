# -*- coding: utf-8 -*-
import json
import re

from curate_contemporary_and_classical_books import get_contemporary_and_book_gems

def run():
    with open('assets/data/salaf_gems.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    existing_gems = data['gems']
    print(f"Initial gems count: {len(existing_gems)}")

    # 1. Re-tag existing contemporary scholars to category 'درر الدعاة المعاصرين'
    contemporary_authors = [
        'الطريفي', 'بن باز', 'العثيمين', 'الألباني', 'الفوزان',
        'البدر', 'الشنقيطي', 'بكر أبو زيد', 'الخميس', 'آل الشيخ', 'السعدي'
    ]

    retagged_count = 0
    for g in existing_gems:
        author = g.get('author', '')
        if any(ca in author for ca in contemporary_authors):
            if g.get('category') != 'درر الدعاة المعاصرين':
                g['category'] = 'درر الدعاة المعاصرين'
                retagged_count += 1
    
    print(f"Re-tagged {retagged_count} existing gems to category 'درر الدعاة المعاصرين'")

    # 2. Get the new curated gems
    new_gems = get_contemporary_and_book_gems()
    print(f"New curated gems to ingest: {len(new_gems)}")

    # Dedup by stripped text
    existing_texts = set(re.sub(r'[\s\u064B-\u065F\u0670]', '', g['text']) for g in existing_gems)

    added = 0
    for ng in new_gems:
        norm = re.sub(r'[\s\u064B-\u065F\u0670]', '', ng['text'])
        if norm not in existing_texts:
            existing_gems.append(ng)
            existing_texts.add(norm)
            added += 1

    print(f"Successfully added {added} new unique gems.")

    # 3. Re-assign sequential unique IDs
    for idx, g in enumerate(existing_gems):
        g['id'] = f"gem_{idx+1:04d}"

    # 4. Save back to assets/data/salaf_gems.json
    data['gems'] = existing_gems
    with open('assets/data/salaf_gems.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Final gems database written with {len(existing_gems)} gems.")

    # 5. Print category breakdown
    cats = {}
    for g in existing_gems:
        c = g.get('category', 'غير مصنف')
        cats[c] = cats.get(c, 0) + 1

    print("\n--- Category Breakdown ---")
    for c, cnt in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"{c}: {cnt}")

if __name__ == '__main__':
    run()
