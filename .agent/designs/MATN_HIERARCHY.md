# Matn Learning Page: Optimal Content Hierarchy

## 1. Design Philosophy
The "Talib Ilm" (Student of Knowledge) prioritizes the **Matn** (Orderly Text) above all else. Memorization and reading flow come first. Explanation (Sharh) and Media are supportive layers accessible on demand.

## 2. Section Component Order

### A. The Context Header (Top)
- **Content:** Chapter Title, Breadcrumbs (e.g., "Book of Purification > Water").
- **Goal:** Orient the user instantly.

### B. The Matn Panel (Hero Section)
- **Content:**
  - The Original Arabic Text (Large, Vowelled, High Contrast).
  - Audio Controls (Listen to Matn for memorization).
- **Default State:** **ALWAYS EXPANDED**.
- **Rationale:** This is the primary object of study. It must never be hidden. The audio is attached directly here because hearing the text aids reading.

### C. The Sharh & Tafsir Layer (Middle)
- **Content:**
  - **Source Selector:** Horizontal Tabs or Chips (e.g., "Al-Fawzan", "Ibn Uthaymeen", "Al-Sa'di").
  - **Sharh Text:** The commentary text corresponding to the selected source.
- **Default State:** **PEEK MODE (Collapsed)**.
  - Shows 3-4 lines of the explanation with a "Read Sharh" (iqra' al-sharh) expansion button.
- **Rationale:** Prevents "Text Wall" paralysis. Users read the Matn first, then clearly choose to "dive deep" into the explanation.

### D. The Multimedia & Deep Dives (Bottom)
- **Content:**
  - Related Video Lectures (YouTube/Local).
  - Extended Audio Lectures.
- **Default State:** **COMPACT LIST**.
- **Rationale:** Watching a video is a high-friction commitment (10+ mins). It sits at the bottom as a "Further Study" resource, not blocking the immediate reading flow.

## 3. Interaction Flow (The "Where do I start?" Loop)
1.  **Eye lands on Matn:** User reads the short Arabic text.
2.  **Ear listens:** User taps the prominent "Play" icon next to the text to correct pronunciation.
3.  **Mind inquires:** User taps "Read Explanation" to slide open the Sharh panel for understanding.
4.  **Heart deepens:** User scrolls to bottom to watch the scholarly lecture for mastery.
