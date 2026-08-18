## Accumulated Build Quality Rules

These rules were learned from post-build refinement sessions on shipped games. Each one was absent from an initial build and required manual correction after delivery. All applicable rules are enforced in AR-4 item (pp).

---

### 1. Character Randomization (games with multiple interchangeable characters)
If a game has more characters than players and assigns one per player, shuffle all characters at game-screen `initState` time rather than hardcoding by player index. Pattern (identical to Reef Royale):
```dart
late List<String> _characterPaths;

@override
void initState() {
  super.initState();
  final allChars = [
    'assets/games/[GAME_NAME_SNAKE]/characters/Char1.png',
    // ... every character ...
  ]..shuffle();
  _characterPaths = allChars.take(playerCount).toList();
  // ...
}
```
Use `_characterPaths[playerIndex]` everywhere character images are needed (game screen, results screen). The results screen does not share screen state with the game screen, so if the results screen hard-codes character paths it will show different characters than the game screen used.

---

### 2. Shape-Following Character Glow
`BoxShadow` on a Container creates a **rectangular** glow that includes the transparent areas of the PNG. For character images with transparency, use `ImageFiltered` + `ColorFiltered(BlendMode.srcIn)` positioned just outside the character bounds:
```dart
import 'dart:ui' as ui;

SizedBox(
  width: charSize, height: charSize,
  child: Stack(
    clipBehavior: Clip.none,
    fit: StackFit.expand,
    children: [
      if (isActive)
        Positioned(
          left: -(charSize * 0.10), right: -(charSize * 0.10),
          top:  -(charSize * 0.10), bottom: -(charSize * 0.10),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: charSize * 0.07, sigmaY: charSize * 0.07),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(glowColor.withOpacity(0.85), BlendMode.srcIn),
              child: Image.asset(characterPath, fit: BoxFit.contain),
            ),
          ),
        ),
      Image.asset(characterPath, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.person, color: glowColor, size: charSize * 0.7)),
    ],
  ),
)
```
`BlendMode.srcIn` colors only the non-transparent pixels of the image; the blur then spreads that colored silhouette outward.

---

### 3. Per-Player Controls Belong in the Player Column, Not the AppBar
Dart indicators (D1/D2/D3) and the Skip Turn button are per-player controls — they belong in the active player's display column, not in the AppBar. AppBar actions should contain only global controls (DartboardConnectionInfo, ResumeGameButton).

---

### 4. Dart Indicator Color Logic — Track Hit Status at Throw Time
Segment strings alone cannot distinguish "dart hit a game target" from "dart hit a valid dartboard number not in the target set." Track `wasMatched` at throw time in screen state:
```dart
List<bool> _currentTurnHits = [];
String? _lastTurnPlayerId;

// In _handleDartThrow, BEFORE processDartThrow:
if (_lastTurnPlayerId != playerId) {
  _currentTurnHits = [];
  _lastTurnPlayerId = playerId;
}
_currentTurnHits = [..._currentTurnHits, wasMatched];

// Clear in _handleTakeoutFinished() and in the skip-turn callback.
```
Pass `dartHits: _currentTurnHits` to the active player's column; use `dartHits[i]` to decide player-color vs neutral-color per slot.

---

### 5. All Results Badge States Must Be Implemented
Never leave the loser badge as an empty transparent container. Implement WIN, LOSS, and DRAW explicitly:
```dart
isMatchDraw ? 'DRAW' : isWinner ? 'WIN' : 'LOSS'
```
Use a muted fill (e.g., `bloodRed.withOpacity(0.25)`) for LOSS — visible but not harsh.

---

### 6. Use Icon Widgets, Not Emoji, for Player-Colored Indicators
Emoji (🚩, ⚓, ⚙, etc.) render in fixed platform colors that `TextStyle.color` cannot override. Use `Icon(Icons.flag, color: playerColor)` anywhere the indicator color is semantically meaningful (e.g., different flag colors per player). Icon shadows work identically to Text shadows:
```dart
Icon(
  Icons.flag,
  color: playerFlagColor,
  size: 22,
  shadows: const [
    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
    Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
  ],
),
```

---

### 7. Text Readability on Busy Backgrounds — 4-Corner Shadow Outline
A single drop shadow only helps from one direction. For text over background images, use a 4-corner outline (zero blur radius) so the text is readable regardless of which part of the image is behind it:
```dart
shadows: const [
  Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5, -1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5, -1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset(-1.5,  1.5), blurRadius: 0),
  Shadow(color: Color(0xFF1A1A1A), offset: Offset( 1.5,  1.5), blurRadius: 0),
]
```
Apply to: AppBar titles, player names, stat labels, and any other colored text over a background image. Also works on `Icon.shadows` (same syntax).

---

### 8. Settings + Selected Player Persistence on "Change Settings" Navigation
The "Change Settings" navigation MUST pass the previous game's settings AND selected player IDs as constructor parameters to the menu screen. Do NOT rely on `provider.currentGame` surviving the navigation — it may be null by the time the new screen mounts.

**Menu screen constructor** — add optional parameters for every setting and for selected player IDs:
```dart
class [Game]MenuScreen extends StatefulWidget {
  final TargetDifficulty? initialDifficulty;
  final int? initialBestOf; // etc. for each spec option
  final List<String>? initialSelectedPlayerIds;
  const [Game]MenuScreen({super.key, this.initialDifficulty, ..., this.initialSelectedPlayerIds});
}
```

**Menu `initState`** — hydrate ONLY from widget params, then defaults. NO `provider.currentGame` fallback (entry from the home screen must show defaults; only `widget.initialX` from the results-screen CHANGE SETTINGS path should preserve the prior values):
```dart
_difficulty = widget.initialDifficulty ?? TargetDifficulty.easy;
```
After `clearSelection()` in `addPostFrameCallback`, re-select previous players:
```dart
if (widget.initialSelectedPlayerIds != null) {
  for (final id in widget.initialSelectedPlayerIds!) {
    final player = playerProvider.allPlayers.where((p) => p.id == id).firstOrNull;
    if (player != null) playerProvider.selectPlayer(player, maxPlayers: N);
  }
}
```

**Results screen `_changeSettings`** — read from provider before navigating:
```dart
void _changeSettings() {
  final game = context.read<[Game]Provider>().currentGame;
  Navigator.pushAndRemoveUntil(context,
    MaterialPageRoute(builder: (_) => [Game]MenuScreen(
      initialDifficulty: game?.targetDifficulty,
      // ...other settings...
      initialSelectedPlayerIds: game?.playerIds,
    )),
    (route) => route.isFirst,
  );
}
```

---

### 9. Randomize Grid Targets (Grid-Based Games)
For games with targeting grids, target numbers MUST be randomized from the full eligible range each game — never hardcoded. The generator MUST accept `Random? random` for testability:
```dart
import 'dart:math';

static List<List<CellTarget>> generate(TargetDifficulty difficulty, {Random? random}) {
  final rng = random ?? Random();
  final pool = List.generate(20, (i) => i + 1)..shuffle(rng);
  final nums = pool.take(9).toList(); // 9 for Easy/Medium; 8 + bull-center for Hard
  // ...
}
```
Hardcoded layouts (e.g., `[20,18,16 / 19,17,15 / 14,12,10]`) mean every game is identical and players memorize the grid after one session.

---

### 10. Play-to-Complete: Steal / Takeover Infinite Loop Prevention
When a game has steal or takeover mechanics (player A can take player B's claimed cell/territory), the play-to-complete strategy MUST:
1. Designate a fixed winner upfront — always `game.playerIds[0]`
2. Have all non-winners return `null` from `getNextThrow` (deliberate miss every dart)
3. Have the winner target only EMPTY cells — never steal from opponents

Both (2) and (3) are required. Without them, P1 steals P2's cell → P2 steals it back on the next turn → infinite loop. The strategy comment must document this explicitly.

---

### 11. Test Keys for Runtime-Dynamic Values
When a UI element displays a value determined at runtime (e.g., a randomized target number, a computed score), add a widget key to that element so tests can query it without going through the provider:
```dart
Text(
  targetLabel,
  key: [Game]GameKeys.gridCellTargetLabel(row, col),
  // ...
)
```
Expose the value in `ProviderHelpers` as well:
```dart
static int get[Game]CellTargetNumber(WidgetTester tester, int row, int col) =>
    get[Game]Provider(tester).currentGame!.grid[row][col].target.number;
```

---

### 12. `completeGameToVictory` Must Read Actual Target Values
The `completeGameToVictory` helper MUST read actual target values from the provider at runtime — never hardcode numbers that assume a fixed grid layout. Include a `throwForCellTarget` dispatch helper:
```dart
import 'package:dart_games/models/[GAME_NAME_SNAKE]_game.dart';

Future<void> throwForCellTarget(WidgetTester tester, CellTarget target) async {
  switch (target.requirement) {
    case CellRequirement.bull:
      await DartThrowHelpers.throwBullseyeViaMock(tester);
    case CellRequirement.tripleOnly:
      await DartThrowHelpers.throwDartViaMock(tester, target.number, multiplier: 'triple');
    case CellRequirement.doubleOnly:
    case CellRequirement.doubleOrTriple:
      await DartThrowHelpers.throwDartViaMock(tester, target.number, multiplier: 'double');
    case CellRequirement.any:
      await DartThrowHelpers.throwDartViaMock(tester, target.number);
  }
}
```
P2 always misses in `completeGameToVictory` — this is safe even with steal mode ON (see Rule 10).

---

### 13. Responsive Layout — Use LayoutBuilder for Game Boards
Fixed-size game board elements (character images, grid cells, board tracks) that sit beside other fixed-size elements in a Row will overflow on different screen sizes. Use `LayoutBuilder` to compute proportional sizes from available width:
```dart
LayoutBuilder(builder: (context, constraints) {
  final availW = constraints.maxWidth;
  final gridW = availW * 0.40; // grid takes 40% of width
  final cellSize = (gridW - 18.0) / 3.0; // 3×3 grid, 3px margin each side
  final charColW = (availW - gridW) / 2.0;
  // ...
})
```
Note: any margin/padding on the grid container must be subtracted from `availW` before computing character column widths — failing to do so causes a pixel overflow equal to the total horizontal margin.

---

### 14. Background Texture Image Opacity
Background texture images (`opacity: AlwaysStoppedAnimation(0.3)`) at 30% are often invisible against a dark overlay. Use 0.50–0.65 for textures meant to add visual interest, or higher if the image is a primary visual element. The `errorBuilder: (_, __, ___) => const SizedBox.shrink()` pattern silently hides missing images — verify the file actually exists at the specified path.

---

### 15. Tests must include inline `[DIAG]` reason strings on navigation/findsOneWidget assertions
Headless `-d web-server` mode does NOT pipe app stdout into `flutter drive`'s log. When a `findsOneWidget` fails, the failure block in the per-test log is *all we get* — no `print()`s, no progress markers, no audio queue trace. Without diagnostic info embedded in the failure itself, every iteration costs a full re-run.

Any assertion that depends on navigation having completed (post-tap, post-pop, after `pushReplacement` / `pushAndRemoveUntil`) MUST include an inline diagnostic in its `reason:` string built from already-imported `ElementFinders` methods.

**Inline at the call site — never via a new shared helper.** New shared methods have repeatedly hit "Member not found" in headless compile and block the test from running at all. Use the test's existing imports.

```dart
final diag = '[DIAG after-NEW-VOYAGE '
    'menuStart=${ElementFinders.get[GameName]StartButton().evaluate().length} '
    'gameSkip=${ElementFinders.get[GameName]SkipTurnButton().evaluate().length} '
    'resultsPlayAgain=${config.getPlayAgainButton().evaluate().length} '
    'homeCarnival=${ElementFinders.getCarnivalDerbyCard().evaluate().length} '
    'resumeModal=${ElementFinders.getResumeGameModalOverlay().evaluate().length}]';
expect(ElementFinders.get[GameName]StartButton(), findsOneWidget,
    reason: 'Should be on menu after NEW VOYAGE. $diag');
```

Apply to: every nav-back test, every tap-then-expect pair, every results-screen and modal action. Build it in *during initial test authoring*, not after a failed run.

---

### 16. `tester.tap` requires `ensureVisible` before it for any button inside a `SingleChildScrollView`
In headless chromedriver mode (`-d web-server`), `tester.tap` only registers a click on widgets in the visible viewport. Buttons below the fold are silently un-tappable — the tap is a no-op and the test stays exactly where it was.

The results screen wraps action buttons (NEW VOYAGE / PORT HOME / SET SAIL AGAIN — or the equivalent named buttons for this game) in a `SingleChildScrollView`. With a 1080-tall viewport and a 420px winner avatar + headline + stats card, the action buttons fall off-screen. Same applies to Save Modal Save and Resume Modal Resume buttons.

**Rule:** ANY shared helper that taps a button living inside a `SingleChildScrollView` (results-screen actions, save/resume modal buttons) must `ensureVisible + pump` first:
```dart
await tester.ensureVisible(button);
await tester.pump();
await tester.tap(button);
```
Apply this to `clickPlayAgain`, `clickChangeSettings`, `clickSelectDifferentGame` etc. in `shared/results_helpers.dart` AT INITIAL AUTHORING. Any inline tap on a results-screen / modal button in test bodies needs the same.

**Home-screen game cards are also a `SingleChildScrollView`.** As the GAMES list grew past 6 entries, bottom-row cards started landing offscreen at the default 1366×768 viewport. Direct `tester.tap(config.getGameCard())` was a silent no-op for those cards. Use the shared helper:
```dart
await UITestHelpers.tapGameCard(tester, config);
// (does ensureVisible + pump + tap + PumpSequences.navigation internally)
```
NEVER use `await tester.tap(config.getGameCard())` directly — it works at the moment a game is added but starts failing silently once enough other games are added that the new game's card lands below the fold. AR-6 grep enforces this: `grep -rE 'tester\.tap\(config\.getGameCard\(\)\)' integration_test/` (excluding `ui_test_helpers.dart` which references the deprecated pattern in docs) must return nothing.

---

### 17. Save/Resume tests that tap *Resume* must use the in-game save flow, not `preSaveGame`
`preSaveGame(GameSaveConfig.foo())` writes a placeholder `gameState = {'_marker': 'test'}`. When a test taps Resume, the menu calls `provider.restoreGame(savedGame)` → `[GameName]Game.fromJson(savedGame.gameState)` which immediately casts a required field (`json['grid'] as List<dynamic>` for grid-based games, etc.) and crashes. The screen then renders with `_currentGame == null` and crashes again — observed as "Multiple exceptions (2)" with no further detail in the headless log.

**Rule:** Reserve `preSaveGame` for tests that *only verify the resume modal appears* in the saved-games list. For any test that actually taps Resume:
```dart
// Set up + save via the in-game flow (real toJson() lands in gameState):
await setupAndStartGame(tester, config, playerNames: ['Alice', 'Bob']);
await throwDartViaMock(tester, someTarget);
await UITestHelpers.tapGameScreenBackButton(tester, config);
final saveButton = ElementFinders.getSaveGameModalSaveButton();
await tester.ensureVisible(saveButton);
await tester.pump();
await tester.tap(saveButton);
await PumpSequences.navigation(tester);

// Look up the savedId we just created:
final savedGames = await SaveGameService().loadSavedGames('[GAME_NAME_SNAKE]');
final savedId = savedGames.first.id;
// Now selectSavedGameTile + tap Resume can succeed.
```

---

### 18. The Resume modal's Resume button is disabled until a tile is selected
`ResumeGameModal._buildButtons` wires `onPressed: hasSelection ? () { ... } : null` where `hasSelection = _selectedGameId != null`. The user must tap a saved-game tile first to populate `_selectedGameId`. Tests that go straight to `tap(resumeButton)` are tapping a disabled button — silent no-op, modal stays visible.

**Rule:** Every test that taps Resume must first call:
```dart
await UITestHelpers.selectSavedGameTile(tester, savedId);
```
*Then* `ensureVisible + tap` the Resume button. Document with a comment so future readers know why the tile-tap is required.

---

### 19. `_startGame` must use `Navigator.push`, NEVER `pushReplacement` — AND register `.then((_) => _checkForSavedGames())`
`pushReplacement` removes the menu route from the stack. After "back from game" or "Save modal Save" both pop one route, the user lands on Home, not Menu. Tests that expect "back-from-game returns to menu with settings preserved" (a standard pattern across all games) fail because the menu is gone.

**Rule (push, not pushReplacement):**
```dart
void _startGame() {
  // ...startGame(...)
  Navigator.push(   // NOT pushReplacement
    context,
    MaterialPageRoute(builder: (_) => const [GameName]GameScreen()),
  ).then((_) => _checkForSavedGames());   // ← MANDATORY
}
```
Game→Results uses its own `pushReplacement` (game route is consumed). NEW VOYAGE / Change Settings on Results uses `pushAndRemoveUntil((r) => r.isFirst)` to push a fresh menu and discard everything below. Both flows still work correctly with the menu staying on the stack during gameplay.

**Rule (refresh `_hasSavedGames` after the game pops):** BOTH `_startGame` AND `_resumeGame` MUST register `.then((_) => _checkForSavedGames())` on the `Navigator.push`. The AppBar's conditional `ResumeGameButton` (rendered when `_hasSavedGames == true`) only shows after the menu's `_hasSavedGames` flag flips to true — which requires re-running the saved-games API check after the game-screen pops back. Without the callback, a user who saves their game via SaveGameModal returns to a menu where the resume button stays hidden, even though a saved game now exists.

**Why:** Pirate's Grid shipped with this asymmetry — `_resumeGame` had the `.then` but `_startGame` did not. Five canonical save_resume tests (`resume_button_color_when_enabled_test`, `resume_button_enabled_after_save_test`, `resume_button_hidden_after_resume_test`, `resume_button_shows_modal_test`, `resume_modal_start_new_game_test`) failed because their setup goes save → return → expect ResumeGameButton, and the button was never added to the AppBar. The fix was a one-line addition to `_startGame`. The asymmetry was caught only when the canonical 16-file save_resume pack was added; the pre-existing 6-sub-test file didn't exercise the in-game save flow that depends on this callback.

**How to apply:** AR-4 audit must grep `_startGame` and `_resumeGame` in every menu and confirm both push calls have `.then((_) => _checkForSavedGames())`. Reference: monster_mash menu lines 976-979 (`_startGame`) + 993-998 (`_resumeGame`); lunar_lander menu lines 116-121 + 136-139; carnival_horse_race menu (`_startGame` and `_resumeGame`). Pirates Grid menu lines 113-116 + 138-145 (after fix).

---

### 20. `_resetTurnForPlayer` (edit-score replay) must undo *all* win side-effects, including match-level
When the original turn caused a round-win that promoted to a match-win, `_applyRoundResult` already incremented `roundsWon`, set `matchWinnerId`, set `state = GameState.finished`, and set `gameEndTime`. If the reset only clears round-level fields (`winnerId` / `winningLine` / `isDraw`), `provider.hasWinner` (which reads `matchWinnerId != null || isMatchDraw`) still returns true, AND `processDartThrow` rejects the replayed segments via the `!isGameActive` early-return guard. The edit silently does nothing.

**Rule:** Capture pre-reset state BEFORE clearing round-level fields, then undo match-level side-effects when the turn caused them:
```dart
// Capture BEFORE clearing winnerId/isDraw:
final thisTurnWonRound  = game.winnerId == playerId;
final thisTurnWonMatch  = game.matchWinnerId == playerId;
final thisTurnDrewMatch = game.isMatchDraw && !thisTurnWonMatch;

// ... existing reset of winnerId/winningLine/isDraw, dart counters, cell undo ...

if (thisTurnWonRound) {
  game.roundsWon[playerId] = ((game.roundsWon[playerId] ?? 0) - 1).clamp(0, 99999);
}
if (thisTurnWonMatch || thisTurnDrewMatch) {
  game.matchWinnerId = null;
  game.isMatchDraw = false;
  game.state = GameState.playing;
  game.gameEndTime = null;
}
```

---

### 21. `processDartThrow` silently drops darts after `state = GameState.finished` — edit dialog tests must compensate
Provider's `processDartThrow` early-returns on `if (_currentGame == null || !isGameActive) return;`. After a Bo1 win, follow-up Miss throws don't make it into `currentTurnDartSegments`. When the edit-score dialog opens, it sees `initialSegments=['S{n}']` (only the winning dart). `_parseScore` returns `{ring: null, number: null}` for darts 2 and 3. The dialog's validation then fails: Save button stays disabled until every dart has a non-null ring.

**Rule:** Edit-score "remove winner" tests must explicitly set every dart in the dialog, not just the winning one:
```dart
await EditScoreHelpers.setDart1(tester, 'Miss');
await EditScoreHelpers.setDart2(tester, 'Miss');   // even if originally a Miss
await EditScoreHelpers.setDart3(tester, 'Miss');   // — provider dropped it after the Bo1 win
await updateScore(tester);
```
Document this in the test with a comment so future readers know why darts 2 and 3 are being set.

---

### 22. Edit-score helper `_parseSegment` must accept all common Miss representations
Score-display widgets render Miss as `'-'`, `'—'`, or empty depending on configuration. If `_parseSegment` only recognizes literal `'Miss'`, callers passing the displayed string get an `ArgumentError: Invalid segment format`. The error gets swallowed mid-tap and the Save button stays disabled — silent failure that's hard to diagnose.

**Rule:** Author `_parseSegment` (in BOTH `integration_test/shared/edit_score_helpers.dart` AND `test/shared/edit_score_helpers.dart` per rule 26) to accept the union of representations:
```dart
final trimmed = segment.trim();
if (trimmed.isEmpty
    || trimmed == '-'
    || trimmed == '—'
    || trimmed.toLowerCase() == 'miss'
    || trimmed.toLowerCase() == 'm') {
  return {'ring': 'Miss', 'number': null};
}
```
Also accept lowercase `d`/`t` in the regex prefix. And `ensureVisible` before every ring-button and number-button tap inside the dialog (rule 16 applies here too).

---

### 23. `PlayToCompleteStrategy.getNextThrow` must NEVER return `null` for a "deliberate miss"
The auto-play runner does `if (dart == null) break;` — null is its STOP signal. For multi-player games where one player must miss every dart (to designate the auto-play winner — see rule 10), returning null breaks the auto-play loop on the first miss-turn, leaving the game stuck and the test timing out.

**Rule:** Return a miss-shaped `SimulatedThrow` for deliberate misses:
```dart
if (currentPlayerId != designatedWinnerId) {
  return const SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0);
}
```
Match the pattern in `target_tag_strategy.dart` (which throws a "neutral" non-targeted number for non-winner turns). Never use `return null` to mean "miss" — the runner can't tell the difference.

---

### 24. Player column needs an inner `LayoutBuilder` to clamp character size by actual column height
The outer game-area `LayoutBuilder.constraints.maxHeight` is what's visible to the layout root, but by the time the player Column resolves layout inside `Expanded(Row(...))`, it receives only ~75% of that — AppBar (a 35pt title can push to ~100px) + Row crossAxis distribution + padding eat the difference. Computing `charSize` against the outer constraint produces values that overflow the inner column.

**Rule:** Wrap `_buildPlayerColumn`'s body in a `LayoutBuilder` and clamp `charSize` against `columnConstraints.maxHeight`, with a reserve that varies with active state AND with whether speedPlay is on:
```dart
return LayoutBuilder(builder: (context, columnConstraints) {
  final reserveH = isActive
      ? 220.0 + (game.speedPlay ? 56.0 : 0.0)   // +56 for the 36pt timer + spacing
      : 80.0;
  final maxByH = (columnConstraints.maxHeight - reserveH).clamp(0.0, double.infinity);
  final charSize = math.min(desiredCharSize, maxByH);
  return Column(...);
});
```
The OUTER LayoutBuilder should provide a `desiredCharSize` derived from width only; the inner LayoutBuilder is responsible for the height clamp.

---

### 25. UI test color assertions must compare RGB bytes, not `Color.value`, on Flutter web
`Color.value` is deprecated in Flutter 3.27+, and on Dart-to-JS its int representation can flip negative for high-bit ARGB values (sign-bit issue). `0xFFCD7F32` may compare as `-3342030`, breaking equality checks against the literal even when the color is correct.

**Rule:** Compare RGB bytes (always 0–255 ints):
```dart
return color != null
    && color.red   == 0xCD
    && color.green == 0x7F
    && color.blue  == 0x32;
```
Apply this to every visual-validation test that asserts on a widget's border, background, or text color.

---

### 26. Every shared helper that compiles in both contexts MUST stay byte-identical between `test/shared/` and `integration_test/shared/`
When the two drift, non-UI tests pass while UI tests fail with "Member not found" against the same-named class — the symbol is in one file but not the other, and the resolution depends on which test type is running. Drift happens silently and is hard to diagnose without reading both files.

**The set of mirrored helpers is dynamic, not enumerated.** Past versions of this skill listed "12 mirrored shared helpers" by name. That list went stale (a 13th, `pause_modal_helpers.dart`, was added at some point without the list being updated; `failure_screenshot_helper.dart` was nearly added as a 14th before being merged into `ui_test_helpers.dart`). Any rule that depends on a specific count is wrong by construction. The actual rule: for every `*.dart` file present in BOTH `integration_test/shared/` and `test/shared/`, the two copies MUST be byte-identical. Files present in only one directory (e.g. `mock_api_helpers.dart` and `player_test_utils.dart` in `test/shared/` only — they import packages non-UI tests have but UI tests don't, OR have widget-only dependencies the other way around) are intentionally non-mirrored and excluded from the parity check.

**Rule:** Whenever a Sonnet sub-agent is asked to add a method or function to a shared helper that exists in both directories, the prompt MUST instruct it to apply the IDENTICAL change to the other file in the same edit pass. Whenever a sub-agent CREATES a new shared helper, the prompt MUST decide up front whether the helper compiles in both contexts:
- **If yes** (no `package:integration_test` import, no widget-tree-only types, etc.), create it in BOTH directories from the start.
- **If no** (e.g. uses `IntegrationTestWidgetsFlutterBinding`, `WidgetTester`, etc.), create it ONLY in the directory that can compile it.

**Verification command (use this exact form — do NOT enumerate by name):**
```bash
diff -rq integration_test/shared test/shared 2>&1 | grep "differ" || echo "OK: all mirrored helpers byte-identical"
```
The `diff -rq` output emits one line per pair that differs (`Files X and Y differ`). The `grep "differ"` filter strips the expected `Only in test/shared: <file>` lines for non-mirrored helpers. If the grep finds anything, it's a parity violation that must be fixed before the build can proceed. AR-4 and AR-6 audits use this command directly, not a hardcoded list.

**Caveat — flutter drive web compile cache:** brand-new files under `integration_test/shared/` are silently ignored by the web compile cache (commit `4d1377e`). When a UI test imports a brand-new shared file, the compile fails with `org-dartlang-app:/...File not found` even though `dart analyze` and disk reads confirm the file exists. Workaround: add the new functionality as a static method on an existing long-lived helper class (e.g. `UITestHelpers`) instead of creating a new shared file. The `UITestHelpers.runWithFailureScreenshot` helper was placed inside `ui_test_helpers.dart` for exactly this reason — see `failure_screenshot_helper.dart` in commit `3cafc83` (deleted) for the pattern that didn't work.

---

### 27. Randomized game targets — every dart-throwing test must read the target at runtime
When the game randomizes targets per session (rule 9), tests that hardcode dart numbers (`throwDartViaMock(tester, 20)`) hit the wrong cell or no cell at all. The lookup pattern is required everywhere a test wants to deliberately hit a specific cell.

**Rule:** Add `get[GameName]CellTargetNumber(tester, row, col)` (or equivalent) to `integration_test/shared/provider_helpers.dart` AT INITIAL TEST AUTHORING when targets are randomized. Add a `throwForCellTarget(tester, target)` dispatch helper that reads the cell's target requirement (e.g. `CellTarget` for grid games) and chooses the right multiplier (`single` / `double` / `triple` / `bull`). Use these in every gameplay test. Sync to `test/shared/provider_helpers.dart` per rule 26.

```dart
// Helper in integration_test/shared/provider_helpers.dart:
static int get[GameName]CellTargetNumber(WidgetTester tester, int row, int col) {
  final grid = get[GameName]Grid(tester);
  return grid![row][col].target.number;
}

// In tests:
final t02 = ProviderHelpers.get[GameName]CellTargetNumber(tester, 0, 2);
await throwForCellTarget(tester, provider.currentGame!.grid[0][2].target);
```

---

### 28. Pause Modal canonical 20-test pack (7 menu + 8 gameplay + 5 results) is mandatory
A "minimal" pause modal pack of 1 testWidget per file misses the modal-stacking edge cases (pause-over-RemoveDartsModal, pause-over-SaveGameModal, EditScoreDialog auto-closes on disconnect, RemoveDartsModal still visible after reconnect) that are the actual bug-prone seam between the dartboard layer and per-screen overlays. These cases ONLY exist in the full 20-test pack.

**Why:** Pirate's Grid shipped with 3 testWidgets (1 per file). A cross-game test-count audit weeks later showed every other game had 20 (Carnival Derby, Target Tag, Monster Mash, Reef Royale, Clockwork Quest, Lunar Lander). The gap was invisible inside the "I wrote pause tests" claim — only counting tests across games surfaced it.

**How to apply:** In Phase 7, the `pause_modal/` subdirectory's three files MUST contain exactly 7, 8, 5 testWidgets respectively (canonical names listed in Phase 7 Step 7A's `pause_modal/` bullet). The pack is mirrored 1-for-1 from `integration_test/monster_mash/pause_modal/*` with finder substitutions only — no game-specific test additions/omissions. AR-6 audit check (m) verifies the count.

---

### 29. Save/Resume canonical 16-file pack (one testWidget per file) is mandatory
The "16 separate files, one testWidget each" structure is not a stylistic preference — it's the canonical helper pack used by the shared `SaveResumeHelpers` to map cleanly onto the user-flow surface. Collapsing into one file with multiple sub-tests OR shipping with fewer than 16 file names elides specific edge cases (resume-button-color-when-enabled, resume-button-hidden-after-resume, resume-modal-start-new-game, resume-modal-delete-individual, resume-modal-delete-all, resume-resave-overwrites).

**Why:** Pirate's Grid shipped with 1 file containing 6 sub-tests. Lunar Lander shipped with 6 separate files. Both missed 10 of the 16 canonical edge cases. The 3 "real-flow" tests (resume_game_loads_screen, resume_resave_overwrites, resume_auto_deletes_on_completion) are the *only* ones that catch `[GameName]Game.fromJson` regressions on actual restore — without all three, only the metadata-list happy path is verified.

**How to apply:** Phase 7's `save_resume/` subdirectory MUST contain the 16 files listed in Phase 7 Step 7A's `save_resume/` bullet, each with exactly 1 testWidget. The 3 real-flow files MUST use the in-game save flow (Rule 17) since `preSaveGame`'s placeholder gameState crashes restore. AR-6 audit check (n) verifies the file count and per-file testWidget count.

---

### 30. `test/providers/[game]_provider_game_test.dart` is mandatory — NOT optional, NOT replaced by screen-level tests
Every game except Lunar Lander and Pirate's Grid (both shipped without it, both caught only post-launch) has a dedicated `test/providers/[game]_provider_game_test.dart` with 44–50 pure-provider tests. The screen-level `test/screens/games/[game]/[game]_game_test.dart` tests via the screen wrapper and inherits the screen's coupling; the provider-level file isolates `processDartThrow` / `skipTurn` / win detection / turn advancement / `_resetTurnForPlayer` / option side-effects so regressions surface clearly when the screen layer changes.

**Why:** A screen-level test that passes after a provider regression is common — the screen often masks provider-level bugs by re-rendering reasonable state from stale data. Provider-isolated tests fail loudly. The two layers catch different classes of bugs.

**How to apply:** Phase 3 file list now requires this as file #4 (alongside model, provider, screen-level test). Minimum 40 tests, with required groups: initial state, `processDartThrow` per option/difficulty, turn advancement, win detection, per-option side-effects, round/match transitions, `_resetTurnForPlayer` undo (Rule 20), randomized targets (if applicable), `endGame` + `resumedSavedGameId`. AR-3 audit check (e) verifies file existence and ≥ 40 tests.

---

### 31. Per-option-value test coverage — one functional + one visual test per spec Section 7 value
A common failure pattern: spec Section 7 lists an option with N values (e.g., Difficulty: Easy/Medium/Hard); the implementer writes ONE test (typically Easy or default) and assumes the "option logic" is covered. The remaining N-1 values ship with zero functional UI coverage. Provider tests prove the option's logic; UI tests prove the option is wired through menu → screen and renders the expected behavior under the real frame loop.

**Why:** Pirate's Grid shipped with `plant_flag_easy_test.dart` and `plant_flag_medium_test.dart` but NO Hard test, NO Best Of 5 test, NO Speed Play timer-expires test. Three Section 7 values had zero functional UI coverage. Spec coverage audits passed because each option had "a test"; the per-VALUE gap was missed.

**How to apply:** In Phase 7 Step 7A, build the option-value coverage table (Section 5c) BEFORE writing tests. For every Section 7 row × every distinct value, plan one functional gameplay test file. For every option that has a *visible* effect (badge, color, glow, text), additionally plan one visual_validation test (Section 5d). AR-6 audit check (o) verifies the matrix is complete.

Test-naming conventions:
- Functional: `<option>_<value>_<behavior>_test.dart` (e.g., `difficulty_hard_corner_triple_required_test.dart`) or `<behavior>_<option>_<value>_test.dart` (e.g., `plant_flag_hard_test.dart`)
- Visual: `<option>_badges_test.dart` (groups Easy/Medium/Hard sub-tests) or `<element>_<state>_test.dart` (e.g., `cell_flag_colors_test.dart`, `winning_row_glow_test.dart`)

---

### 32. Visual-validation tests must assert APPEARANCE, not just EXISTENCE
A visual_validation test that only checks `findsOneWidget` for a spec-Section-10 element is incomplete. The spec says "X is rendered as Y" — your test must assert Y (text content, RGB color, border properties, icon presence), not just that X exists.

**Why:** Pirate's Grid spec Section 10B says "Winning cells get Treasure Gold pulsing glow + sparkle overlay" — no test asserted the glow color. The spec says "P1 cells get Blood Red border glow, P2 cells get Sea Foam Teal border glow" — no test asserted the colors. The spec says "Round tracker shows P1 wins in Blood Red, P2 wins in Sea Foam Teal" — only widget existence was tested. Six visible spec elements shipped with logical-only assertions and zero visual checks.

**How to apply:** When authoring a visual_validation test, for each assertion ask: "If the screen rendered this element with the WRONG color/text/icon/border, would my test still pass?" If yes, add the appearance assertion using RGB byte comparison (Rule 25), `find.descendant` for inner Text content, or BoxDecoration introspection for borders/shadows. AR-6 audit check (l) builds the visual-element coverage matrix; check (o) extends it to per-option-value visuals.

---

### 33. Test-coverage audits must be grounded in IMPLEMENTATION, not spec aspiration
The spec describes what the game *should* render; the screen code describes what the game *does* render. These diverge constantly: a designer simplifies during build (animal characters in place of a rocket icon), a feature is deferred (no "Round Complete" overlay yet), or a section was rewritten without updating the spec. A coverage audit that maps spec → tests without verifying implementation produces three classes of finding mixed together — and only one is a real test gap.

**Why:** A Lunar Lander coverage audit run from the spec alone produced 5 visual_validation test recommendations (rocket icon position, flame trail, ORBIT/MOON markers, tick marks, "CRASH!" overlay) for elements that did not exist in `lunar_lander_game_screen.dart`. The screen renders animal character images on a Flame Orange descent line — a deliberate design pivot. Writing those 5 tests would have produced 5 failing tests, not 5 closed gaps.

**Rule:** Every spec element being audited must be classified by reading the actual code:
- **Implemented + Tested** → no action
- **Implemented + Not tested** → real test gap; write the test
- **Not implemented** → NOT a test gap; surface as a separate "implement vs. update spec" decision to the user

**How to apply:** before proposing any test addition, grep the screen/provider/test_keys for the spec keyword. If the keyword is not in the code, the gap is a spec/code divergence — do not generate a test prompt for it. AR-6 audit check (l) enforces this for visual elements; the same principle applies to options, behaviors, and any other spec claim.

---

### 34. Menu screens must guard the player section with `playerProvider.isLoading`
`PlayerProvider._selectedPlayers` is shared global state that persists across games. The menu's post-frame `clearSelection()` runs AFTER the first paint, so without a loading guard the user briefly sees a flash of the previous game's players in the "Selected" column before the post-frame callback wipes them. On a slow `loadPlayers()` round-trip (cold start, slow server) the flash can last 100–500ms and is clearly visible.

**Why:** Pirate's Grid, Lunar Lander, Target Tag, and Clockwork Quest all shipped without this guard and exhibited the flash. Carnival Derby, Monster Mash, and Reef Royale had the guard from the start and behaved correctly. The asymmetry was caught only when a user reported "the previously selected players show briefly and then get unselected" on PG/LL — every other game looked empty from the start because the spinner masked the 1-frame initial paint with stale state.

**Rule:** Every menu screen MUST wrap its main content (the LayoutBuilder/Row containing left+right panels) in a `Consumer<PlayerProvider>` that returns a centered `CircularProgressIndicator` while `playerProvider.isLoading` is true:
```dart
Consumer<PlayerProvider>(
  builder: (context, playerProvider, child) {
    if (playerProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder( /* or Row */
      builder: (context, constraints) { ... },
    );
  },
),
```

The post-frame callback in `initState` (which calls `loadPlayers()` → sets `_isLoading=true` → notifies → loads → `_isLoading=false` → `clearSelection()`) takes over the rendering window between first paint and load completion. The Consumer rebuilds during that window, the spinner replaces the layout, and the user sees "spinner → empty list" instead of "stale list → empty list".

**How to apply:** in Phase 4 (Screens), the menu screen sub-agent must include this guard. AR-4 audit row should grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` for `playerProvider.isLoading` and `CircularProgressIndicator` — both must be present in the menu's build tree. Reference: monster_mash menu lines 208-228, reef_royale menu lines 198-213.

---

### 35. Real background image used in EVERY wireframe + EVERY screen
The mockups must reference the actual `[GameName]-Background.png` asset on every screen — menu, game, results — via `<img>` or CSS `background-image: url(...)`. CSS gradients or solid fills as a "stand-in" silently teach the wireframe sub-agent that the background is generic, and the same omission then carries into the Flutter screens.

**Why:** Pirate's Grid Stage A wireframe used a CSS parchment-style gradient as the menu background; the actual user-provided `PiratesGrid-Background.png` is a fully illustrated pirate scene. The discrepancy wasn't caught until late visual validation, by which time UI elements had been laid out without an overlay budget for the busy art. Recurring across at least 3 game builds.

**How to apply:** Phase 2 staged approval gates — the orchestrator's AR-2 review for each stage must `grep -c "[GameName]-Background\|[GameName]-Bg" temp_wireframes/[GAME_NAME_SNAKE]/<stage>.html`. Must report ≥ 1 hit per HTML. AR-1 (Phase 1) also adds a background-image suitability check: read the image, classify as TEXTURE (suitable backdrop) vs ILLUSTRATED SCENE (will compete with UI), surface to user as an overlay-budget decision before Phase 2 starts.

---

### 36. Game UI fills full screen height; dartboard emulator is a transparent OVERLAY
The dartboard emulator section only renders when `!dartboardProvider.isConnected`; in production gameplay (board connected) the game content has the FULL screen height. Wireframes that reserve vertical space for the emulator (treating it as a `Column[gameContent, dartboardEmulator]` sibling) propagate a too-short content area into the Flutter screens, which then overflow at the headless 1366×768 viewport.

**Why:** Pirate's Grid wireframes laid out the gameplay screen with the emulator as an inline child, eating ~150-200px of vertical height. When the screen was implemented in Flutter, the player column / grid clamped against this reduced height; cellSize was wrong, character size was wrong, RenderFlex overflowed by 76px. Multiple round-trip fixes (`_buildPlayerColumn` inner LayoutBuilder, speedPlay reserve, grid centering) addressed the symptoms but the wireframe model had been wrong from the start.

**How to apply:** Phase 2 Stage B requires the wireframe to draw `gameContent` at `width: 100%; height: 100%` and the dartboard emulator as `position: absolute; bottom: 0` (or a `Positioned(bottom: 0)` Stack child OUTSIDE the body Stack — sibling of Scaffold). The `position: absolute` model mirrors the actual Flutter widget tree and prevents the wireframe from baking in a phantom height reservation. AR-2 review checks the wireframe HTML for `position: absolute; bottom` on the emulator block.

---

### 37. Wireframes must validate at the headless test viewport (1366×768)
Wireframes designed at desktop monitor sizes (1920×1080+) look great in the browser preview but overflow at the parallel runner's default headless Chrome viewport. The screenshot test then captures a clipped/overflowed state that the orchestrator must triage as a layout bug — usually requiring screen code changes after the fact.

**Why:** PG wireframes were authored at desktop dimensions and looked clean in browser preview. The actual screenshot tests captured a 1366×768 viewport showing 76px column overflow, off-center grid, oversized winner character. Each was a separate fix-and-recapture cycle.

**How to apply:** Phase 2 every wireframe HTML wraps content in `<div style="width: 1366px; height: 768px; overflow: hidden; ...">` for the visual review. Inside this wrapper, layout primitives (% widths, `min/max` clamps, flex/grid) MUST adapt without introducing horizontal scroll, clipped buttons, or content overflow. AR-2 review opens the HTML at exactly 1366×768 in dev tools and confirms no overflow indicators.

---

### 38. UI tests wrap their bodies in `UITestHelpers.runWithFailureScreenshot` during the build phase
When a UI test fails the only artifact available in the standard text log is a stack trace — no screen state, no DOM, no rendered pixels. Authors who add screenshot capture retroactively (after a failure) waste an iteration cycle: failed run → inspect log → instrument → re-run. Building the failure capture into every test from initial creation removes that cycle and turns the first failed run into an actionable diagnostic.

**Why:** Multiple PG debug rounds (rounds 2-7 of the post-build refinement) consisted entirely of "test fails → add diagnostics → re-run". Each round cost 5-15 minutes of test execution time. The user explicitly requested that diagnostic instrumentation be included from initial creation so the first failed run produces a screenshot the orchestrator can read instead of an opaque "Multiple exceptions (2)".

**Why build-phase-only:** the wraps add per-test boilerplate that's noise once tests are stable. The production runner uses `test_driver/integration_test.dart` which has no `onScreenshot` callback — the wrap would be inert there anyway, but its presence still adds visual clutter. Removing the wraps at the Phase 9 transition aligns the new game's tests with every other game's tests in form.

**How to apply:**
- **During build (Phase 7 iterative authoring):** every test in the new game's pack wraps its body in `UITestHelpers.runWithFailureScreenshot(tester, '[GAME_NAME_SNAKE]_<subdir>_<test_basename>', () async { /* body */ })`. Tests run via `flutter drive --driver=test_driver/screenshot_test.dart --target=<test> -d chrome --dart-define=SERVER_PORT=<port> --browser-dimension=1366x768`. Failure PNGs land in `temp_screenshots/failures/<sanitized-test-name>_<timestamp>.png`.
- **At Phase 9 transition (after Gate 4 passes):** the "Failure-screenshot wrap removal" step in Phase 9 dispatches a Sonnet sub-agent to unwrap every test in the new game's pack. The helper itself stays in `integration_test/shared/ui_test_helpers.dart` — only the per-test wraps are removed. Future game builds will use the helper again during their own Phase 7.
- **Helper location:** `UITestHelpers.runWithFailureScreenshot` (a static method on `UITestHelpers` in `integration_test/shared/ui_test_helpers.dart`). The helper is part of `UITestHelpers` rather than a standalone file because brand-new files under `integration_test/shared/` are silently ignored by flutter drive's web compile cache (documented in commit `4d1377e` and Rule 26).
- **Driver:** the `test_driver/screenshot_test.dart` driver has the `onScreenshot` callback that writes PNG bytes to disk (with `mkdir -p` for subdirectory paths). The default `test_driver/integration_test.dart` driver does NOT have `onScreenshot` — that's intentional, since post-build tests don't need it.
- **Verification:** `integration_test/_smoke/failure_screenshot_smoke_test.dart` is a deliberately-failing test that exercises the helper. Lives outside any game directory so neither runner picks it up. Invoke directly via `flutter drive` after a Flutter SDK upgrade or driver change to confirm the mechanism still works.
- **AR-4 audit during build:** every `*_test.dart` under `integration_test/[GAME_NAME_SNAKE]/` (excluding `_helpers.dart` and the smoke test) MUST contain `UITestHelpers.runWithFailureScreenshot`. AR-4 enforces this until Gate 4 passes; after Gate 4, AR-4 enforces the OPPOSITE (no wraps in any test).

---

### 39. UI tests authored iteratively: screenshot first, then 1 per category easiest-to-hardest
Authoring all UI tests in one batch and running them all at once produces a wall of failures sharing the same root causes (missing ensureVisible, hardcoded grid targets, missing in-game save flow, etc.). The orchestrator then debugs one category at a time across many files instead of fixing the root once and replicating.

**Why:** PG had 7+ debugging cycles (commit titles "Round 2/3/4/5/6 fixes ...") because all 47 UI tests were authored upfront. Each round fixed a single bug class across dozens of files. The user requested that future builds author one test per category at a time, run it, fix the root, then replicate.

**How to apply:** Phase 7 Step 7A sub-rule 1.6 specifies the order of categories (visual_validation screenshot test → menu_and_settings → add_player → navigation → gameplay → pause_modal → results_screen → save_resume → edit_score → play_to_complete) and the per-category loop (author one → run → fix → replicate). The orchestrator MUST resist the temptation to delegate "write all tests in parallel" to a single sub-agent batch.

---

### 40. Screenshot test for timer-driven UI states must freeze the timer
Screenshot test entry that captures a state involving an active `Timer.periodic` (Speed Play countdown, animation loop) deadlocks: pumping `pump(Duration)` on a continuously-firing timer never settles. Past failure: PG screenshot test halted at #12 of 15 ("game_speed_play_timer transition"). The orchestrator waited 4 minutes before killing — wasted iteration time.

**How to apply:** Phase 8 STEP 1 imposes a 25-second per-screenshot progress timeout (down from 60s). For the timer-driven scene specifically: (a) freeze the timer before capturing — set the screen state to a fixed timer value via a `provider.setSpeedPlayTimerForTest(...)` hook if exposed, OR (b) capture immediately on the same frame the timer was started (no `pump(Duration)`), OR (c) skip that visual state and document it in the spec coverage report as a known gap. The screen and provider may need a test hook (`@visibleForTesting void setTimerForCapture(int seconds) { ... }`) added in Phase 4 to support this without exposing private state production-side.

---

### 41. Cross-game parity audit — grep all 6 existing screens before creating the 7th
Three production bugs in the last two months followed the same shape: 5 or 6 of the 6 existing games' screens implemented some pattern; the new (7th) game's screen omitted it. Each was caught only post-launch by a user observing the inconsistency, not by AR review.

**Past failures matching this shape:**
- **Cross-game selection leak (commit `d96c19f`)** — 5 of 6 menus called `playerProvider.loadPlayers()` then `playerProvider.clearSelection()` in their `addPostFrameCallback`. Lunar Lander did not. Result: selecting players in CD then opening LL left those players already selected. Caught after 6 menus had shipped.
- **`isLoading` spinner guard (commit `d96bac2`)** — 3 of 7 menus (CD, MM, RR) wrapped their main content in `Consumer<PlayerProvider>` returning `CircularProgressIndicator` while loading. TT, CQ, LL, PG did not. Result: brief flash of stale selection on each of those 4 menus. Caught after 7 menus had shipped, when a user reported the flash on PG.
- **`.then((_) => _checkForSavedGames())` after `_startGame` (commit `042d791`)** — 6 menus had this callback on BOTH `_startGame` and `_resumeGame`. PG had it on `_resumeGame` only — `_startGame` was missing it. Result: 5 canonical save_resume tests failed because the AppBar's conditional `ResumeGameButton` never appeared after the in-game save flow. Caught when the canonical 16-file save_resume pack ran for the first time on PG.

In every case, the omission was invisible to the new game's tests in isolation; only cross-game comparison surfaced it.

**Rule:** AR-4 (Phase 4 review) MUST execute a parity grep for every shared pattern before approving the screens. The audit:

1. **Enumerate each lifecycle hook** (initState, post-frame callbacks, dispose, addPostFrameCallback bodies, button onTap handlers, Navigator.push call sites) in EVERY existing game's three screens (`menu_screen.dart`, `game_screen.dart`, `results_screen.dart`).
2. For each method/handler, run `grep -n '<canonical-line>' lib/screens/games/*/[gN]_<screen>.dart` across ALL games — check the new game's file is in the result list. Examples:
   - `grep -n 'playerProvider.loadPlayers' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n 'playerProvider.clearSelection' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n 'playerProvider.isLoading' lib/screens/games/*/[g]_menu_screen.dart`
   - `grep -n '_checkForSavedGames()' lib/screens/games/*/[g]_menu_screen.dart` — and verify it appears AFTER both `_startGame`'s push AND `_resumeGame`'s push
   - `grep -n '\.then((_)' lib/screens/games/*/[g]_menu_screen.dart` — every Navigator.push from a menu should have a `.then` callback
3. **For every grep, the new game's file MUST appear in the output.** Any omission is a parity violation surfaced to the user as a corrective sub-agent dispatch BEFORE the screens are accepted into Phase 5.
4. **Add new patterns to the parity grep list** as they're discovered. The list is intentionally append-only — every recurrence-prevention rule (Rules §8, §19, §34, §41 itself) adds a new grep line.

**How to apply:** AR-4 audit must include a "Cross-game parity grep" section listing every grep line and the new game's name in each result. If any grep returns zero hits for the new game, AR-4 fails and the orchestrator dispatches a corrective sub-agent. This rule is the meta-protection: every individual rule (§8 player persistence, §19 _checkForSavedGames, §34 isLoading guard) gets enforced via the parity grep, even if the individual rule's "How to apply" section drifts out of date.

---

### 42. Every new game registers a `GameMetadata` entry in the filter registry
The home-screen filter bar reads `lib/constants/game_filter_registry.dart` to decide which cards to render given the user's selections. A new game whose card is added to `home_screen.dart` but whose registry entry is missing will:
- Show in the unfiltered view (because home_screen falls back to "show all" when the registry lookup returns null)
- Be invisible in EVERY filtered view (because no metadata = no match)
- Trigger the orphan-bucket check in `test/models/game_metadata_test.dart` if a filter value loses its only game

This is exactly the kind of asymmetry Rule §41's parity audit catches — the new game's id should appear in `home_screen.dart`'s `games` list AND in the registry's `_all` list AND in `test/models/game_metadata_test.dart`'s `expectedIds` set. Any of those three missing is a parity violation.

**Rule:** Phase 4 step 7a (Add the game card) is followed immediately by step 7b (Register filter metadata). Both happen in the SAME edit pass — the card and the registry entry are added together so they can't drift.

**How to apply:** AR-4 grep adds:
- `grep -n "'[GAME_NAME_SNAKE]'" lib/screens/home_screen.dart` — must match (the card's `gameId`)
- `grep -n "gameId: '[GAME_NAME_SNAKE]'" lib/constants/game_filter_registry.dart` — must match (the registry entry)
- `grep -n "'[GAME_NAME_SNAKE]'" test/models/game_metadata_test.dart` — must match (the `expectedIds` Set)
All three must hit. If any returns zero, AR-4 fails. Update `test/models/game_metadata_test.dart`'s `expectedIds` Set in the same change to keep the registry-coverage test passing.

**Adding a new filter criterion** (rare but supported):
1. Add a new enum to `lib/models/game_metadata.dart` and a field on `GameMetadata`.
2. Update EVERY existing entry in `GameFilterRegistry` to set the new field.
3. Add a new `FilterCriterion` enum value.
4. Add a dropdown in `lib/widgets/game_filter_bar/game_filter_bar.dart`.
5. Add `HomeKeys.filter<New>Button` and `filter<New>Option` in `lib/constants/test_keys.dart`.
6. Add a UI test in `integration_test/home_screen/filter_bar/`.
7. Add an OR-within-criterion case to `test/models/game_metadata_test.dart`.

The `matchesFilters` switch must cover every `FilterCriterion` — if a new criterion is added without a switch case, Dart's exhaustive-switch analyzer fails the build. That's the compile-time backstop.

---

### 43. Parallel runner worktree setup is FAIL-LOUD; existence check before workers spawn
The parallel UI runner clones the repo into one git worktree per worker so each worker has an isolated `build/` and `.dart_tool/`. If any worktree fails to create, that worker runs `flutter drive` in a non-existent directory and every test in its pack fails with `the system cannot find the path specified` — but the swallowed-error pattern (`>nul 2>&1` on `git worktree add`) masks the real cause.

**Why:** A user's UI run produced 27 failures across 4 games (target_tag, lunar_lander, pirates_grid, reef_royale). All test logs ended after the runner's "Worktree: ..." prefix line — no compile output, no test output, just "FAILED". Investigation showed `git worktree list` had only the main repo registered: `git worktree add` had failed silently for 6 of 9 workers, leaving the runner pressing on with workers pointed at empty paths. The worktree creation loop's `_wt_ok=0` check existed but didn't catch every failure mode (e.g., when leftover dirs from a prior run blocked rmdir → blocked `git worktree add` because destination exists → errorlevel propagation through nested IFs got confused).

**Rule:** `run_ui_tests_parallel.bat` worktree setup follows four invariants:
1. **Errors go to a log, not /dev/null.** Replace every `git worktree <op> ... >nul 2>&1` with `... >> "!_WT_LOG!" 2>&1` (where `_WT_LOG = !_PARALLEL_DIR!\worktree_setup.log`). When a `git worktree add` fails, the script prints the worker name, points at the log, and aborts.
2. **Prune metadata before cleanup.** A `git worktree prune` runs BEFORE the rmdir loop. Without this, stale `.git/worktrees/<name>` metadata pointing at deleted directories will make subsequent `git worktree add` fail with "fatal: '<path>' already exists" even though the dir was removed.
3. **Pre-flight kill of orphaned test processes.** Before the cleanup, kill leftover `chromedriver.exe` and `flutter_tester.exe` processes (blanket-safe — test-only) and port-scoped `dart.exe` instances bound to ports 9001-9020 (so we don't accidentally kill the user's IDE-launched dart server on a different port). A previous run that was force-killed leaves orphaned processes that hold worktree files open, blocking rmdir, and bind test ports — preventing the new run's setup. Past failure: a parallel run produced 8+ leftover chromedriver.exe processes that blocked all subsequent worktree creation.
4. **Existence check before workers launch.** After the creation loop, verify every expected worktree project dir contains a `pubspec.yaml`. If any are missing or incomplete, abort with the worker name(s) printed — workers MUST NOT spawn pointed at missing paths.

**Plus:** if rmdir leaves any leftover dir in `_WORKTREE_BASE` (because a prior chromedriver/dart process STILL has files locked despite the pre-flight kill), surface it loudly with the dir name and a hint about killing leftover processes before re-running.

**Absolute path for `_WORKTREE_BASE`:** the variable is computed as `!_SCRIPT_DIR!\integration_test_output\parallel\worktrees`, NOT a relative path. Past failure: relative `_WORKTREE_BASE` worked for `git worktree add` (called from the bat's cwd) but flutter sub-processes inherited a different cwd and `flutter pub get` printed "The system cannot find the path specified." for every worker. Absolute paths remove that variable.

**How to apply:** verify the runner has all four invariants:
```bash
grep -c '>> "!_WT_LOG!" 2>&1' run_ui_tests_parallel.bat   # must be > 0 (errors logged)
grep -c 'git worktree prune' run_ui_tests_parallel.bat   # must be ≥ 2 (before AND after rmdir)
grep -c 'taskkill /F /IM chromedriver' run_ui_tests_parallel.bat  # must be > 0 (pre-flight kill)
grep -c 'pubspec.yaml' run_ui_tests_parallel.bat         # must be > 0 (existence check)
grep '_WORKTREE_BASE=' run_ui_tests_parallel.bat | grep -c '_SCRIPT_DIR'  # must be > 0 (absolute path)
```

---

### 44. PlayerListPanel widget choice — extract in Phase 0, brief every Phase 2 sub-agent
Tiki Golf was the first team-game build under this skill. Its initial Stage A wireframe was authored against `DualPlayerListPanel` conventions (two side-by-side AVAILABLE / SELECTED panes) because the Phase 4 prompt template heavily documents DualPlayerListPanel layout rules. The spec actually called for `TeamPlayerListPanel` (a single scrolling list — Target Tag pattern). Reviewer caught it; corrective sub-agent had to redo the panel.

**Two widgets, two layouts. Cite which one the spec uses BEFORE wireframing:**
- **`TeamPlayerListPanel`** (Target Tag, Tiki Golf, any future team-mode game) — SINGLE scrolling player list with header row (count chip + ADD PLAYER button), per-row selected/unselected accent borders. Selected players sort to the top. In Manual team mode, each selected row gets a trailing team-crest icon and the team-assignment boxes appear BELOW the list.
- **`DualPlayerListPanel`** (Carnival Derby, Reef Royale, Clockwork Quest, Lunar Lander, Monster Mash, Pirate's Grid) — two side-by-side AVAILABLE / SELECTED panes with players moved between them. Specific recipe: `availableContainerMargin: EdgeInsets.zero`, `selectedContainerMargin: EdgeInsets.zero`, `listGap: 4`. The recipe is documented in detail in the Phase 4 prompt template's DualPlayerListPanel section.

**Phase 0 Step 8 must extract the widget choice from spec Section 1 ("Player List Pattern" row in the Overview table)** and propagate it as a sub-agent prompt placeholder `[PLAYER_LIST_WIDGET]` so the Phase 2 Stage A prompt knows which layout to author.

**The DualPlayerListPanel-specific recipe (`availableContainerMargin: zero, selectedContainerMargin: zero, listGap: 4`) DOES NOT apply to TeamPlayerListPanel.** Do not cite or apply it when the spec uses TeamPlayerListPanel.

**How to apply:** when extracting the player-panel widget choice in Phase 0, save it to memory (or `temp_wireframes/<game>/asset_paths.md` carry-forward decisions) so every later Phase 2 / Phase 4 sub-agent gets a literal reference to the correct widget name in its prompt's "Read first" section. AR-4 audit (pp) gains an extra grep: `grep -c 'TeamPlayerListPanel\|DualPlayerListPanel' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` — exactly one of those must appear, matching the spec.

---

### 45. TeamPlayerListPanel is single-column regardless of player count
At 16 selected players (Team mode max), Tiki Golf's initial wireframe sub-agent assumed the list was "too long" for one column and switched to a 2-column CSS grid. Target Tag uses a single scrolling column even at its own max player count; the underlying widget renders one column.

**Rule:** the TeamPlayerListPanel's scrollable list is ALWAYS a single vertical column with `overflow-y: auto` for long lists. Do NOT switch to a 2-column grid at high player counts. Match the underlying widget's `ListView.builder` shape exactly (`team_player_list_panel.dart:243-292`).

**How to apply:** Phase 2 Stage D Team variants. When authoring `menu_team_random_<N>p.html` for N ≥ 12, the player list is still `display: block` (or `display: flex; flex-direction: column`) inside a scrollable container. AR-2 review adds a check: `grep -c 'grid-template-columns' temp_wireframes/<game>/menu_team_*.html` — only the settings-grid (`1fr 1fr`) should match; any grid on the player list is a violation.

---

### 46. Team-mode menu: team-assignment boxes stack BELOW the player list
Initial Tiki Golf wireframe placed the team-assignment boxes alongside the player list in a horizontal `flex-direction: row` panel body. Target Tag stacks them vertically — player list on top, then an "Assign Teams" caption, then the team boxes below. Reference: `lib/widgets/player_list_panel/team_player_list_panel.dart:109-136` (`_buildFixedHeightLayout`) which uses a `Column` with the team boxes as the LAST children after the player list.

**Rule:** in Team + Manual mode wireframes, the player-panel body is `flex-direction: column`. Inside (top → bottom): (a) header row with count + ADD PLAYER button; (b) scrollable player list with `max-height: ~160-180px` so it doesn't push team boxes off-screen; (c) "Assign Teams" caption (Boogaloo 14pt with 4-corner text-shadow); (d) the row of 4 team-assignment boxes as `display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; flex-shrink: 0`. The panel body uses `overflow: visible` so children aren't clipped.

**How to apply:** Phase 2 Stage D Team+Manual prompt template includes this layout explicitly. AR-2 grep: in any `menu_team_manual_*p.html`, `grep -c '"player-panel-body"' file | column-flex` must match. AR-4 grep on the Phase 4 menu screen: `grep -c 'crossAxisAlignment.*start\|Column(' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` near the player-panel block must show a single-column structure.

---

### 47. Team-assignment box content: ONLY crest + player count (no team name, no player-name chips)
Initial Tiki Golf team boxes contained crest + team name + a list of player-name chips. Reviewer wanted: just the crest (focal point) + a count caption ("N players"). Player NAMES live on the player tiles as trailing team-crest icons — that's the Target Tag-style visual mapping between players and teams.

**Rule:** each team-assignment box in Team+Manual mode contains ONLY:
- Team crest (~56–64 px circular)
- Player count caption: "N players" (Boogaloo 14pt Sand White with 4-corner text-shadow)

DO NOT render the team name text inside the box. DO NOT render player-name chips inside the box. When a player is selected AND assigned to a team in Manual mode, the team's crest renders as a SMALL trailing icon on the player tile in the main player list — that's the only place where the player-to-team mapping is visible.

Box CSS pattern:
```css
.team-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 6px;
  border: 1px solid rgba(255,255,255,0.20);
  border-radius: 8px;
}
.team-crest-large { width: 56px; height: 56px; border-radius: 50%; overflow: hidden; }
.team-player-count { font-family: var(--font-display); font-size: 14pt; color: var(--sand-white); text-shadow: <4-corner outline>; }
```

**How to apply:** Phase 2 Stage D Team+Manual prompt template specifies this layout. Phase 4 menu-screen sub-agent renders the actual widget the same way; the TeamPlayerListPanel widget's `_buildTeamAssignmentBoxes` (`team_player_list_panel.dart:613`) already follows this convention internally. AR-2 review: in any `menu_team_manual_*p.html`, `grep -c '"team-name\|"team-player-chip' file` must be 0 in the HTML (CSS definitions kept as `display: none` for backward compatibility are fine).

---

### 48. Mode-dependent maxPlayers cap — solve in Phase 0, surface to Phase 4
Tiki Golf specs `maxPlayers: 16` for the `TeamPlayerListPanelConfig.tikiGolf()` but Solo mode caps at 4 and Team mode caps at 16. The default widget reads a single `config.maxPlayers` for the count chip ("N/16 selected") which is wrong in Solo. This is a recurring spec/widget mismatch for any game whose Solo and Team modes have different caps.

**Rule:** when the spec has different player-count caps per mode (Solo vs Team), surface it in the Phase 0 build plan as a Phase 4 implementation decision. Two valid implementation paths:
- **Preferred:** add `maxPlayersSoloMode: <N>` to `TeamPlayerListPanelConfig`; the widget reads the mode-appropriate value for the header count chip + `selectPlayer(maxPlayers:)` call.
- **Alternative:** menu screen overrides the cap via a screen-level intermediary that gates `selectPlayer` based on the current mode flag.

Wireframes must show the mode-appropriate cap in the count chip: `N/4 selected` in Solo wireframes, `N/16 selected` in Team wireframes. The asset_paths.md manifest captures the implementation decision so Phase 4 picks it up.

**How to apply:** Phase 0 Step 8 spec-extraction adds: "Player-count caps per mode — extract from Overview / spec Section 1 / Section 7. If Solo and Team caps differ, record both AND record the implementation-path decision (config-knob preferred) in the asset_paths.md manifest." AR-3 gains: verify the count-chip rendering path reads the mode-appropriate cap in the menu screen unit tests.

---

### 49. Team gameplay screen: transparent Teams panel; logo + score only; no team names
Tiki Golf spec Section 10B described per-team boxes with team-color bg + 2px Lagoon Blue border for the active team. Reviewer wanted simpler: no boxes at all (transparent), no team names; each team shows just the crest + the running team score below it. Active team distinguished only by a left-edge accent + a faint bg tint.

**Rule:** the left-side Teams panel on the game screen (Team mode only):
- 160px wide, transparent background, no border on the panel container
- "TEAMS" header at top (optional — many specs omit this)
- One row per configured team, each row shows:
  - Team crest at 56×56 (slightly larger because it's the only visual identifier)
  - Team's running ± par score below the crest (Boogaloo 18pt Bold; Lagoon Blue under par / Sand White even / `#FF8C42` over par)
- Active team: `border-left: 3px solid var(--lagoon-blue)` + `background: rgba(0,180,216,0.10)` (slight tint). Inactive teams: `opacity: 0.60`, no other decoration.
- NO team names anywhere. NO per-team boxes/borders/bg fills.

Reference: `temp_wireframes/tiki_golf/game_team_early_8p.html` is the canonical example.

**How to apply:** Phase 2 Stage D Team gameplay prompt template includes this spec. Phase 4 menu-screen sub-agent implements the panel the same way. AR-4 audit: read the game screen and verify the Teams panel renders zero team-name text widgets (only crest + score), zero per-team Container backgrounds, only the active-team's left-edge accent.

---

### 50. Team gameplay scorecard: ONLY the current team's players (Solo-style)
Tiki Golf spec Section 10B described a multi-team scorecard with team primary rows + collapsed teammate sub-rows. Reviewer simplified: the scorecard shows ONLY the 1–4 players on the CURRENT team using the SAME layout as Solo mode. Team-level totals live in the Teams panel; the scorecard is per-player for the active team.

**Rule:** in Team mode, the game-screen scorecard renders one row per player on the currently-throwing team (max 4 rows). Headers and per-cell styling are IDENTICAL to Solo mode (H1–H9 + Total, current player's row highlighted with Lagoon Blue tint + left-edge accent + Lagoon Blue name). DO NOT render team primary rows. DO NOT render teammate sub-rows for other teams. DO NOT render best-ball-contributing dot indicators.

Above the scorecard, add a small caption naming the active team (e.g., "Sharks scorecard" Boogaloo 14pt Sand White with 4-corner text-shadow) so the user knows which team's data is shown.

**How to apply:** Phase 2 Stage D Team gameplay prompt template specifies this exact pattern. Phase 4 game-screen sub-agent builds the scorecard with a `currentTeamPlayerIds` selector and renders one row per id. AR-4 audit: `grep -c 'team-primary-row\|team-sub-row' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` must be 0 (no nested team/sub-row rendering); the scorecard structure matches Solo.

---

### 51. Team results screen: 2-column team-blocks + internal-scroll scorecards
Tiki Golf spec Section 10C described a single wide scorecard. Reviewer wanted: each team gets its own mini-scorecard block, blocks arranged in 2 columns (4 teams → 2+2, 3 teams → 2+1, 2 teams → 1+1, 1 team → centered). Plus the scorecards area must scroll internally so the action buttons stay visible at the bottom of the 1366×768 viewport.

**Rule:** team-mode results screen replaces the single wide scorecard with a 2-column team-blocks layout. Each team-block contains:
- Team crest 64×64 at the top
- Team name caption below (Boogaloo 16pt Sand White; Lagoon Blue for the winning team)
- Mini-scorecard table (headers + per-player rows + a best-ball total footer row)
- Winning team's block has a `border: 2px solid var(--lagoon-blue)` and Lagoon Blue team total

**Distribution rule:** left-to-right, 2 teams per column when possible.
- 4 teams → col1: Teams 1+2; col2: Teams 3+4
- 3 teams → col1: Teams 1+2; col2: Team 3
- 2 teams → 1 per column
- 1 team → single-column centered

**Scroll rule:** wrap the team-blocks columns in a `.scorecards-scroll` container with `flex: 1; min-height: 0; overflow-y: auto`. The action buttons sit OUTSIDE this container (last child of `.main-area`) with `flex-shrink: 0` so they stay pinned at the bottom of the canvas. Winner card stays at the top with `flex-shrink: 0`.

**Heading text:** "GOLDEN TIKI CHAMPIONS!" (plural — team mode) vs "GOLDEN TIKI CHAMPION!" (singular — solo). The Dart screen branches on `gameMode` to pick the right text. Pluralize equivalents for non-golf games (CHAMPS / WINNERS / etc.).

**How to apply:** Phase 2 Stage D Team results prompt template includes the 2-column distribution rule + the scrollable container. Phase 4 results-screen sub-agent renders the same structure. AR-4 audit: `grep -c '"scorecards-scroll\|overflow-y' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart` ≥ 1 in team-mode branch; action buttons live in a Row that is a sibling of (not nested inside) the scroll container.

---

### 52. Random N-of-M team-crest selection — wireframe varies, Phase 4 implements
When a spec calls for "N team crests picked at random from a pool of M" (M > N), this is a runtime randomization akin to Reef Royale's creature shuffle.

**Rule for wireframes (Phase 2 Stage D):** pick N specific crests for the wireframe to demonstrate one valid distribution. Don't always use the first N from the spec — vary across mode-variant files so a reviewer sees that any random subset is valid. Include a code comment near the team-crest rendering: `<!-- In production, N of the M available crests are randomly picked per game; this wireframe shows one such pick. -->`. Capture the random-pick rule for Phase 4 in `temp_wireframes/<game>/asset_paths.md`.

**Rule for Phase 4 implementation:** the provider's game-construction (model factory) calls `crests..shuffle(Random())..take(N)` and stores the picked list on the game model (e.g., `List<String> teamCrestPaths` length N, frozen after construction). Resume restores the same list from saved-game JSON. Mirror Reef Royale's `lib/models/reef_royale_game.dart:206-236` creature-assignment pattern.

**How to apply:** Phase 2 Stage D prompt template includes the random-pick wireframe convention. Phase 3 model+provider prompt cites the shuffle pattern. Non-UI test for the model: "two consecutive constructions produce different `teamCrestPaths` ordering across N≥20 fresh games (statistical sanity)" — same approach as Reef Royale Random Reefs test #38.

---

### 53. Random team-distribution table — full-table coverage tests are mandatory
Tiki Golf's spec Section 5 defines a deterministic `randomDistribution(N)` table mapping selected-player count → team count + sizes, with special-case rules (N=8 → [4,4] instead of [2,2,2,2]; N≥12 → T=4). Naive heuristics ("minimize team count" or "minimize team size") do NOT reproduce the table.

**Rule:** any game whose Team-mode spec defines a deterministic team-count + sizes table from player count MUST:
1. Implement the function as `randomDistribution(int N)` (or equivalent) in the provider returning `{int teamCount, List<int> sizes}`
2. Author a full-table non-UI test that iterates every N in the spec's table and asserts the returned (team count, sorted-sizes multiset) matches the spec row exactly
3. Author a UI test (in `integration_test/<game>/team_setup_test.dart` or equivalent) that for every N in the table: selects N players, taps TEE OFF in Random mode, then asserts the resulting team count + sorted sizes match the spec
4. Hard-code every special-case row explicitly in the algorithm (don't rely on a single heuristic to produce the table)

**How to apply:** Phase 3 prompt template adds a mandatory "Random Distribution Coverage" test group. AR-3 audit reads the spec table, counts rows, verifies the non-UI test file iterates all rows. AR-6 audit verifies the UI test file iterates all rows.

---

### 54. Shared TeamAssignmentDialog already exists — wire keys, don't reinvent
The Target Tag implementation of `TeamAssignmentDialog` at `lib/widgets/player_list_panel/team_assignment_dialog.dart` is already shared infrastructure for Team+Manual mode. The TeamPlayerListPanel widget calls into it directly via `_showTeamSelectionDialog`. Any new Team-mode game reuses this dialog wholesale — there's no game-specific TeamAssignmentDialog config factory required.

**Rule:** in Phase 4 menu screen, wire the dialog's keys through `TeamPlayerListPanel` parameters:
- `teamDialogContainerKey: [GAME_NAME_PASCAL]MenuKeys.teamDialogContainer`
- `teamDialogDropdownKey: (id) => [GAME_NAME_PASCAL]MenuKeys.teamDialogDropdown(id)`
- `teamDialogCancelKey: [GAME_NAME_PASCAL]MenuKeys.teamDialogCancel`

Add these three keys to `[GAME_NAME_PASCAL]MenuKeys` in `lib/constants/test_keys.dart`. Do NOT author a new dialog. Do NOT create a `TeamAssignmentDialogConfig.[gameName]()` factory method.

**How to apply:** Phase 4 prompt template under "Create config factory methods" already lists every shared widget config method — explicitly exclude `TeamAssignmentDialogConfig` from the list for Team-mode games (only the keys need to be added). AR-4 audit: verify the keys are wired correctly when `_isManualTeamMode == true`.

---

### 55. Invisible-placeholder pattern for "neighbor previews" of the current item
When a UI shows "neighbors of the current item" (e.g., Tiki Golf's previous/next hole previews on the gameplay screen, or any future game that previews adjacent pieces/positions/players), use invisible-but-width-preserving placeholders for slots without valid neighbors. This keeps the central item stationary as the user progresses through the list, instead of shifting horizontally when previews appear/disappear at the edges.

**Rule:** for any "current item ± N neighbors" UI:
```css
.item-preview { display: flex; align-items: center; flex-shrink: 0; }
.item-preview.outer { width: 140px; }
.item-preview.inner { width: 182px; }   /* +30% from outer per Tiki Golf precedent */
.item-preview.empty {
  visibility: hidden;                    /* preserves layout width but renders nothing */
}
```

Empty placeholders match the natural slot width (outer vs inner) so the row's flex distribution doesn't shift. Use `align-items: center` for vertical-center alignment of neighbors against the (larger) central item. Use `justify-content: space-between` for screen-spanning distribution.

**How to apply:** Phase 2 Stage B / Phase 4 game-screen prompt templates cite this pattern when the spec includes neighbor previews. AR-4 audit: read the game screen and verify empty-slot Container widths match valid-slot Container widths so the central item stays centered.

---

### 56. Menu option boxes: label-left + control-right on one row, vertically centered
Past games and the Tiki Golf v1 build laid out each settings-grid option box as a vertical `Column[Label, SizedBox(8), ControlRow]` with `minHeight: 110`. The user consistently asked for this to be redone as a one-row layout: label on the left, control on the right, vertically centered inside the box. The minHeight constraint also reads as too tall.

**Rule:** every option box in the menu screen settings grid renders as `Row(MainAxisAlignment.spaceBetween, crossAxisAlignment.center, [Label, Control])`. The outer box is a `Container(padding: 12h/8v)` with the box's background/border. Wrap the Row in `Center(child: ...)` so the content is vertically centered inside the box. DO NOT set a fixed `minHeight` — let the box size to its content. All boxes in a row will naturally share the same height via `IntrinsicHeight(Row(Expanded(box)...))` on the parent.

**Canonical pattern:**
```dart
Widget _buildSettingsBox({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(/*bg + border + radius*/),
    child: Center(child: child),  // vertically center label + control
  );
}
// Each box content:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [Text('Label', style: labelStyle), controlWidget],
)
```

For boxes with a conditional secondary control (e.g., team-count dropdown that only appears in a sub-mode), prefer to omit the secondary entirely (Rule §67) rather than nest it in the box.

**How to apply:** Phase 4 menu-screen sub-agent prompt template — add this as the canonical option-box layout. AR-4 audit greps: each `_buildXxxBox` method must contain `MainAxisAlignment.spaceBetween` AND `crossAxisAlignment: CrossAxisAlignment.center` somewhere in the Row, AND must NOT contain `minHeight:` in the SettingsBox wrapper.

---

### 57. Menu option label and control text should be within 2pt of each other
Tiki Golf v1 had labels at 14pt and toggle text at 14pt; after the polish iteration the user wanted labels at 22pt and toggle/dropdown text at 20pt — a 2pt hierarchy difference. Old versions with 6-8pt size differences between label and control read as inconsistent.

**Rule:** in the settings grid, option labels (e.g., "Game Mode", "Max Strokes", "Mulligan") and their controls' visible text (toggle segment text "SOLO"/"TEAM", dropdown selected value, toggle on/off labels) should be within 2pt of each other. Labels can be the slightly larger of the two for hierarchy.

**Recommended sizes for menu screens using display fonts (Boogaloo/Bangers/Rye):**
- Option label: 22pt
- Toggle segment text + dropdown text: 20pt
- Toggle on/off labels (OFF / ON): 20pt
- Inline subtitle (e.g., "1 do-over per player" in parens): 14pt Nunito (Rule §66)

For games using more neutral display fonts, use the same 22/20 split and tune visually.

**How to apply:** Phase 4 menu-screen sub-agent prompt template defaults to label 22 / control 20. AR-4 audit: every menu-screen option-box file should have label fontSize and control fontSize within 2pt of each other.

---

### 58. How-To-Play / left panel: top-align with the first option row (don't stretch full-height)
By default a `Row` with `crossAxisAlignment: stretch` (the default for many layouts) makes both columns fill the parent's height. The how-to-play panel on the left then stretches to canvas height, while the right panel's first option row starts at `y = padding-top`. The visible top of the green container ends up ABOVE the visible top of the first option box — visually jarring.

**Rule:** the menu's main-content Row uses `crossAxisAlignment: CrossAxisAlignment.start`, so the left panel doesn't auto-stretch. Wrap the left panel in `Padding(EdgeInsets.only(top: <right-panel-padding-top>, left: <small-left-inset>))` so the green container's top edge aligns with the first option box's top edge.

**Canonical pattern (Tiki Golf reference):**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start, // top-align both columns
  children: [
    SizedBox(
      width: constraints.maxWidth * 0.437,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16),
        child: _buildLeftPanel(),
      ),
    ),
    Expanded(child: _buildRightPanel(...)),
  ],
);
// _buildLeftPanel is a Container with EdgeInsets.all(16) padding so its
// content has the same equal top + bottom inset.
```

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies this. AR-4 audit: confirm `crossAxisAlignment: start` on the menu's main-content Row AND a Padding wrapper on the left panel sized to match the right panel's padding-top.

---

### 59. Horizontal gap between left and right panels — 8px sweet spot (16px is too generous)
Tiki Golf v1 used `EdgeInsets.all(16)` on the right panel, which combined with the left panel's right edge gave a visible 16px gap between the two panels. The user asked for that gap to be halved.

**Rule:** the right panel uses asymmetric padding `EdgeInsets.fromLTRB(8, 16, 16, 16)` (8px on the left side facing the left panel; 16px on the other three sides). This halves the inter-panel gap while preserving the visible right and bottom margins.

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies this for the right panel container. AR-4 audit: read the right panel's outer Container `padding` and confirm `fromLTRB(8, 16, 16, 16)` (or equivalent asymmetric with `left < right`).

---

### 60. Right-panel section gaps — 8px between sections (16px reads too airy)
Tiki Golf v1 had `SizedBox(height: 16)` between settings-grid ↔ player-panel and between player-panel ↔ TEE-OFF button. The user wanted these halved.

**Rule:** the vertical gaps between major sections inside the right panel (settings grid, player panel, primary button) default to **8px**. Use 16px only when there's a deliberate visual-break reason (e.g., separating ungrouped content categories).

**How to apply:** Phase 4 menu-screen sub-agent prompt template specifies `SizedBox(height: 8)` between sections. AR-4 audit: grep `SizedBox(height: 16)` in the menu screen — should appear only inside the left panel (between How-To-Play headers and body) if at all.

---

### 61. TeamPlayerListPanel header indent: use the `headerPadding` config, NEVER wrap the panel in Padding
The `TeamPlayerListPanel` widget returns `Expanded(child: Column(...))` when `useFixedHeight: false`. `Expanded` requires a **direct** Flex (Row/Column) parent — any intermediate widget (Padding, Container, Transform, Align) between Expanded and its Flex parent triggers `Incorrect use of ParentDataWidget` at runtime. This bit the Tiki Golf build twice during the polish iteration.

**Rule:** to indent the player panel's HEADER (the "Available Players" label + count chip + ADD PLAYER button) relative to the panel's list rows, use the shared widget's `headerPadding: EdgeInsetsGeometry?` config field. The widget wraps `_buildHeader`'s Row in a Padding only when the field is set. **DO NOT wrap `TeamPlayerListPanel` itself in any non-Flex widget** (Padding, Container with margin, Align, Transform, etc.) — it will break at runtime when `useFixedHeight: false`.

If you need to indent the entire panel (rows AND header), you have two options:
- Set `useFixedHeight: true` (returns Column, not Expanded — Padding wrapping then works) AND override the panel's `soloListHeight` / `teamListHeight` so the content fits in the available vertical space.
- OR change the menu screen's outer right-panel padding so the entire right-panel content shifts inward.

**Canonical pattern (Tiki Golf reference):**
```dart
// In <Game>PlayerListPanelConfig factory:
headerPadding: const EdgeInsets.symmetric(horizontal: 12),

// In the menu screen — DO NOT do this:
//   Padding(child: TeamPlayerListPanel(useFixedHeight: false, ...))  ← runtime crash
// Just pass the panel directly:
TeamPlayerListPanel(config: <Game>PlayerListPanelConfig.<game>(), useFixedHeight: scrollable, ...)
```

**How to apply:** AR-4 audit greps `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart` for `Padding` wrapping `TeamPlayerListPanel(`. Any such match is a runtime-crash risk — replace with `headerPadding` (header-only indent) or `useFixedHeight: true` (whole-panel indent via outer wrapper).

---

### 62. Suppress the "Team Assignment" label above team boxes when it's redundant
By default the shared `TeamPlayerListPanel` renders the `config.teamAssignmentLabel` text ("Assign Teams" or similar) above the team-assignment boxes in Manual mode. When the team-badge images themselves clearly communicate "these are the teams", the label is redundant and just adds vertical space.

**Rule:** the shared config has `showTeamAssignmentLabel: bool` (default true). Games where the team badges are self-explanatory should set it to `false`. When false, both the label AND its surrounding 16px/8px SizedBox spacers are skipped.

**How to apply:** Phase 4 menu-screen sub-agent prompt template includes the option. AR-4 audit: for any new game with team mode, surface to the user during build review: "should the 'Team Assignment' label above the team boxes be hidden?" — set `showTeamAssignmentLabel: false` if the user says yes.

---

### 63. Allow team-box chrome to be transparent for a clean badges-only look
The shared `TeamPlayerListPanel` wraps each team crest in a `Container` with `teamBoxBackgroundColor` + `teamBoxBorderColor` + `teamBoxActiveBorderColor`. These add visual chrome around each badge. For games where the crest images are detailed enough to stand on their own (e.g., circular crests with rope borders, full-bleed images), the Container chrome competes with the artwork.

**Rule:** set all three team-box color config fields to `Colors.transparent` to render the badges with no container chrome. The active-team visual cue can come from other places (a left-edge accent on the active team's parent row, a glow on the badge image via `BoxShadow` or `ImageFiltered`, or a 2px translucent border via a different config) — see Rule §49 for the canonical Teams-panel transparent treatment.

**Canonical pattern (Tiki Golf reference):**
```dart
teamBoxBackgroundColor: Colors.transparent,
teamBoxBorderColor: Colors.transparent,
teamBoxActiveBorderColor: Colors.transparent,
teamBoxSize: 84.0,   // can size larger when no chrome competes
```

**How to apply:** Phase 4 prompt template suggests this for games where the crests are visually self-sufficient. AR-4 audit: when reviewing the team-mode setup screen, the user should be asked "do the team-box backgrounds and borders feel necessary?" — if no, set all three to transparent.

---

### 64. Heavy-descender display fonts (Boogaloo, Bangers, etc.) need line-height tightening on home-card labels
Boogaloo, Bangers, and similar handwritten/casual display fonts have heavier descenders than the more uniform fonts used by other games (Fredoka, Luckiest Guy, Cinzel, etc.). On the home-screen game card, the label's baseline sits visually lower than peer-game labels — the descender pushes the rendered text down within its line box, even when the SizedBox spacer above is shrunk.

**Rule:** for games using Boogaloo, Bangers, Pirata One, or other heavy-descender display fonts on the home-screen card, apply BOTH of these tweaks to align the label baseline with peer games:
1. Reduce the SizedBox between the icon and the label (default 8px → 3px for Boogaloo, 6px for Pirata One)
2. Tighten the TextStyle line-height with `height: 0.6` (or similar < 1.0) to compress the line box and shift the rendered glyphs up

**Canonical pattern (Tiki Golf reference):**
```dart
// In the SizedBox conditional in home_screen.dart:
height: title == 'Tiki Golf' ? 3 : <peer-game-default>,
// In the TextStyle conditional:
GoogleFonts.boogaloo(
  fontSize: <size>,
  fontWeight: FontWeight.bold,
  color: ...,
  height: 0.6,   // tightens the line-box so text sits higher
),
```

**How to apply:** Phase 4 home-card sub-agent prompt template includes this tweak for any game whose Style section uses a heavy-descender font. AR-4 audit: open the home screen at full resolution and verify the game's label baseline visually aligns with at least 2 peer-game labels (or the user reports it does).

---

### 65. AppBar title size for branded display fonts — 28-34pt (default 20pt is too small)
Default Material AppBar `titleStyle` is ~20pt. For games that use a branded display font (Boogaloo, Bangers, Cinzel, Rye, Pirata One) for the AppBar title, 20pt reads as cramped and undersells the game's visual identity. The user consistently asked Tiki Golf's titles bumped from 20pt → 28pt → 34pt over multiple iterations.

**Rule:** for the AppBar title on EVERY new game's three screens (menu / game / results), use **28-34pt** when the spec uses a branded display font. Pick a size by font weight:
- Heavier display fonts (Bangers, Pirata One, Rye): 28pt
- Medium-weight display fonts (Boogaloo, Cinzel, Cinzel Decorative): 32-34pt
- Light/condensed display fonts (Fredoka, Orbitron): 24-28pt

**How to apply:** Phase 4 prompt template for menu/game/results screen authors specifies the AppBar title at 28-34pt by default. AR-4 audit: read the three AppBar titles and verify fontSize ≥ 24 when the font is a Google Fonts display font.

---

### 66. Inline parenthetical subtitle (RichText) instead of below-row subtitle
When an option box needs a one-line clarifying subtitle (e.g., "Mulligan" with "1 do-over per player"), the user prefers the subtitle inline next to the label as a smaller parenthetical, rather than on a separate row below the option's primary row. The inline pattern keeps the box height matching the other options' boxes.

**Rule:** for option boxes that need a clarifying subtitle, use `RichText` with two TextSpans:
- Primary label at the full option-label size (e.g., 22pt Boogaloo)
- Parenthetical subtitle at a smaller body-font size (e.g., 14pt Nunito with 0.75 opacity)

**Canonical pattern (Tiki Golf Mulligan box reference):**
```dart
Flexible(
  child: RichText(
    overflow: TextOverflow.visible,
    text: TextSpan(children: [
      TextSpan(
        text: 'Mulligan ',
        style: GoogleFonts.boogaloo(fontSize: 22, color: ..., shadows: ...),
      ),
      TextSpan(
        text: '(1 do-over per player)',
        style: GoogleFonts.nunito(fontSize: 14, color: ...withOpacity(0.75)),
      ),
    ]),
  ),
),
```

DO NOT use a separate Column[PrimaryRow, SizedBox, SubtitleText] — that makes the box taller than its peers in the same settings row.

**How to apply:** Phase 4 menu-screen sub-agent prompt template suggests this pattern when a spec includes per-option clarifying text. AR-4 audit: any option box with both a primary label and a clarifying subtitle should use RichText inline, not Column + Text below.

---

### 67. Inline secondary controls — consider removing them entirely if a sensible default exists
Tiki Golf v1 had a "Teams: [4 ▾]" inline dropdown inside the Game Mode option box, shown only in Team + Manual mode. The user removed it entirely, accepting a default of 4 teams. The control was visually noisy and added little value when the user can always manage team membership by which slots they fill.

**Rule:** for inline secondary controls that appear conditionally (only in a sub-mode) AND have a sensible default value AND can be worked around via other UI (e.g., the user picks team assignments which implicitly determines team count), surface to the user during build review: "is this secondary control needed, or should we default it and remove the UI?" Often the answer is "remove" — fewer controls = cleaner menu.

When removing: KEEP the underlying state variable in the screen (it's still used downstream by the provider/game) and DEFAULT it to a sensible value. Just remove the UI that exposed it.

**How to apply:** Phase 4 prompt template, when authoring an option box that has a conditional secondary control inside it, instructs the sub-agent to flag the secondary control as a removal candidate. AR-4 audit: when the user is reviewing the menu screen visually, ask if any conditional secondary controls feel necessary; remove them if the answer is no.

---

### 68. `SettingsHelpers.resetServerState` MUST disable voice via the API
Every UI test reset MUST issue `PUT /api/v1/settings/voice_enabled` with body `{"value": "false"}` after the `/api/v1/test/reset` and before returning. With voice enabled in tests, `_handleGameWon()`'s `_audioQueue.whenIdle()` chain blocks indefinitely under heavy load — headless flutter_drive + DDC TTS engine's `setCompletionHandler` doesn't fire reliably, so each queued announcement falls back to its `wordCount * 1000 + 1500` ms timeout. Longer games (tiki golf 9 holes, gladiator knockoffs, monster mash multi-monster) accumulate enough mid-game announcements that the audio queue takes 60–200+ seconds to drain after victory, exceeding the `pumpUntilResults` budget so the results screen never renders. With voice off, `DartAnnouncerService.speak()` short-circuits, the queue stays empty, `whenIdle` resolves synchronously, and navigation fires. Game logic (provider state, scoring, `hasWinner`) is unaffected; only the per-test reset changes.

Insert this block immediately after the dartboard-configuration PUT in `resetServerState`:
```dart
final voiceResponse = await http.put(
  Uri.parse(ApiConfig.url('/api/v1/settings/voice_enabled')),
  headers: dartboardHeaders,
  body: jsonEncode({'value': 'false'}),
);
if (voiceResponse.statusCode != 200) {
  print('WARNING: Failed to disable voice for test '
      '(status ${voiceResponse.statusCode}): ${voiceResponse.body}');
}
```
Mirror to both `integration_test/shared/settings_helpers.dart` AND `test/shared/settings_helpers.dart` per Rule 26 (byte-identical sync).

**How to apply:** Phase 6/7 setup. AR-4 item (rr).

---

### 69. `ResultsHelpers.pumpUntilResults(tester, config)` is the canonical post-victory wait — fixed pumps are forbidden in this position
After a victory-causing input (`completeGameToVictory`, `clickDartsRemoved` on a winning turn, `EditScoreHelpers.editScoreAndSave` that creates a winner), tests that assert on any results-screen widget — Play Again button, winner name, headline text, edit-score button, music init, stats, or any `_results_*` key — MUST wait with:
```dart
await ResultsHelpers.pumpUntilResults(tester, config);
```
Fixed `tester.pump(const Duration(seconds: 4))` chains are FORBIDDEN here. Victory navigation is now event-driven on `_audioQueue.whenIdle()` + 250 ms (per AR-4 item ii-c and Rule 68) — wall-clock latency is unbounded and any fixed budget races the navigation under parallel-runner load. `pumpUntilResults` polls with `pump(Duration(milliseconds: 300))` for up to 300 iterations (90 s wall-clock max), breaking early when the Play Again button mounts.

Screenshot / showcase tests inline the equivalent loop instead (see § 71).

**Allowed exception:** the per-turn skip-turn-with-darts-thrown wait described elsewhere in this skill (`pump(seconds: 4)` after `clickSkipTurn` to let the 3500 ms `simulateTakeoutStarted` schedule fire) is unrelated to results navigation and stays as-is.

**How to apply:** Phase 7. AR-4 item (ss).

---

### 70. `VictoryMusicService` / stats assertions need an explicit 5 s settle AFTER `pumpUntilResults`
`pumpUntilResults` exits the moment the Play Again button mounts. `VictoryMusicService.initialize()` (HTTP GET `/api/v1/music`) and `_updatePlayerStats()` (HTTP POST `/api/v1/players/.../stats/batch`) run async AFTER that mount. The helper's 1 s tail settle isn't enough under heavy parallel load. Every test that asserts `VictoryMusicService().isInitialized == true`, `player.gamesPlayed`, `player.gamesWon`, or `player.gameHistory` MUST insert this block between `pumpUntilResults` and the assertion:
```dart
await ResultsHelpers.pumpUntilResults(tester, config);
// VictoryMusicService.initialize() + _updatePlayerStats() API call run async
// AFTER the Play Again button mounts; pumpUntilResults only settles ~1s
// post-button, which isn't enough under heavy parallel load.
await tester.pump(const Duration(seconds: 5));
await tester.pump();
await tester.pump();

expect(VictoryMusicService().isInitialized, isTrue);
// ... and / or stats assertions
```

**How to apply:** Phase 7. AR-4 item (tt).

---

### 71. Screenshot / showcase tests use an inline 300-iteration poll loop, not a fixed pump
Screenshot and showcase tests inline all helpers (no `_helpers.dart` import — pre-existing rule). When such a test waits for the results screen between captures or before a results-screen assertion, it MUST use this inline polling loop (300 iterations × 300 ms = 90 s budget, breaks on first hit):
```dart
// Robust wait: poll until the results screen has rendered, instead of a
// fixed pump that races the event-driven victory navigation under load.
for (int _i = 0; _i < 300; _i++) {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  if (<results play-again finder>.evaluate().isNotEmpty) break;
}
await tester.pump(const Duration(seconds: 1));
await tester.pump();
```
The break finder is game-specific: `ElementFinders.get[Game]PlayAgainButton()` if `element_finders.dart` is already imported, otherwise `find.byKey([Game]ResultsKeys.playAgainButton)`. Fixed `tester.pump(const Duration(seconds: 4))` chains are forbidden in this position for the same reason as Rule 69.

**How to apply:** Phase 8 visual validation. AR-4 item (uu).

---

### 72. `mounted` guard after every `await playerProvider.<method>()` in `State` code
`PlayerProvider`'s async methods (`loadPlayers`, `savePlayer`, `deletePlayer`, `batchUpdatePlayerStats`, etc.) are HTTP roundtrips. The widget tree may be disposed during the gap — user backs out, dartboard disconnect grabs nav focus, integration-test teardown ends the test. Calling any method on the provider after that disposal — `selectPlayer`, `clearSelection`, anything that triggers `notifyListeners` — fires the `"ChangeNotifier was used after being disposed"` assertion. Every `State<T>` class that awaits a `PlayerProvider` method MUST have `if (!mounted) return;` between the await and the next line that touches the provider, `setState`, or `context`.

Pattern:
```dart
await playerProvider.loadPlayers();
// HTTP roundtrip just resolved; widget may have unmounted in the gap.
if (!mounted) return;
playerProvider.clearSelection();   // safe now
```

Equally applies to `savePlayer` followed by `selectPlayer` (in `_handleAddPlayer` of `team_player_list_panel.dart` / `dual_player_list_panel.dart`) and to `savePlayer` followed by `_scrollToNewPlayer()` (in `options_screen.dart`'s add-player flow).

**Exception:** `batchUpdatePlayerStats` calls inside a `try`/`catch` that do NOT touch the provider, `setState`, or `context` after the await (the standard results-screen `_updatePlayerStats` body) are already safe.

**How to apply:** Phases 4 and 5. AR-4 items (oo) extended + (vv).

---

### 73. Real-time pumps (`pump(Duration(milliseconds: N))`) for popup / overlay animations
`tester.pump()` (no Duration argument) advances the test clock by ONE frame and does NOT wait wall-clock time. `tester.pump(const Duration(milliseconds: N))` waits real wall-clock time on `LiveTestWidgetsFlutterBinding` (which integration tests use), allowing real timers — animation controllers, fade transitions, popup overlays, Material's `Tooltip`/`PopupMenuButton`/`DropdownButton` show/hide animations — to fire. Tests that interact with popups, dropdowns, dismissal overlays, modal show/hide, or any animated transition MUST use:
```dart
await tester.tap(<popup-affecting finder>);
await tester.pump(const Duration(milliseconds: 200));
await tester.pump();
```
between the gesture and the next gesture. Bare `pump(); pump();` chains (including `PumpSequences.simpleUpdate`) are forbidden in this position. Reference: `integration_test/home_screen/filter_bar/filter_no_match_test.dart` for the canonical pattern. Surface: was caught when `filter_multi_criterion_and_test.dart` started failing after a stabilization commit that had only added a second bare pump — the second bare pump didn't help because both pumps were synthetic.

**How to apply:** Phase 7. AR-4 item (ww).

---

### 74. Don't assert "intermediate state not yet loaded" — assert the final state
Pre-Rule-68, the `_handleGameWon` `Future.delayed(3 s)` gave tests a free "results screen not yet loaded" window. With voice disabled in tests (Rule 68), navigation now lands ~immediately because `_audioQueue.whenIdle()` resolves synchronously. Tests written against the old timing — typically asserting `gamesPlayed == 0` with reason `"results screen not yet loaded"` — break under the new timing because the results screen and stats persistence ARE done by the time the assertion runs.

Don't write intermediate-state checks at all. Wait for the final state with `pumpUntilResults` (Rule 69) + 5 s settle (Rule 70), and assert the final values — typically `gamesPlayed == 1`, plus winner-specific (`gamesWon == 1`) and loser-specific (`gamesWon == 0`) checks. Tests with docstring claims like "stats reflect the edited outcome" should verify the actual final stats, not the intermediate "not loaded yet" state.

Reference fix: `tiki_golf/edit_score/edit_removes_winner_no_stats_test.dart` post-commit `6142923`.

**How to apply:** Phase 7. AR-4 item (xx).

---
