<!-- game.build layout constants (WS07 §7.5).
     These were prose scattered through Phase 4. Collected here so the Layout
     Lint step has one table to check instead of a reader having to notice a
     paragraph. -->

# Layout constants — with verify commands

Every row is a constant Phase 4 must produce, and the grep that proves it.
Run these after the Phase 4 sub-agent returns, BEFORE AR-4.

Anything already covered by `test/meta/` is marked so — do not hand-grep what
a test already asserts. Run `flutter test test/meta/` instead; it is faster
and it fails loudly.

## Automated — covered by `test/meta/game_style_lint_test.dart`

| Element | Constant | Notes |
|---|---|---|
| AppBar back button | `size: 32` + `hoverColor` / `highlightColor` / `splashColor` all `Colors.transparent` | All three hover properties are required — one missing leaves the default splash on touch. |
| AppBar title | a `GoogleFonts.*` display face, never a bare `TextStyle(` | |
| Raw Material colours | no NEW `Colors.blue/red/green/grey/orange` in game screens | Existing uses are baselined per file; the baseline only ratchets down. |

## Automated — covered by `test/meta/option_wiring_lint_test.dart`

| Element | Constant |
|---|---|
| Every spec §7 option | control → handoff → consumption → effect, all four links present |

## Automated — covered by `test/meta/widget_key_manifest_test.dart`

| Element | Constant |
|---|---|
| Every key in `test_keys.dart` | attached to a widget somewhere in `lib/` |

A key that is declared but never attached is a finder that can never match, so
a test using it can pass while asserting nothing. That has happened here
before — see the Carnival `targetScoreDropdown` note in that test.

## Hand-checked — the dual-list / options-row recipe

These are NOT linted, deliberately: the values are per-game design decisions
and a lint would fight legitimate variation. What is fixed is the RELATIONSHIP
between them, which is why the reasoning matters more than the numbers.

| Element | Value | Verify |
|---|---|---|
| `availableContainerMargin` | `EdgeInsets.zero` | `grep -E 'availableContainerMargin' lib/widgets/player_list_panel/dual_player_list_panel_config.dart` |
| `selectedContainerMargin` | `EdgeInsets.zero` | same |
| `listGap` | `4` | same — **not 8**, see below |
| Option-box internal padding | `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | `grep -n 'EdgeInsets.symmetric(horizontal: 16, vertical: 8)' <menu screen>` |
| Options-row gap | `SizedBox(width: 8)` | `grep -n 'SizedBox(width: 8)' <menu screen>` |
| Option boxes | identical heights via a fixed min-height | read the screenshot — a slider box taller than a toggle box breaks the row's rhythm |
| Game + results screens | `LayoutBuilder` or `FittedBox` present | `grep -nE 'LayoutBuilder|FittedBox' <game/results screen>` |

### Why `listGap: 4` and not `8` — the counterintuitive one

The instinct is to set `listGap` equal to the options-row `SizedBox(width: 8)`
so the gaps match. **That produces a visibly WIDER gap between the panes.**

`dual_player_list_panel.dart` hardcodes `padding: EdgeInsets.all(16.0)` inside
each section, so pane content sits 16px in from each pane's border, while
option-box content sits at its own 12–16px. The pane-to-pane VISUAL gap
therefore includes 16+16 of inner padding that the options row does not have.
`listGap: 4` — half the options-row value — compensates, and makes the visible
box-to-box gaps appear equal.

If a game needs a different visual gap, scale `listGap` proportionally and
leave a comment in the factory explaining the perceived-vs-actual distinction,
because the next person will otherwise "fix" it back to 8.

The real fix is a `sectionPadding` knob on the shared widget; until that
exists, every game works around the hardcoded 16.

### Verify the recipe end to end

```bash
grep -nE 'availableContainerMargin|selectedContainerMargin|listGap' \
  lib/widgets/player_list_panel/dual_player_list_panel_config.dart
```

Then look at the `menu_4_players_ready` (or `menu_default`) screenshot:

- the AVAILABLE↔SELECTED gap should look EQUAL to the gap between the two
  option boxes, and
- the player tiles' left edge should align with the option labels' left edge.

Numbers matching the table with a screenshot that looks wrong means the shared
widget's inner padding has changed — check `dual_player_list_panel.dart`
before adjusting anything per game.
