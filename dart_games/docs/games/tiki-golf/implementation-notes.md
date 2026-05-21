# Tiki Golf - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/tiki_golf_provider.dart`

**State Management:**
- `TikiGolfGame? game` — The active game model (null before `startGame()`)
- `bool hasWinner` — True after all 9 holes are completed and winner is determined
- `bool currentTurnEnded` — True when a turn-end condition is met (hit, all-missed, skip); resets to false after `confirmTurnEnd()`. This is the KEY difference from all other games.
- `Map<String, bool> playerMulliganAvailable` — Per-player mulligan availability (true at game start for each player when Mulligan ON)
- `Map<String, bool> playerMulliganUsedThisGame` — Per-player usage tracking (false at start, set to true after `useMulligan()`)

**Key Methods:**
- `startGame({required List<String> playerIds, required TikiGolfGameOptions options})` — Initializes game, runs both random shuffles (`holeTargets`, `holeImagePaths`), initializes mulligan maps when enabled
- `processDartThrow(DartThrow dartThrow)` — Handles a dart throw; checks target hit; sets `currentTurnEnded = true` on turn-end conditions; increments `totalTurns` on first dart
- `useMulligan(String playerId)` — Clears hole score, marks mulligan used, resets `dartsThrown[playerId] = 0`, clears `currentTurnEnded`
- `confirmTurnEnd(String playerId)` — Records score as final, resets dart tracking, advances to next player via `advanceToNextPlayer()`
- `advanceToNextPlayer()` — Moves the active player cursor; handles both Solo sequential and Team grouped-then-handoff rotation
- `skipTurn()` — Records Splash for current player, sets `currentTurnEnded = true`
- `editScore(String playerId, int holeIndex, int newStrokeCount)` — Overrides a hole score; re-evaluates win condition and mulligan eligibility

### Models
**File:** `lib/models/tiki_golf_game.dart`

**Data Structure:**
```dart
class TikiGolfGame {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;
  final List<int> holeTargets;          // Length 9, randomized at game start
  final List<String> holeImagePaths;    // Length 9, randomized at game start
  final Map<String, List<int?>> playerHoleScores; // playerId → [hole1, hole2, ... hole9]
  final Map<String, int> dartsThrown;   // Per-player current-turn dart count
  final Map<String, bool> currentTurnEnded; // Per-player turn-end flag
  final Map<String, bool> playerMulliganAvailable;
  final Map<String, bool> playerMulliganUsedThisGame;
  final int currentHole;                // 1-9
  final int currentPlayerIndex;         // Index into turn order
  final int maxDarts;                   // 3, 4, 5, or 6
  final bool mulliganEnabled;
  final bool isTeamMode;
  // Team mode fields:
  final List<List<String>> teams;       // teams[teamIndex] = list of playerIds
  final List<String> teamCrestPaths;    // teams[teamIndex] = crest asset path
  final String? winnerPlayerId;         // Solo winner (nullable)
  final String? winnerTeamId;           // Team winner (nullable)
}
```

**Key Responsibilities:**
- Stores immutable post-shuffle lists (`holeTargets`, `holeImagePaths`) that define the course
- Serializes all per-player maps for save/resume
- Provides hole target lookup: `holeTargets[currentHole - 1]`
- Provides hole image lookup: `holeImagePaths[currentHole - 1]`

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/tiki_golf/tiki_golf_menu_screen.dart`

The menu uses a 2×2 settings grid (per spec Section 7). Key interactions:
- **Game Mode toggle** — `Solo` | `Team`. Drives `isTeamMode` flag passed to `TeamPlayerListPanel`. When TEAM is selected AND Team Assignment = MANUAL, the inline Team Count dropdown (2/3/4) appears in the Game Mode box.
- **Team Assignment toggle** — `Manual` | `Random`. ONLY interactive when Game Mode = TEAM (50% opacity + `AbsorbPointer` in Solo mode). Drives `isManualTeamAssignment` flag. In Random mode, the Team Count dropdown is hidden — team count is auto-derived at game start.
- **Max Darts dropdown** — 3/4/5/6, default 3.
- **Mulligan toggle** — ON/OFF, default OFF.
- **TeamPlayerListPanel** — Same widget in all modes; `isTeamMode` and `isManualTeamAssignment` flags gate the team UI sub-elements.

**Max-players cap:** Solo mode caps at 4; Team mode caps at 16. The `TeamPlayerListPanel` receives both a `maxPlayersSoloMode: 4` and `maxPlayers: 16` parameter added during Tiki Golf's Phase 4. The widget uses the appropriate cap based on `isTeamMode`.

#### Game Screen
**File:** `lib/screens/games/tiki_golf/tiki_golf_game_screen.dart`

**Critical wiring — `shouldPromptTakeout`:**
```dart
// Tiki Golf: turn ends on target hit OR all darts missed OR skip — NOT after fixed N darts
final shouldPromptTakeout = provider.currentTurnEnded || provider.hasWinner;
```
This is the single most important implementation deviation from the canonical pattern. All other games use `dartsThrown >= 3 || hasWinner`. Tiki Golf MUST NOT use that pattern.

**Mulligan modal variant wiring:**
```dart
// In the RemoveDartsModal or equivalent:
final game = provider.game!;
final showMulliganVariant = provider.currentTurnEnded &&
    provider.lastTurnWasSplash &&
    game.mulliganEnabled &&
    (provider.playerMulliganAvailable[currentPlayerId] ?? false);

if (showMulliganVariant) {
  // Show USE MULLIGAN + NEXT PLAYER buttons
} else {
  // Show standard DARTS REMOVED button
}
```

**Dart row (variable slots):**
The dart indicator row renders `game.maxDarts` slots (3-6). Each slot shows hit/miss/empty state. The row is responsive — slot dimensions compress at 5-6 darts.

#### Results Screen
**File:** `lib/screens/games/tiki_golf/tiki_golf_results_screen.dart`

Solo mode: shows Golden Tiki trophy (`GoldenTiki.png`) and "GOLDEN TIKI CHAMPION!" headline.
Team mode: shows winning team's crest at 120×120, team name, and lists all team members as "Tiki Champions."

**Exit navigation:** Uses `Navigator.popUntil(context, (route) => route.isFirst)` — NOT `pushNamedAndRemoveUntil('/')`. The navigation tests enforce this.

## Complex Algorithms

### Per-Game Randomization
**Purpose:** Ensure no two rounds play the same course.

**Implementation at `startGame()` time:**
```dart
// 1. Pick 9 distinct numbers from 1-20 (no duplicates)
final allNumbers = List.generate(20, (i) => i + 1); // [1..20]
allNumbers.shuffle(Random());
final holeTargets = allNumbers.sublist(0, 9); // First 9 after shuffle

// 2. Shuffle 9 hole-theme image paths
final holeImagePaths = [
  'assets/games/tiki_golf/pieces/Volcano.png',
  'assets/games/tiki_golf/pieces/Waterfall.png',
  'assets/games/tiki_golf/pieces/TikiStatue.png',
  'assets/games/tiki_golf/pieces/PalmTree.png',
  'assets/games/tiki_golf/pieces/Lagoon.png',
  'assets/games/tiki_golf/pieces/Shipwreck.png',
  'assets/games/tiki_golf/pieces/BambooTemple.png',
  'assets/games/tiki_golf/pieces/CoralReef.png',
  'assets/games/tiki_golf/pieces/SunsetPier.png',
]..shuffle(Random());
```

Both lists are stored on the `TikiGolfGame` model and serialized to JSON for save/resume.

**Reference pattern:** Reef Royale's `List<X>..shuffle(Random())` at game-construction time (`lib/models/reef_royale_game.dart:208-213`).

### Variable-Dart Turn-End Logic
**Purpose:** Detect turn end at the correct moment (hit OR all darts exhausted) without relying on a fixed dart count.

**Implementation in `processDartThrow()`:**
```dart
// Increment dart count
final newDartsThrown = (game.dartsThrown[playerId] ?? 0) + 1;

// Increment totalTurns on dart 1 only (canonical rule — unchanged)
if (newDartsThrown == 1) {
  totalTurns[playerId] = (game.totalTurns[playerId] ?? 0) + 1;
}

// Check for target hit
final currentTarget = game.holeTargets[game.currentHole - 1];
if (dartThrow.number == currentTarget) {
  // Hit! Stroke count = this dart number
  holeScores[playerId][game.currentHole - 1] = newDartsThrown;
  currentTurnEnded = true; // Turn ends immediately
} else if (newDartsThrown >= game.maxDarts) {
  // All darts exhausted without hit → Splash
  holeScores[playerId][game.currentHole - 1] = game.maxDarts + 1;
  currentTurnEnded = true; // Turn ends
}
// Otherwise: mid-turn, do NOT set currentTurnEnded
```

**Key invariant:** `currentTurnEnded` is only `true` when a complete turn has finished. The game screen reads this flag via `shouldPromptTakeout`. No other game in the codebase uses this pattern — they all use `dartsThrown >= 3`.

### Random Team Distribution Algorithm
**Purpose:** Auto-derive team count and sizes from player count in Random assignment mode.

**Full algorithm (from spec Section 5):**
```dart
Map<int, (int, List<int>)> randomDistribution(int n) {
  // Step 1: Determine team count T
  final int t;
  if (n <= 7) {
    t = (n / 2).ceil(); // Pair-fill: 3→2, 4→2, 5→3, 6→3, 7→4
  } else if (n == 8) {
    t = 2;              // Special case: [4,4] NOT [2,2,2,2]
  } else if (n <= 11) {
    t = 3;              // 9, 10, 11 → 3 teams of 3-4
  } else {
    t = 4;              // 12-16 → 4 teams of 3-4
  }

  // Step 2: Distribute players into T teams as evenly as possible
  final base = n ~/ t;
  final extra = n % t;
  final sizes = [
    ...List.filled(extra, base + 1),
    ...List.filled(t - extra, base),
  ];

  // Step 3: Shuffle players, deal sequentially
  // (done at provider level with actual player list)
  return sizes;
}
```

**Critical special cases:**
- N=8: spec overrides the natural pair-fill rule → [4,4] not [2,2,2,2]
- N=12: 4 teams of 3, not 3 teams of 4

### Team Grouped Turn Rotation
**Purpose:** Ensure all players on Team A complete the hole before Team B starts (real golf format).

The provider maintains:
- `_currentTeamIndex` — which team currently has the floor
- `_nextPlayerWithinHole[teamId]` — cursor for the next player within each team's roster for the current hole

**`advanceToNextPlayer()` logic:**
```dart
void advanceToNextPlayer() {
  final currentTeam = game.teams[_currentTeamIndex];
  final nextPlayerIdx = (_nextPlayerWithinHole[_currentTeamIndex] ?? 0) + 1;

  if (nextPlayerIdx < currentTeam.length) {
    // More players on this team for this hole
    _nextPlayerWithinHole[_currentTeamIndex] = nextPlayerIdx;
  } else {
    // This team is done with the hole — advance to next team
    _nextPlayerWithinHole[_currentTeamIndex] = 0; // Reset for next hole
    _currentTeamIndex++;

    if (_currentTeamIndex >= game.teams.length) {
      // All teams done with this hole — aggregate best-ball, advance hole
      _aggregateTeamScores();
      _advanceToNextHole();
    }
  }
}
```

### Best-Ball Score Aggregation
```dart
void _aggregateTeamScores() {
  for (int ti = 0; ti < game.teams.length; ti++) {
    final team = game.teams[ti];
    final currentHoleIdx = game.currentHole - 1;

    // Minimum (best/lowest) of all team members' scores for this hole
    final bestScore = team
        .map((pid) => game.playerHoleScores[pid]![currentHoleIdx])
        .whereType<int>()
        .reduce(min);

    game.teamHoleScores[ti][currentHoleIdx] = bestScore;
  }
}
```

## Gotchas and Quirks

### Variable Darts vs Fixed 3 Darts (Most Important Quirk)
**Issue:** Every other game in the codebase ends a turn after exactly 3 darts (`shouldPromptTakeout = dartsThrown >= 3 || hasWinner`). Tiki Golf ends turns based on a `currentTurnEnded` flag, not a dart count.

**Why it happens:** Tiki Golf has configurable Max Darts (3-6) AND turns end early on target hit. A hard-coded `>= 3` would be wrong for Max Darts 4, 5, 6, and would also fire the Remove Darts modal mid-turn if dart 3 misses in a 5-dart game.

**How to handle:** Always use `provider.currentTurnEnded || provider.hasWinner` for `shouldPromptTakeout`. Never use `dartsThrown >= maxDarts` directly in the game screen — the provider tracks this. If adding a new feature that interacts with turn-end, read `currentTurnEnded` from the provider.

**Code location:** `lib/screens/games/tiki_golf/tiki_golf_game_screen.dart` — `shouldPromptTakeout` assignment; `lib/providers/tiki_golf_provider.dart` — `processDartThrow()` and `skipTurn()`.

### Mulligan Modal Replaces Standard RemoveDartsModal
**Issue:** When a Splash occurs AND Mulligan is ON AND player has mulligan available, the standard "DARTS REMOVED" one-button modal is replaced by a two-button modal (USE MULLIGAN + NEXT PLAYER). The DartboardEmulatorSection's built-in `onRemoveDarts` callback wiring must be conditional.

**How to handle:** The game screen checks `showMulliganVariant` before rendering. When true, the standard `RemoveDartsModal` is bypassed and the Mulligan variant is shown. The dartboard section's overlay still fires when `shouldPromptTakeout` is true, but the action buttons are different.

### totalTurns Increment Rule is Unchanged
**Issue:** Some developers assume variable Max Darts changes the `totalTurns` counting semantics.

**It does not.** `totalTurns[playerId]` increments exactly once per turn at the moment dart 1 is thrown. This is the canonical pattern from the skill and applies unchanged regardless of Max Darts setting.

### Solo Mode Max-Players Cap
**Issue:** The `TeamPlayerListPanel` widget's `maxPlayers` parameter is normally used for both Solo and Team caps. For Tiki Golf, Solo = 4 and Team = 16.

**How it was solved:** A `maxPlayersSoloMode` field was added to `TeamPlayerListPanelConfig` during Phase 4. The widget uses `isTeamMode ? config.maxPlayers : config.maxSoloPlayers` for both the header display (`(N/4 selected)` vs `(N/16 selected)`) and the `selectPlayer(maxPlayers: ...)` call.

### N=8 Random Distribution Special Case
**Issue:** A naive "minimize team count" or "minimize team size" algorithm gives N=8 → [2,2,2,2] (4 teams). The spec requires [4,4] (2 teams).

**Why:** The spec prefers fewer-but-bigger teams once pair-fill would max out the team count. This is an explicit design decision, not a bug. The implementation hard-codes the N=8 branch.

### Hole Name Derives from Image, Not Fixed List
**Issue:** The displayed hole name ("Volcano", "Waterfall", etc.) follows the SHUFFLED image assignment, not a fixed hole-name list. If hole 3's shuffled image is `SunsetPier.png`, the displayed name is "Sunset Pier."

**How to handle:** Derive hole names from the `holeImagePaths` list at runtime: `_holeNameFromPath(game.holeImagePaths[currentHole - 1])`. Do NOT maintain a separate fixed `holeNames` list.

## Integration Points

### Global User Management
**Integration:** `PlayerProvider.updatePlayerStats()` called from `TikiGolfResultsScreen.initState()` after winner is determined.

**Solo mode:** 1 player marked winner (`gamesWon++`), all others marked loser (`gamesLost++`).
**Team mode:** All players on the winning team marked winner (Target Tag pattern). All other players marked loser.

### Announcer System
**Integration:** `TikiGolfAnnouncementHelper` wraps `GameAnnouncementQueueService`.

**Key pattern:** The "Almost There" announcement fires at `dartsThrown == game.maxDarts - 1` with no hit. This requires tracking the penultimate dart specifically — not after dart 2 of 3 always, but after dart (N-1) of N.

```dart
if (newDartsThrown == game.maxDarts - 1 && !hitTarget) {
  _audioQueue?.announceAlmostThere(playerName);
}
```

### Victory Music
**Integration:** Standard `VictoryMusicService` integration in `TikiGolfResultsScreen.initState()`.

```dart
@override
void initState() {
  super.initState();
  _playVictoryMusic();
}

Future<void> _playVictoryMusic() async {
  await VictoryMusicService().initialize();
  await VictoryMusicService().play();
}
```

### Dartboard Emulator
**Configuration:** `DartboardSectionConfig.tikiGolf()` — Palm Green background, Tiki Brown borders, Lagoon Blue remove button. See [Components](components.md) for full config.

**Critical:** `shouldPromptTakeout = provider.currentTurnEnded || provider.hasWinner` — see Gotchas above.

## Data Persistence

### Game State (Save/Resume)
**Storage:** Server API via `SaveGameService`

**Serialized fields include:**
- `holeTargets` — The 9 random target numbers (preserved so resumed game plays same course)
- `holeImagePaths` — The 9 random image paths (preserved so hole themes are unchanged)
- `playerHoleScores` — Per-player completed hole scores
- `dartsThrown` — Current-turn state
- `currentTurnEnded` — Turn-end flag
- `playerMulliganAvailable` / `playerMulliganUsedThisGame` — Mulligan state
- `currentHole`, `currentPlayerIndex` — Position in game
- `teamAssignments`, `teamCrestPaths` — Team setup (Team mode)

**Save trigger:** Same as all other games — auto-save when navigating away from the game screen while the game is in progress.

### Player Stats
**Data Tracked:**
- `gamesPlayed` — Incremented for every player at game end
- `gamesWon` — Incremented for winner (Solo) or all winning team players (Team)
- `gameHistory` — Entry added with `gameName: 'Tiki Golf'`, duration, and player count

## Known Issues and Limitations

### 9 Holes Only
Tiki Golf ships with exactly 9 hole themes. There is no "5-hole" or "18-hole" mode. This is by design — the 9 hole-theme images map 1:1 to the 9 holes. Extending to more holes would require additional themed images.

### Fixed Par = 2
Par is always 2 strokes regardless of Max Darts setting. This is intentional — par is the "natural" benchmark (hit on your second dart). Players with Max Darts 6 have 4 extra chances, making birdies much more achievable, but par and bogey are always defined relative to 2 strokes.

## Reference Implementations

### Similar Patterns in Other Games
- **Per-game randomization:** Reef Royale creature shuffling (`lib/models/reef_royale_game.dart:208-213`) — same `List<X>..shuffle(Random())` pattern
- **Team mode with best-ball:** Unique to Tiki Golf; Target Tag is the reference for `TeamPlayerListPanel` integration and team assignment flows
- **Save/resume with complex model:** Gladiator Arena save/restore tests (`test/providers/gladiator_arena_save_restore_test.dart`) as pattern reference for the 13 Tiki Golf save/restore tests

### External Resources
- **Dart Golf game rules:** Standard dart golf rules (9 holes, sequential, lowest strokes wins) underpin the scoring system
- **Best-ball golf format:** Standard "best ball" / "better ball" tournament format where team score = lowest individual score per hole
