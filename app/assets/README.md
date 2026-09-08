# assets/

Artwork for the app. **Nothing here is committed until it exists** — the app runs
correctly with this folder empty, because `lib/core/illustrations.dart` falls back
to a calm placeholder for any file that is missing.

The set is `docs/design-v4.md` §6, from the client's second design pass.

## illustrations/ — seven files, exactly these names

| File | Subject | Used on |
|---|---|---|
| `lock_friendly.webp` | violet padlock with a small smile | the blocked card, every locked game tile |
| `star_big.webp` | large gold star, **no face** | rewards, session complete, setup milestones |
| `backpack.webp` | violet backpack with books and pencils | the school-grade step |
| `rocket.webp` | rocket with a small astronaut waving | the welcome step |
| `astronaut.webp` | small round astronaut | the home greeting, empty states |
| `shield.webp` | violet shield with a check mark | the disclosure step, the parent gate |
| `starfield.webp` | sparse low-contrast star pattern | behind the blocked card and the balance card |

`lock_friendly.webp` is the one to get right. It is what a child sees at the moment
they are refused something they wanted, and it repeats on every locked tile. It has
to read as *not yet*, never as *forbidden*.

## icons/ — deliberately empty

Every small glyph the client's mockups draw inside a rounded tinted square is a
**Material icon**, rendered by `TintedIcon` in `lib/core/illustrations.dart`. Star,
gift, clock, calendar, book, trophy, controller — Material ships all of them, and
using them instead of commissioned art halves the budget below.

The app icons in the game grid come from the device through `PackageManager`. They
belong to the installed apps; we neither draw them nor ship them.

## Budget — this is Article 13, not a preference

The reference device is a 2 GB Android 10 phone, and the app must survive a
30-minute session with no crash (acceptance criterion 11.10).

- **WebP, transparent background.**
- **≤ 150 KB per asset** at 3x density.
- **≤ 1 MB total** added to the APK.
- Lighting and shadow **baked into the asset**. No runtime blur, no stacked
  shadows, no shader effects.
- **No text inside any artwork** — it cannot be localised, and this app ships in
  two languages with the Arabic reviewed line by line. This includes the brand
  name: a wordmark baked into the rocket illustration is a wordmark that has to be
  redrawn the day the brand changes.

## Converting what the generator gives you — what was actually done

The delivered files were 6.8 MB of PNG at 1254x1254. They ship as **0.19 MB of WebP**,
all at quality 88, so nothing was traded away to meet the budget.

`cwebp` is not installed on the dev machine; Pillow does the same job. Four steps
per file, and the first two matter more than they sound:

1. **Despeckle.** Several files carried faint coloured dust in the fully transparent
   area — magenta specks inside the padlock's shackle, white specks around the
   shield. Any pixel under alpha 16 is forced to zero. Left alone it survives the
   resize as visible grit on a dark background.
2. **Trim to content, then pad back to square.** The generator left a wide empty
   margin, so the drawing was arriving at roughly 60 % of the box the widget gave
   it. Trimming and re-squaring makes it fill the box at the same file size.
3. **Resize** to the density the app draws at: 384 px for the 128 dp illustrations,
   288 px for the 96 dp ones, 900 px for the rocket hero, 600 px for the tiling
   star field.
4. **Encode to WebP**, stepping quality down only if the file misses budget. None
   of them did.

| Asset | Delivered | Ships as | Size |
|---|---|---|---|
| `lock_friendly` | 1254² PNG, 843 KB | 384² | 22.5 KB |
| `star_big` | 1254² PNG, 621 KB | 288² | 13.7 KB |
| `backpack` | 1254² PNG, 934 KB | 384² | 26.2 KB |
| `astronaut` | 1254² PNG, 1617 KB | 384² | 32.6 KB |
| `shield` | 1254² PNG, 876 KB | 288² | 16.9 KB |
| `rocket` | 1448x1086 PNG, 1637 KB | 900x675 | 47.5 KB |
| `starfield` | 1254² PNG, 340 KB | 600² | 37.6 KB |

The script is `scratchpad/convert_art.py`; re-run it if any asset is redrawn.

## Where they are used

| Asset | Screen |
|---|---|
| `rocket` | setup step 1, as a full-width hero above the title |
| `backpack` | setup step 2, under the school-grade field |
| `shield` | setup step 4 at the head of the disclosure card, and the parent PIN gate |
| `astronaut` | the child's home when there are no lessons yet |
| `star_big` | the session-complete screen |
| `lock_friendly` | the blocked card and locked game tiles — **not built yet**, both wait on the Kotlin blocking layer |
| `starfield` | behind the blocked card — same, not built yet |
