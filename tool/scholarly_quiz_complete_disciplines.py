# -*- coding: utf-8 -*-
"""
Authentic Classical Islamic Sciences Comprehensive Quiz Bank.
Supplies fully-fleshed out authentic questions for:
- Fiqh (110 questions target)
- Aqidah (92 questions target)
- Hadith (92 questions target)
- Usul (74 questions target)
- Tajweed (74 questions target)
- Adab (74 questions target)
- Arabic (92 questions target)
"""

# We'll import existing modules first and collect what they have
import sys, os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from data_quiz_fiqh_usul import FIQH_60, USUL_30
from data_quiz_aqidah_hadith import AQIDAH_FULL, HADITH_FULL
from data_quiz_tajweed_adab_arabic import TAJWEED_40, ADAB_30, ARABIC_45
from data_quiz_massive_expansion import (
    AQIDAH_EXPANDED, FIQH_EXPANDED, USUL_EXPANDED, HADITH_EXPANDED,
    TAJWEED_EXPANDED, ADAB_EXPANDED, ARABIC_EXPANDED
)
from data_quiz_massive_generator import SCHOLARLY_QUESTIONS
from data_quiz_massive_generator_v2 import DEEP_SCHOLARLY_QUESTIONS
from data_quiz_qiraat_and_scholars import ALL_EXTRA_SCHOLARLY
from data_quiz_comprehensive_scholarly import COMPREHENSIVE_SCHOLARLY
from data_quiz_massive_scholarly_pack import MASSIVE_SCHOLARLY_PACK, generate_additional_scholarly
from data_quiz_scholarly_final_fill import FINAL_SCHOLARLY_FILL

def get_curated_pool(fan_id):
    """Gathers and deduplicates existing questions for a specific fan."""
    pool = []
    seen = set()

    def add_q(q_tuple):
        # Format: (fan, level, q_text, correct, [w1, w2, w3], lesson, evid, ref)
        q_text = q_tuple[2].strip()
        if q_text not in seen:
            seen.add(q_text)
            pool.append(q_tuple)

    # 1. Base files
    if fan_id == 'fiqh':
        for item in FIQH_60:
            add_q(('fiqh', 'fiqh_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in FIQH_EXPANDED:
            add_q(('fiqh', 'fiqh_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'aqidah':
        for item in AQIDAH_FULL:
            add_q(('aqidah', 'aqidah_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in AQIDAH_EXPANDED:
            add_q(('aqidah', 'aqidah_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'hadith':
        for item in HADITH_FULL:
            add_q(('hadith', 'hadith_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in HADITH_EXPANDED:
            add_q(('hadith', 'hadith_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'usul':
        for item in USUL_30:
            add_q(('usul', 'usul_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in USUL_EXPANDED:
            add_q(('usul', 'usul_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'tajweed':
        for item in TAJWEED_40:
            add_q(('tajweed', 'tajweed_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in TAJWEED_EXPANDED:
            add_q(('tajweed', 'tajweed_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'adab':
        for item in ADAB_30:
            add_q(('adab', 'adab_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in ADAB_EXPANDED:
            add_q(('adab', 'adab_l2', item[0], item[1], item[2], item[3], item[4], item[5]))
    elif fan_id == 'arabic':
        for item in ARABIC_45:
            add_q(('arabic', 'arabic_l1', item[0], item[1], item[2], item[3], item[4], item[5]))
        for item in ARABIC_EXPANDED:
            add_q(('arabic', 'arabic_l2', item[0], item[1], item[2], item[3], item[4], item[5]))

    # 2. Add from SCHOLARLY_QUESTIONS
    for item in SCHOLARLY_QUESTIONS:
        if item[0] == fan_id:
            add_q(item)

    # 3. Add from DEEP_SCHOLARLY_QUESTIONS
    for item in DEEP_SCHOLARLY_QUESTIONS:
        if item[0] == fan_id:
            add_q(item)

    # 4. Add from ALL_EXTRA_SCHOLARLY
    for item in ALL_EXTRA_SCHOLARLY:
        if item[0] == fan_id:
            add_q(item)

    # 5. Add from COMPREHENSIVE_SCHOLARLY
    for item in COMPREHENSIVE_SCHOLARLY:
        if item[0] == fan_id:
            add_q(item)

    # 6. Add from MASSIVE_SCHOLARLY_PACK
    for item in MASSIVE_SCHOLARLY_PACK:
        if item[0] == fan_id:
            add_q(item)
    for item in generate_additional_scholarly():
        if item[0] == fan_id:
            add_q(item)

    # 7. Add from FINAL_SCHOLARLY_FILL
    for item in FINAL_SCHOLARLY_FILL:
        if item[0] == fan_id:
            add_q(item)

    return pool

if __name__ == '__main__':
    for f in ['aqidah', 'fiqh', 'hadith', 'usul', 'tajweed', 'adab', 'arabic']:
        p = get_curated_pool(f)
        print(f"{f:10}: {len(p)} items collected")
