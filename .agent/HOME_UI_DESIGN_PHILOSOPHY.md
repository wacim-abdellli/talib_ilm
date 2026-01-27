# Home Feature UI Design Philosophy

## Core Principles - Restrained, Premium, Sacred

### Black First
- Primary surfaces: near-black / charcoal
- Primary text: white or soft neutral gray
- The darkness creates depth and calm

### Gold is NOT a Theme - Gold is a RARE Accent
- **≤ 5% of visible UI**
- NEVER used for:
  - Long-running timers (countdown is WHITE)
  - Large text blocks
  - Backgrounds
  - Frequent icons
- ONLY used for:
  - Focus indicators (tiny dots)
  - Selected state markers
  - Completion indicators
  - Rare sacred emphasis

### Semantic Undertones (Felt, Not Seen)
Colors that convey meaning at 5-10% opacity:
- **Prayer/Sacred**: Deep muted green
- **Learning**: Deep indigo
- **Quotes**: Neutral slate
- **General**: Warm gray

These colors blend with the surface - they are felt emotionally, not seen visually.

---

## Component Guidelines

### HomeHeroCard (Prayer Timer)
- Black surface with subtle depth
- Timer text: **WHITE** (never gold)
- Mosque icon: **Monochrome** (secondary text color)
- Only gold element: tiny 6px dot next to current prayer name
- No gradients, no color animation
- Motion allowed only via opacity or translation

### QuickActionButton
- Icons: **Neutral gray by default**
- Gold appears **ONLY on pressed/selected state**
- No per-feature colors
- Widget receives intent, theme decides appearance

### Continue Learning Section
- Icon: Monochrome with subtle indigo undertone
- Progress bar: Neutral fill (white/gray)
- Gold: Only as tiny completion dot when progress > 0
- No gold icon, no gold progress bar

### Section Headers
- Divider bars: Subtle tertiary gray, NOT gold
- Titles: Primary text color

### DailyMotivationCard
- Quote type colors: Muted, barely perceptible
- Quran: Deep sage
- Hadith: Slate gray
- Scholar: Warm gray
- Icons: Tertiary color by default

### HomeSectionCard / HomeLearningCard
- No gradients, no purple
- Near-black surface with subtle undertone
- All icons: Monochrome
- Simplified, quiet, premium

---

## Forbidden Behaviors
1. ❌ Overusing gold
2. ❌ Turning the app yellow
3. ❌ Adding gradients for decoration
4. ❌ Adding "premium" effects to compensate for weak hierarchy
5. ❌ Being creative beyond this brief
6. ❌ String-based color logic in widgets
7. ❌ Per-feature hardcoded colors in widgets

---

## Success Criteria
The UI should feel:
- ✅ Darker than before
- ✅ Calmer than before
- ✅ Less colorful than before
- ✅ More legible
- ✅ More sacred
- ✅ More intentional

**Final Test**: If removing gold entirely still leaves a strong UI, you have succeeded.

---

## Files Modified in This Refactor

1. `home_hero_card.dart` - Timer now white, icon monochrome, tiny gold dot only
2. `quick_action_button.dart` - Icons neutral, gold only on press/select
3. `home_page.dart` - Section bars neutral, continue section monochrome
4. `home_section_card.dart` - Removed colors, semantic undertones only
5. `motivation_widgets.dart` - Muted semantic undertones

---

*"Luxury is restraint, not saturation."*
