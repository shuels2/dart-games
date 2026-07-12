# Treasure Divide - Implementation Notes

## Code Architecture

### Provider Pattern

**File:** `lib/providers/treasure_divide_provider.dart`

**State Management:**
- All game state is owned by `TreasureDivideProvider` (ChangeNotifier)
- `TreasureDivideGame` (immutable value object) holds the serializable game state
- Provider exposes computed getters (`currentTarget`, `activePlayerTreasure`, `hasWinner`, `dartsThisTurn`, `shouldPromptTakeout`, etc.) that the UI reads directly
- `processDartThrow()` is the single entry point for all dart input — handles scoring, turn advancement, round progression, and halving

**Key Methods:**
- `startGame(players, settings)` — initializes `TreasureDivideGame`, assigns pirate themes, derives crew layout (random) or uses user assignments (manual), stores saved-game context
- `processDartThrow(dart)` — records dart, checks target hit/miss, advances turn or round when full dart budget is reached
- `skipTurn()` — forfeits remaining darts; treats as miss-all if no hits recorded in current turn
- `advanceToNextPlayer()` — Solo: sequential; Team: crew-grouped rotation (P1→P2 within crew, then next crew)
- `editScore(playerId, roundIndex, newDarts)` — replays the round with new dart values; re-evaluates halving for that round
- `saveGame()` — persists current game state via `SaveGameService`
- `restoreGame(savedGameId)` — loads game state and sets `resumedSavedGameId`

### Models

**File:** `lib/models/treasure_divide_game.dart`

**Data Structure (mirrors Tiki Golf's field set):**
```dart
class TreasureDivideGame {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;

  // Game options
  final int totalRounds;          // 7, 9, or 12
  final bool quarterItEnabled;
  final bool customTargetsEnabled;
  final GameMode gameMode;        // solo / team
  final TeamAssignment teamAssignment;  // random / manual
  final int teamCount;            // 2-5 (Manual mode only)

  // Target sequence — ints for number rounds, sentinel constants for special rounds
  final List<int> targetSequence;

  // Per-player per-round hauls: Map<playerId, List<int?>>
  // Length == totalRounds; null = not yet thrown
  final Map<String, List<int?>> playerRoundScores;

  // Team fields (mirrors TikiGolfGame)
  final String? gameMode;         // 'solo' | 'team'
  final List<String> teamCrestPaths;
  final Map<String, String> playerTeamAssignments;  // playerId → teamId
  final Map<String, List<String>> teamPlayers;      // teamId → [playerId]
  final String? activeTeamId;
  final Map<String, int> teamWithinRoundRotationPointer;  // teamId → member index
  final int currentTeamIndex;
  final String? winnerTeamId;
  final List<String>? winnerTeamIds;

  // Pirate theme assignment
  final Map<String, int> playerPirateThemes;  // playerId → themeIndex 0..7

  // Game progress
  final int currentRound;
  final int currentPlayerIndex;
  final String? winnerId;
  final List<String>? winnerIds;
}
```

**Key Responsibilities:**
- `totalForPlayer(playerId)` — folds over `playerRoundScores` in order: add haul on hit-round, apply `floor(x/2)` or `floor(x/4)` on miss-round. Path-dependent because halving is applied to the RUNNING total.
- `totalForTeam(teamId)` — same fold, but sums all members' hauls per round and applies crew-wide halving only when the sum is 0 (whole crew missed all darts)

### Sentinel Target Constants

**File:** `lib/models/treasure_divide_game.dart` (or a constants file)

```dart
const int kTargetAnyDouble = -1;
const int kTargetAnyTriple = -2;
const int kTargetBull = -3;
```

These negative values are guaranteed never to appear as valid dartboard target numbers (1–20) and serve as in-band markers in the `targetSequence` list. Hit detection logic branches on these constants:
- `kTargetAnyDouble` — dart must be a double segment (`multiplier == 2`)
- `kTargetAnyTriple` — dart must be a triple segment (`multiplier == 3`)
- `kTargetBull` — dart must be outer bull (25) or inner bull (50)

### `randomDistribution(int n)` Algorithm

**Purpose:** Compute crew count and sizes for Team + Random assignment.

```dart
// n in 3..10
List<int> randomDistribution(int n) {
  final pairs = n ~/ 2;
  final hasOdd = (n % 2 == 1);
  return List.filled(pairs, 2) + (hasOdd ? [1] : []);
}
// Returns: crew sizes (e.g., n=7 → [2,2,2,1])
// Crew count = sizes.length
```

After calling this, the provider shuffles `selectedPlayerIds` and deals them sequentially into crews of the derived sizes. The 1-player crew (if present) is always the last crew after the deal.

### Solo Crew 6-Dart Rule — Mechanism

**Provider getter:**
```dart
int get dartsThisTurn {
  if (!isTeamMode) return 3;
  final activeTeam = teamPlayers[activeTeamId] ?? [];
  return activeTeam.length == 1 ? 6 : 3;
}
```

The `processDartThrow()` handler:
1. Appends the dart to `playerRoundScores[currentPlayerId][currentRound]`
2. Checks if darts recorded == `dartsThisTurn`
3. If not: stays on the same player (does NOT advance the within-crew rotation pointer)
4. If yes: evaluates hit/miss for the round, then calls `advanceToNextPlayer()`

The `playerRoundScores[playerId][roundIndex]` list for a solo crew stores 6 entries (instead of 3 for paired crew members) to preserve the per-dart breakdown.

### `_isManualTeamMode` Flag

**In menu screen state:**
```dart
bool get _isManualTeamMode => _isTeamMode && _isManualTeamAssignment;
```

This gate is used identically to Tiki Golf / Target Tag:
- Crew-assignment boxes visible ↔ `_isManualTeamMode`
- Per-player team-assign trailing icons visible ↔ `_isManualTeamMode`
- Inline Crews (Team Count) dropdown visible in Game Mode box ↔ `_isManualTeamMode`

When `_isManualTeamMode == false` (either Solo mode OR Team + Random), the panel looks identical to Solo — no crew UI rendered.

### Save/Restore Details

**resumedSavedGameId tracking:**
- When SET SAIL is tapped with an existing save for the current configuration, the provider clears the old save immediately (auto-replace)
- When `restoreGame(savedGameId)` is called, the provider sets `resumedSavedGameId = savedGameId`
- On game completion (results screen `initState`), the provider calls `saveGame.delete(resumedSavedGameId)` if non-null — auto-delete on results screen load

**Auto-delete on results screen:**
The results screen `initState` calls `provider.onGameCompleted()`, which:
1. Calls `updatePlayerStats()` for all players
2. Calls `_playVictoryMusic()`
3. Deletes the resume save if `resumedSavedGameId != null`

## Pirate Theme Overlay System (Section 3C)

### Architecture Overview

The Pirate Theme Overlay System adds two cross-cutting capabilities: **face landmark detection** (server-side, one-time per avatar) and **themed avatar rendering** (client-side, every render).

### mediapipe Python Sidecar Architecture

**Python script:** `server/python/detect_face.py`
- Reads an image path from `argv[1]`
- Runs `mediapipe.solutions.face_detection` (and/or `face_mesh` for nose/mouth landmarks)
- Prints landmark JSON to stdout, exits 0 on success
- Exits non-zero (and prints nothing or an error) on failure / no face detected

**Dart wrapper:** `server/lib/services/face_landmark_service.dart`
- Exposes `Future<FaceLandmarks?> detect(File image)`
- Spawns Python: `Process.run('python', ['python/detect_face.py', imagePath])`
  - **Python discovery order:** tries `python` → `python3` (system may vary; the implementation handles both)
- Parses JSON output into `FaceLandmarks` model
- Returns `null` if Python exits non-zero, stdout is empty, confidence < 0.5, or subprocess times out (>10s)
- Never throws — failures are silently returned as `null` so the avatar upload always succeeds

**Wiring:** the existing avatar-upload route (`PUT /players/:id/photo`) is extended:
1. Save the image file as before
2. Await `faceLandmarkService.detect(savedFile)` — this may take a few hundred milliseconds
3. If landmarks returned: update `Player.faceLandmarks` column in the database
4. If null: leave `face_landmarks = NULL` in the database (graceful degradation)
5. Return 200 to the client either way — landmark detection failure never blocks an upload

### Face Landmarks Data Model

**Server column:** `face_landmarks TEXT` (nullable JSON blob) on the `players` table, added by Migration V5.

**JSON schema:**
```json
{
  "boundingBox": {"x": 0.18, "y": 0.12, "width": 0.64, "height": 0.72},
  "leftEye":     {"x": 0.34, "y": 0.40},
  "rightEye":    {"x": 0.66, "y": 0.40},
  "noseTip":     {"x": 0.50, "y": 0.55},
  "mouthCenter": {"x": 0.50, "y": 0.72},
  "confidence":  0.97
}
```

All coordinates are normalized 0..1 relative to the avatar image dimensions, so they survive resizing.

**Derived anchors (computed client-side by `PirateAvatarWidget`):**
- `headTop` = `(boundingBox.x + boundingBox.width/2, boundingBox.y - boundingBox.height * 0.15)` — 15% above the top of the bounding box
- `chin` = `(boundingBox.x + boundingBox.width/2, boundingBox.y + boundingBox.height)`
- `leftEar` / `rightEar` = mid-height edges of the bounding box
- `faceScale` = `boundingBox.width` — used to size sprites relative to face width

**Heuristic fallback (when `faceLandmarks == null`):**
- `headTop` = `(0.5, 0.05)` — top-center of the avatar box
- `leftEye` = `(0.40, 0.40)`; `rightEye` = `(0.60, 0.40)`
- `noseTip` = `(0.5, 0.55)`; `chin` = `(0.5, 0.75)`
- `faceScale` = `0.6` — 60% of avatar width as a reasonable face-width estimate

### PirateAvatarWidget Heuristic Fallback

`PirateAvatarWidget` checks `PlayerProvider.isDefaultAvatar(playerId)` as a secondary signal. If the avatar is the default silhouette (no photo), the heuristic anchors are used regardless of the `faceLandmarks` field (which is likely null for default avatars anyway). This ensures every player has a pirate effect — even those who haven't uploaded a photo.

### kThemeAccessoryAnchors Map

**File:** `lib/widgets/treasure_divide/pirate_themes.dart`

```dart
const List<PirateTheme> kPirateThemes = [
  PirateTheme(name: 'Captain', accessories: [
    PirateAccessory('assets/games/treasure_divide/themes/captain/hat.png',
        anchor: AnchorPoint.headTop, widthFactor: 1.6),
    PirateAccessory('assets/games/treasure_divide/themes/captain/eyepatch.png',
        anchor: AnchorPoint.leftEye, widthFactor: 0.4),
    PirateAccessory('assets/games/treasure_divide/themes/captain/parrot.png',
        anchor: AnchorPoint.frameUpperRight, widthFactor: 0.35),
  ]),
  // Themes 1..7 follow the same pattern
];
```

The `AnchorPoint` enum covers: `headTop`, `leftEye`, `rightEye`, `noseTip`, `chin`, `leftEar`, `rightEar`, `frameUpperLeft`, `frameUpperRight`, `frameLowerLeft`, `frameLowerRight`.

### mediapipe Server Stack Details

**Migration V5** (`add_face_landmarks`):
- Adds `face_landmarks TEXT` column (nullable) to the `players` table
- Idempotent: safe to re-apply (migration runner skips already-applied versions)
- All existing player rows have `face_landmarks = NULL` after migration

**Python deps:** `server/python/requirements.txt`
```
mediapipe==0.10.x
opencv-python==4.x.x
```

**CLI migrator:** `server/bin/migrate_face_landmarks.dart`
- Scans `players` table for rows where `face_landmarks IS NULL AND avatar_path IS NOT NULL AND avatar_path != <default>`
- Runs `faceLandmarkService.detect(...)` on each
- Writes results back; skips rows that already have landmarks (idempotent)
- Logs: `Processed N/M players (K successes, L detection-failures)`

**Python dependency check scripts:**
- `check_python_deps.bat` (project root) — verifies Python + mediapipe importable; auto-installs from `requirements.txt` on miss; exits 0/1/2; never blocks
- Wired into: `run_app.bat`, `start_server.bat`, `run_ui_tests.bat`, `run_ui_tests_parallel.bat` (the last behind its existing `STUB_MODE` gate)
- Non-blocking everywhere: if Python is missing, a WARNING is printed and execution continues; Treasure Divide's avatar overlays fall back to heuristic placement; all other games are unaffected

## Product Bugs Found and Fixed During Build

10 bugs were discovered and fixed during Phases 1–7:

1. **Nested Expanded in flex context** — `Expanded` widget inside an `Expanded` parent caused a layout exception; resolved by using `Flexible` or removing the inner `Expanded`
2. **Naked Column in Stack** — placing a bare `Column` (without `Positioned`) inside the outer `Stack` caused unbounded height; fixed by wrapping in `Positioned.fill` or `Expanded` in the appropriate flex ancestor
3. **`hasWinner` re-check after navigation** — results screen was calling `hasWinner` after `provider.endGame()` cleared state; fixed by caching the winner information before calling `endGame()`
4. **`TreasureMapWidget` lower-clamp** — island position calculation allowed negative Y coordinates (islands rendered above the map); clamped to `max(0.0, computedY)`
5. **Menu toggle Row overflow** — the Game Mode + Team Assignment toggles Row was overflowing at narrow widths; fixed by using `Flexible` wrappers inside the Row
6. **Opponent tile `expand()`** — calling `.expand()` on a non-expandable widget in the player strip tile; replaced with `Expanded` correctly placed inside the Column
7. **Team-mode `currentPlayerId` mismatch** — provider's `currentPlayerId` getter was returning the wrong player index in Team mode; fixed by using `teamPlayers[activeTeamId][withinRoundPointer]` directly
8. **`MockScoliaApiService` payload** — the mock service was sending incorrect JSON payload for face landmarks; fixed by aligning the mock with the actual server model schema
9. **`TreasureDivideStrategy.shouldAutoTakeout`** — the Play to Complete strategy was not correctly delegating to `provider.shouldPromptTakeout`; fixed by returning `context.read<TreasureDivideProvider>().shouldPromptTakeout`
10. **`_handleGameWon` null-safety** — `winnerName` was accessed before null-checking the winner; added `if (provider.winnerId == null) return;` guard before announcement

## Performance Considerations

### PirateAvatarWidget Render Cost

Each `PirateAvatarWidget` composites 2–3 accessory sprites over the player's avatar using `CustomPainter`. At 80×80 or smaller sizes (compact strip tiles), this is negligible. At 120×120 (results screen winner), watch for jank if many widgets rebuild simultaneously.

**Mitigation:** The `playerPirateThemes` map is stable within a game (set at SET SAIL, never changes). `PirateAvatarWidget` can use `RepaintBoundary` to isolate its repaint from parent rebuilds.

### Python Subprocess Latency

`faceLandmarkService.detect()` runs a Python subprocess that may take 500ms–2s depending on image size and machine speed. This runs on the server during avatar upload — the client does not wait for it; the upload response returns immediately after the image file is saved.

## Integration Points

### Global User Management

- `PlayerProvider.updatePlayerStats()` called from results screen `initState`
- Solo: `won: true` for the single winner (or all tied winners)
- Team: `won: true` for every player on the winning crew (Target Tag pattern); `won: false` for all others
- `gameHistory` entry records game name "Treasure Divide", final score, duration

### Announcer System

- `TreasureDivideAnnouncementHelper` wraps `GameAnnouncementQueueService`
- All announcements routed through the helper — never call `GameAnnouncementQueueService` directly from the screen
- `dispose()` on the helper must be called in the screen's `dispose()` to release resources

### Victory Music

- `_playVictoryMusic()` called from results screen `initState`
- `VictoryMusicService().initialize()` must be called before `getRandomMusicSource()` — the initialize call is part of `_playVictoryMusic()`
- UI test verifies `VictoryMusicService().isInitialized == true` after results screen loads

### Dartboard Emulator

- `DartboardEmulatorSection` placed as `Positioned(bottom: 0, left: 0, right: 0)` in the outer Stack (NOT inside Scaffold.body)
- `DartboardFABConfig.treasureDivide()` used for the toggle FAB
- `shouldPromptTakeout` drives the disabled overlay on the emulator section

## Data Persistence

### Game State

- Serialized as JSON and stored on the server via `SaveGameService`
- All fields in `TreasureDivideGame` must be JSON-serializable
- `playerRoundScores` stores `List<int?>` per player per round (null = not yet thrown); the serialization must preserve the distinction between null (not thrown) and 0 (thrown, missed all darts)

### Player Stats

- Games played, games won, game duration tracked via `PlayerProvider`
- Team mode: every winning-crew player gets `gamesWon++`; no crew-level stat is stored

## Known Issues and Limitations

### Python Dependency on Windows PATH

The face landmark detection requires `python` (or `python3`) to be on the system PATH. On Windows, some Python installs add only `py.exe` to PATH; the `check_python_deps.bat` helper verifies this and warns if Python is not found. The game runs correctly without Python — avatar overlays simply use heuristic placement.

### Theme Sprite Load Time

On first game load, all accessory sprites for all 8 themes are not pre-loaded. The first render of each sprite may show a brief frame without the sprite. This can be mitigated by precaching sprites in `initState` using `precacheImage()`.

## Development Tips

### Adding a New Announcement

1. Add a method to `TreasureDivideAnnouncementHelper`
2. Call it from the game screen in the appropriate event handler
3. Add a test in `treasure_divide_announcement_test.dart`
4. Add coverage in `treasure_divide_game_with_announcements_test.dart`

### Adding a New Pirate Theme

1. Add sprite assets to `assets/games/treasure_divide/themes/<theme_name>/` (transparent PNGs)
2. Add a `PirateTheme` entry to `kPirateThemes` in `pirate_themes.dart`
3. Update `playerPirateThemes` shuffle range (currently 0..7 for 8 themes)
4. Add `PirateAvatarWidget` test cases for the new theme's sprite count

### Modifying the Random Distribution

`randomDistribution(N)` is tested exhaustively for all N in 3..10. If the distribution table changes, update:
1. The function in `treasure_divide_provider.dart`
2. The expected values in `treasure_divide_provider_game_test.dart` (full-table provider test)
3. The spec table in Section 5 of `docs/research/games/tier2/treasure-divide.md`
