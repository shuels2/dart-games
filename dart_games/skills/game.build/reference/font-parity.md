## Font parity audit procedure (reference — invoked by Phase 8 Step 0 / AR-10)

**This procedure is MANDATORY, not optional.** It runs during Phase 8
Step 0, BEFORE screenshots are captured, so the new game's AppBar and
home-card fontSize match Target Tag's cap-height baseline. Do NOT
frame this to the user as optional — the run happens automatically as
part of the standard pipeline. **The user is informed, not asked.**

Both ribbon tests use the same three-column layout (current fs /
recommended fs / baseline-aligned red-on-white overlay), the same
above-baseline-cap-height metric, and Target Tag as the visual ideal.
They differ only in what they measure:

  - `integration_test/appbar_title_measurement_test.dart` — sized
    for AppBar titles (56 px strip, matches Material's default
    `toolbarHeight`). Compares each game's AppBar title font against
    Target Tag's LuckiestGuy @ fs 36. Applies to changes in the
    game's three screen files
    (`<game>_menu_screen.dart` / `<game>_game_screen.dart` /
    `<game>_results_screen.dart`).

  - `integration_test/home_screen_font_measurement_test.dart` —
    sized for home-card labels (44 px strip, matches the
    `SizedBox(height: 44)` around each label in home_screen.dart).
    Compares each game's home-card title against Target Tag's
    LuckiestGuy @ fs 22 (`titleMedium.fontSize` + 4 in the theme).
    Applies to changes in `lib/screens/home_screen.dart` (a single
    `theme.textTheme.titleMedium?.fontSize + N` offset per game).

Both render in Chrome via `test_driver/screenshot_test.dart` so the
real GoogleFonts load, and save a PNG to `temp_screenshots/` that the
orchestrator reads back and analyses pixel-by-pixel.

### Procedure

Run the AppBar test first, apply the winning fontSize, then run the
home-screen test. They're independent — a game's AppBar fs and its
home-card fs do NOT have to match; they just each independently need
to match their respective Target Tag baseline.

**Step 1 — Add the new game to BOTH test files.** In each file's
`_kEntries` list, add a `_Entry(...)` for the new game AND add its
`fontFamily` to the `_styleFor` switch. Copy the exact values used
by the app:
  - AppBar test: title text + font family + current fontSize + game
    background color out of the new game's screen files. Use the
    gameplay-screen title (usually the shortest of the three) — the
    menu title tends to be longer.
  - Home-screen test: `text: 'Game Name'` matches the string passed
    to `_buildGameCard(title: '...')` in `home_screen.dart`. The
    `currentFs` = `18 + N` where N is the game's `+N` offset in
    that same function. Use `_kCardBg` / `_kCardText` for colors so
    all rows share the same neutral card background.

**Step 2 — Run each test.** The runner (`run_ui_tests.bat`) does NOT
auto-discover top-level `integration_test/` files, so invoke each
test directly:

```bash
./chromedriver/chromedriver-win64/chromedriver.exe --port=4444 &
sleep 2
flutter drive --driver=test_driver/screenshot_test.dart \
  --target=integration_test/appbar_title_measurement_test.dart \
  -d chrome --web-browser-flag=--start-maximized \
  --browser-dimension=1920x1080
# ... then repeat for home_screen_font_measurement_test.dart
```

Screenshots land at `temp_screenshots/appbar_title_ribbon.png` and
`temp_screenshots/home_screen_font_ribbon.png`.

**Step 3 — Measure pixel-precise cap heights.** Read each PNG with
the Read tool for a visual look, but ALSO run the versioned Python
analyzer (**[Playbook §12]**) so you have hard numbers:

```bash
python tools/font_ribbon_analyze.py \
  --ribbon temp_screenshots/appbar_title_ribbon.png \
  --tolerance 3

python tools/font_ribbon_analyze.py \
  --ribbon temp_screenshots/home_screen_font_ribbon.png \
  --tolerance 3
```

The tool emits structured JSON: per-game `rec_cap_px`, `delta_px`
(relative to Target Tag baseline), and `within_tolerance` boolean.
It enforces the AR-10 rule: delta must be in `+0..+tolerance` — no
negative deltas allowed (game caps SHORTER than baseline read as
weak / underpowered vs. the LuckiestGuy baseline).

Iterate on any game whose `within_tolerance` is `false`.

**Step 4 — Iterate `overrideRecFs`.** The metric back-solves fontSize
from above-baseline cap height. That gets each game's caps to the
same *pixel height* — but **thin-stroke fonts (Rye, Creepster,
PirataOne, Cinzel Decorative) read as smaller than a heavy face
(LuckiestGuy) at the same cap height** because visual weight matters
too. When you see the metric shrink a thin-stroke game below the
current size, apply a **weight-parity bump**:

  - Small bump (+2 fs) for moderate-weight fonts like Rye.
  - Medium bump (+4 fs) for thin display faces (Creepster, PirataOne,
    Cinzel Decorative).

Set the bump via `overrideRecFs:` inside that game's `_Entry(...)`
and re-render. Repeat until every rec cap sits within 0–+3 px of the
Target Tag baseline (thin fonts land at +2/+3, bold fonts at 0/+1).

**Step 5 — Apply.** Once the user OK's a ribbon:
  - AppBar recommendations → edit the `fontSize:` inside the
    `AppBar(title: Text(..., style: GoogleFonts.<family>(...)))`
    block in ALL THREE `<game>_menu_screen.dart` /
    `<game>_game_screen.dart` / `<game>_results_screen.dart`.
  - Home-screen recommendations → edit the `+ N` in the game's
    branch of the huge nested ternary inside `_buildGameCard(...)`
    in `lib/screens/home_screen.dart`. The `+ N` is the offset over
    `theme.textTheme.titleMedium?.fontSize ?? 16` — if you land on
    `titleMedium.fontSize + 0`, still write it as the full
    `(theme.textTheme.titleMedium?.fontSize ?? 16) + 0` for pattern
    consistency (Carnival Derby is the exception that used to omit
    it).

Preserve ALL text effects (shadows, glows, letter spacing, colors,
weights, `height:`, `Transform.translate`) — only change the
numeric fontSize / offset. The measurement test intentionally
strips shadows for pixel-accurate cap measurement, but the real
game screens should keep them.

**Do NOT commit the game screen fontSize changes automatically.**
The changes are part of the standard Phase 8 → Phase 9 → Phase 11
flow — they get committed alongside every other Phase 8 fix once
Gate 4 (all-tests-passing) closes. AR-10 verifies the sizes were
applied; the final commit is done in Phase 11 with the rest of the
game.


---
