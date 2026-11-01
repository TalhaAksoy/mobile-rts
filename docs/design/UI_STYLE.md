# UI style

The menus, settings, gallery, pause menu and HUD share one look, defined in `ParchmentTheme.gd`. Before and after:
`docs/audits/evidence/ui/ui_before_after.png`.

## What was wrong

Every label used the MedievalSharp fantasy font. Every button was the same heavy placard, with a 3 px brown border and
a drop shadow, and most text was in capitals. Nothing stood out as the main action.

**New game:**
- The screen was squeezed into two columns at 540 px.
- The tutorial banner, a fixed 400 px label over the top bar, overflowed with two-line texts. Banners fired close
  together were drawn on top of each other.

**Gallery:**
- Debug text: `Osmanlılar () — 5 Birlik Görseli [Dikey Liste]`.
- Emoji icons.
- A second back button.

## Rules

- **Surface:** a light paper sheet (`PARCHMENT_BG`) with a 1 px ink hairline and a soft shadow. Menu screens are one
  full-height sheet over the darkened battle painting, with:
  - a header (back button on the left, Cinzel title on the right);
  - a scrolling body;
  - a fixed footer for the main action.
- **Type:**
  - Cinzel for titles and the main action.
  - The device's sans-serif (Roboto on Android) for everything else.
  - Small capitals in a muted ink only for section labels.
  - Buttons and texts use sentence or title case, not capitals.
- **Buttons:**
  - **Main action:** one per screen (Yeni Oyun, Seferi Başlat, Devam Et, Yeniden Oyna), filled in lacquer red
    (`apply_primary_button`).
  - **Others:** paper chips with a hairline (`apply_parchment_button`).
  - **Back and the least important actions:** text only (`apply_ghost_button`).
- **Choices:**
  - Segmented rows of toggle buttons. The selected one is filled in ink.
  - Sliders have a thin track, the filled part in the accent colour, and a round grabber.
- **HUD notices:**
  - A tutorial objective card ("GÖREV 3/8", title, what to do, ×) sits under the top bar, left of the minimap, and
    lets taps through except on ×.
  - Short notices stack below it, at most three, and fade after about 3 s.
- **Fonts in exports:** Cinzel is loaded as an imported resource (`load("res://assets/Cinzel.ttf")`). The old
  `load_dynamic_font(globalize_path(...))` failed in exported builds and fell back to a system font.

## New game screen

The screen is one column, in this order:

1. **Kingdom:** a 5 × 2 grid of flags, then a card with the civ's bonuses, its unique unit and its army.
2. **Map:** the map type and a description, then the size (Küçük / Orta / Büyük, with each size's opponent limit).
3. **Opponents:** a − / + stepper, limited by the size. One row per opponent, with the team colour and a civ picker;
   the picker defaults to Rastgele, except Rakip 1, which starts on Bizanslılar.
4. **Difficulty**, with its hint.
5. **Seferi Başlat**, fixed at the bottom.
