# Classical Arabic Matn Reading Experience: Design & Typography

## 1. Typography Rules (The "Mushaf" Standard)

### Font Selection
- **Primary Typeface:** Use a high-quality **Naskh** based font (e.g., *Amiri*, *Scheherazade New*, or *Traditional Arabic*).
- **Why:** System fonts clip diacritics (Tashkeel) and lack the calligraphic flow required for respect and legibility.

### Sizing & Scale
- **Base Body Size:** `20sp` to `22sp`.
  - *Rationale:* Arabic script is denser vertically due to dots and vowels. It requires 120-130% of the equivalent English size.
- **Line Height (Leading):** `2.0` to `2.2`.
  - *Rationale:* Essential to prevent "clashing" between top vowels (Fatha) and bottom vowels (Kasrah) of adjacent lines.

### Alignment
- **Alignment:** `TextAlign.justify` (with careful kashida) or `TextAlign.right`.
- **Constraint:** Avoid forced justification on narrow mobile screens if it breaks connecting letters awkwardly. **Right Align** is often more readable for long-form on mobile.

## 2. Spacing & Layout

### Margins (Breathing Room)
- **Horizontal:** `24px` (minimum).
- **Why:** Keeps the thumb from blocking text and creates a "precious frame" around the knowledge.

### Paragraphs
- **Indent:** None.
- **Spacing:** `24px` between logical blocks (Fasl/Bab).

## 3. Semantic Highlight Strategy

Adorn the text meaningfully without clutter:

- **Quranic Verses:**
  - **Style:** Enclosed in `﴿ ... ﴾`.
  - **Color:** `AppColors.primary` (Teal/Emerald).
  - **Font:** Distinct, preferably *Uthmani* styled.

- **Prophetic Hadith:**
  - **Style:** Enclosed in `« ... »`.
  - **Color:** `AppColors.secondary` (Deep Green) or bolded.

- **Term Definitions (Mustalahat):**
  - **Style:** Dotted underline (e.g., `TextDecoration.underline` with `dotted`).
  - **Interaction:** Tap to show toast/popover definition.

## 4. Night Mode Considerations

- **Background:** Avoid pure black (`#000000`). Use **Warm Dark Grey** (`#1C1917` / Stone-900).
  - *Effect:* Reduces "smearing" on OLED screens and feels like dark parchment.
- **Text Color:** **Off-White / Cream** (`#E7E5E4`).
  - *Effect:* Reduces glare. Avoid `#FFFFFF`.
- **Highlights:** Shift from Teal/Blue to **Warm Amber/Gold** (`#D4AF37`).
  - *Rationale:* Blue light is harsh at night. Warm colors preserve sleep hygiene and spiritual calmness (Sakinah).
