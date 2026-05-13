# Gladiator Arena - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/gladiator_arena_provider.dart`

**State Management:**
- `GladiatorArenaProvider extends ChangeNotifier` manages the full game state machine
- Key state variables: `List<GladiatorArenaPlayer> players`, `int currentPlayerIndex`, `int currentRound`, `List<int> currentTurnDarts` (turn's dart values), `bool hasWinner`, `String? winnerId`, `bool shouldPromptTakeout`
- Knockoff tracking: `Map<String, int> knockoffsDealt` and `Map<String, int> knockoffsReceived` — persisted in the model for Results screen stats display
- Options stored as provider fields: `int targetScore`, `bool doubleFinishEnabled`, `bool shieldRoundEnabled`, `bool speedPlayEnabled`
- Bust state: `bool lastTurnWasBust`, `bool lastBustWasOvershoot` — read by the game screen to trigger the correct bust announcement/animation

**Key Methods:**
- `startGame(List<Player> selectedPlayers, {...options})` — initializes game state, shuffles and assigns characters
- `processDartThrow(DartboardSegment segment)` — adds dart to turn, triggers `shouldPromptTakeout` after 3 darts
- `handleTakeoutFinished()` — applies turn total, runs bust check, runs knockoff check, advances turn
- `skipTurn()` — processes turn with current darts (can be 0), triggers `shouldPromptTakeout`
- `updateAllDartScores(List<String> segments)` — called from Edit Score dialog; re-evaluates turn from edited segments
- `clearGame()` / `endGame()` — lifecycle management

### Models
**File:** `lib/models/gladiator_arena_game.dart`

**Data Structure:**
```dart
class GladiatorArenaGame {
  final String id;
  final DateTime startedAt;
  final List<String> playerIds;
  final Map<String, int> playerScores;       // playerId → score
  final Map<String, String> playerCharacters; // playerId → character name
  final Map<String, int> knockoffsDealt;     // playerId → count
  final Map<String, int> knockoffsReceived;  // playerId → count
  final int currentPlayerIndex;
  final int currentRound;
  final int targetScore;
  final bool doubleFinishEnabled;
  final bool shieldRoundEnabled;
  final bool speedPlayEnabled;
  final String? winnerId;
  // toJson / fromJson for serialization
}
```

**Map-of-Strings approach:** Player scores and character assignments are stored as `Map<String, int>` and `Map<String, String>` keyed by player ID. This avoids index-misalignment bugs (especially relevant when players are removed or reordered) and serializes naturally to/from JSON without custom enum handling.

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/gladiator_arena/gladiator_arena_menu_screen.dart`

Renders the two-panel layout (left: How to Play, right: Settings + DualPlayerListPanel + Start button). The Target Score slider uses a `Slider` widget with `min: 100`, `max: 500`, `divisions: 16` (17 stops: 100, 125, …, 500). The slider value is converted to an integer display via `(sliderValue).round()`. The "2 rows of 2 settings boxes" pattern is implemented as a `Column` of two `Row`s.

Save/Resume: The menu checks for saved games via `SaveGameService` in `initState` and sets `_hasSavedGames` accordingly. The `ResumeGameButton` is rendered in the AppBar actions when true.

#### Game Screen
**File:** `lib/screens/games/gladiator_arena/gladiator_arena_game_screen.dart`

The full screen structure uses an outer `Stack` with:
1. `Scaffold` (background image + dark overlay, AppBar, body with Arena Podium Display)
2. `Positioned(bottom: 0)` DartboardEmulatorSection (shown only when `!dartboardProvider.isConnected`)
3. `Positioned(right: 16, bottom: 16)` DartboardEmulatorFAB
4. `RemoveDartsModal` overlay (shown when `provider.shouldPromptTakeout && !dartboardProvider.isConnected`)
5. `SaveGameModal` overlay (shown when `_showSaveModal`)
6. `DartboardPausedModal` overlay (shown when dartboard is paused)

Speed Play timer: managed as `Timer? _speedPlayTimer` in the screen's `State`. Started by `_startSpeedPlayTimerForCurrentPlayer()` at the beginning of each turn. Cancelled by `_speedPlayTimer?.cancel()` when `provider.shouldPromptTakeout` becomes true (detected via `ChangeNotifier` listener). This pattern is identical to Pirate's Grid's Speed Play implementation.

#### Results Screen
**File:** `lib/screens/games/gladiator_arena/gladiator_arena_results_screen.dart`

Uses `initState` to call `_updatePlayerStats()` (updates `PlayerProvider` with win/loss counts and game history) and `_playVictoryMusic()` (initializes `VictoryMusicService`). Both must be called in `initState`, not `build`, to pass the mandatory Results Screen UI tests (`winner_stats_updated_test.dart`, `victory_music_initialized_test.dart`).

Rankings use the 2-column layout for 5–8 players: `rankedPlayers.length > 4 ? twoColumnLayout : singleColumnLayout`. Matches the pattern in Lunar Lander and Reef Royale.

## Complex Algorithms

### Knockoff Check
**Purpose:** After applying the active player's turn score, check if their new score matches any other player's score and reset those players to 0.

**Implementation:**
```dart
void _runKnockoffCheck(String activePlayerId) {
  final activeScore = _game.playerScores[activePlayerId]!;
  final isShieldRound = shieldRoundEnabled && (_game.currentRound % 5 == 0);

  for (final playerId in _game.playerIds) {
    if (playerId == activePlayerId) continue; // No self-knockoff
    if (_game.playerScores[playerId] == activeScore) {
      if (isShieldRound) {
        // Fire shield block announcement, do NOT reset
        _lastShieldBlockedPlayer = playerId;
      } else {
        // Reset victim to 0
        _game = _game.copyWith(
          playerScores: {..._game.playerScores, playerId: 0},
          knockoffsDealt: {..._game.knockoffsDealt,
            activePlayerId: (_game.knockoffsDealt[activePlayerId] ?? 0) + 1},
          knockoffsReceived: {..._game.knockoffsReceived,
            playerId: (_game.knockoffsReceived[playerId] ?? 0) + 1},
        );
        _lastKnockoffVictim = playerId;
      }
    }
  }
}
```

**Edge cases:**
- Shield round check: `currentRound % 5 == 0` AND `shieldRoundEnabled`
- Multiple simultaneous knockoffs iterate all players in one pass
- Self-score match is skipped by the `if (playerId == activePlayerId) continue` guard

### Bust Detection (Double Finish ON)
**Purpose:** Determine whether a turn should be voided and which type of bust occurred.

**Implementation (pseudocode):**
```
prospective = currentScore + turnTotal
if prospective > target:
  → overshoot bust (lastBustWasOvershoot = true)
  → revert score, do not advance
elif prospective == target:
  if lastDartIsDouble:
    → VICTORY
  else:
    → no-double bust (lastBustWasOvershoot = false)
    → revert score, do not advance
else:
  → score = prospective (normal advancement)
```

The "last dart is double" check reads the final entry from `currentTurnDarts`' segment strings. A dart is a double if its segment notation starts with 'D' (e.g., "D20", "D10") OR equals "OB" (Outer Bull = D25 in Eliminator terminology).

### Double-Finish Range Detection
**Purpose:** Determine when to show the "Double Range!" indicator.

A player is in double-finish range when their score is within distance of any possible double dart (D1=2 through D20=40, plus OB=25). The range indicator appears when `(targetScore - currentScore) <= 40`. Since the maximum single double is D20=40, any gap ≤40 means the player could potentially finish on their next double dart.

### Speed Play Timer
**Purpose:** Cancel remaining dart slots when the 25-second turn timer expires.

The timer counts down in the screen's State. When it fires:
1. Record how many darts have been thrown so far (0–2 for partial turns)
2. Fill remaining dart slots with a "timeout" marker (scored as 0)
3. Trigger `shouldPromptTakeout` via `provider.onSpeedPlayExpired()`
4. Show timeout markers ("X") in the unfilled dart indicator slots

## Gotchas and Quirks

### Pattern A Score Display
**Issue:** The spec uses "Pattern A" scoring — scores shown directly on the podium as plain numbers (running totals). There is no S/D/T prefix displayed on the podium itself.
**How to handle:** Score labels on podiums render `provider.playerScore(id).toString()` directly. Individual dart segments are only shown in the D1/D2/D3 AppBar indicators and in the Edit Score dialog (where they show segment notation like "S20", "D10").
**Code location:** `_buildPodium()` in game screen; `EditScoreDialogConfig.gladiatorArena()` does NOT use `scoreDisplayTransform`

### Laurel Green Double-Hit Highlight
**Issue:** When a player wins with Double Finish ON, the winning double segment should briefly glow Laurel Green before transitioning to results.
**How to handle:** The game screen listens for `provider.hasWinner` and when the last dart was a double win, applies a `ColorFiltered` / `ImageFiltered` glow to the active dartboard segment for ~600ms before navigating to results.
**Color:** Laurel Green `#4A7C59`
**Code location:** `_handleWinnerAnimation()` in game screen

### Character Randomization at Game Start
**Issue:** Characters must be randomly assigned in `initState` of the game screen (not in the provider or model constructor) so that re-entering the same game from the menu re-randomizes characters.
**How to handle:** The game screen calls `provider.startGame(selectedPlayers, ...)` which internally shuffles the character list and assigns one to each player. This is identical to the Lunar Lander and Reef Royale patterns.
**Code location:** `GladiatorArenaProvider.startGame()`

### Name Label Below Podium (Active Player Only)
**Issue:** The spec calls for the active player's name to be rendered directly below their podium on the arena floor bar. Inactive players do NOT have their names shown.
**How to handle:** The podium builder renders a conditional `Text` widget below each podium that is only visible when `playerId == provider.currentPlayerId`.
**Code location:** `_buildPodium(playerId)` in game screen; uses `GladiatorArenaGameKeys.activePlayerNameLabel`

### Podium Bar Gladiator Gold for Active Player
**Issue:** The spec states the active player's podium bar (the vertical column) should use Gladiator Gold color, while inactive players use their player accent color.
**How to handle:** `_buildPodium()` checks `playerId == provider.currentPlayerId` and applies `Color(0xFFDAA520)` (Gladiator Gold) for the active player's bar, otherwise uses the player's assigned accent color.

### Shield Round Round-Count
**Issue:** The "every 5th round" check must use the provider's `currentRound` field, which increments once all players have completed their turn (not per player turn).
**How to handle:** `provider.currentRound % 5 == 0 && provider.shieldRoundEnabled` — evaluated when the round advances. The shield banner UI renders based on this condition checked at the start of each round.

## Save/Resume Integration

Game state is persisted via `SaveGameService` using the standard `SaveGameMetadata` wrapper around `GladiatorArenaGame.toJson()`. The `resumedSavedGameId` pattern is used to track the active save so that completing a resumed game auto-deletes the save entry.

Key fields preserved across save/restore:
- All player scores (`playerScores`)
- Current round and player index
- Knockoff history (dealt and received counts)
- All game options (target, doubleFinish, shieldRound, speedPlay)
- Character assignments
- Whether the game was started (to distinguish from an un-started game)

Speed Play timer state is NOT serialized — when a game is resumed, the timer starts fresh for the current player's turn (same behavior as Pirate's Grid).

## Play-to-Complete Strategy

**File:** `lib/services/play_to_complete/gladiator_arena_strategy.dart`
**Class:** `GladiatorArenaStrategy`

**Pattern (Miss + Miss + winner-dart):**
- Dart 1: Miss (0 points)
- Dart 2: Miss (0 points)
- Dart 3: Winning dart

This pattern ensures the turn total equals only the final dart's value, allowing clean victory detection. The strategy reads the current player's score each turn and decides what the final dart needs to be:

- **Double Finish ON:** Strategy targets `D20` (40 pts) as the winning dart. Each turn, darts 1 and 2 miss, dart 3 scores 40. When the active player's score is `targetScore - 40`, the D20 wins. Until then, scores accumulate 40 per turn.
- **Double Finish OFF:** Strategy targets `S20` (20 pts) as the final dart. Accumulates 20 per turn until `currentScore + 20 >= targetScore`, at which point the game ends.

The strategy also handles the case where no single dart can finish cleanly (e.g., target - currentScore = 41, which isn't achievable with a single double) by building up the score incrementally each turn until a clean finish is available.

## Integration Points

### Global User Management
`PlayerProvider.updatePlayerStats()` is called from the Results screen's `initState` with the winner ID and final standings. Game history entry includes `gameName: 'Gladiator Arena'`, duration, and dart counts.

### Announcer System
`GladiatorArenaAnnouncementHelper` wraps `GameAnnouncementQueueService`. The game screen creates and holds the helper instance, calling announcement methods after each significant event (dart throw, knockoff, bust, victory, turn start). The `announceRemoveDarts()` fires unconditionally at the end of every turn.

### Victory Music
`VictoryMusicService().initialize()` is called from the Results screen's `initState` via `_playVictoryMusic()`. This is required for the `victory_music_initialized_test.dart` UI test to pass.

### Dartboard Provider
The game screen observes `dartboardProvider.isConnected` to show/hide the `DartboardEmulatorSection` and `DartboardEmulatorFAB`. When `dartboardProvider.isConnected` changes from false to true mid-game (user connects hardware board), the emulator overlay hides automatically.

## Reference Implementations

### Similar Patterns in Other Games
- **Random character assignment:** Lunar Lander (`lunar_lander_provider.dart`), Reef Royale (`reef_royale_provider.dart`)
- **Speed Play timer in screen State:** Pirate's Grid (`pirates_grid_game_screen.dart`) — identical cancel-on-takeout pattern
- **Dual-list player panel:** Lunar Lander (only other game using `DualPlayerListPanel` without team mode)
- **2-column results rankings:** Lunar Lander and Reef Royale (`_buildRankings()` with `rankedPlayers.length > 4` threshold)
- **Outer-Stack emulator overlay:** All games from Monster Mash onward
