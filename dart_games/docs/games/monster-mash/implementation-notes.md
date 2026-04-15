# Monster Mash - Implementation Notes

## Code Architecture

### Provider Pattern
**File:** `lib/providers/monster_mash_provider.dart`

**State Management:**
- Manages current game state (`MonsterMashGame` model)
- Tracks waiting-for-takeout state (`_waitingForTakeout`)
- Provides getters for health, elimination status, buff info
- Notifies listeners on all state changes

**Key Methods:**
- `startGame(List<Player> players, settings)` - Initialize new game with player list and configuration
- `processDartThrow(int score, String multiplier, int baseScore, String segment)` - Records dart throw, processes healing/damage
- `skipTurn()` - Fills remaining dart slots with markers, sets waiting for takeout
- `updateDartScore(playerId, dartIndex, segment)` - Edit individual dart in a turn
- `updateAllDartScores(playerId, segments)` - Edit all 3 darts at once
- `handleTakeoutFinished()` - Advance to next player after darts removed
- `endGame()` / `clearGame()` - Cleanup

### Models
**File:** `lib/models/monster_mash_game.dart`

**Key Enums:**
- `MonsterMashGameState`: setup, playing, finished
- `MonsterType`: dracula, frankenstein, mummy, wolfMan, invisibleMan, gillMan, mrHyde, phantom
- `BonusBuff`: bloodMoon, ancientBandages, shadowWalk, laboratorySpark

**Data Structure:**
```dart
class MonsterMashGame {
  final int maxDartsPerTurn;          // Always 3
  final int healthMax;                 // 10-50 (configurable)
  final bool bonusBuffsEnabled;        // Buff system toggle
  final bool speedPlayEnabled;         // Round limit toggle
  final int roundLimit;                // 3-20 when speed play on

  Map<String, int> targetNumbers;      // playerId → dart number (1-20)
  Map<String, MonsterType> monsterAssignments;  // playerId → monster
  Map<String, int> health;             // playerId → current HP
  Map<String, bool> eliminated;        // playerId → eliminated status

  // Per-dart tracking
  Map<String, List<int>> dartThrowHealAmount;
  Map<String, List<int>> dartThrowDamageDealt;
  Map<String, List<String?>> dartThrowTargetPlayerId;
}
```

### Screen Architecture

#### Menu Screen
**File:** `lib/screens/games/monster_mash/monster_mash_menu_screen.dart`

**Layout:**
- Left panel: Game description, rules, feature explanations
- Right panel: Game settings and player selection
- Stone tablet start button with lightning animation

**Settings:**
- Health Points slider (10-50, default 20)
- Bonus Buffs toggle (Off/On)
- Speed Play toggle (Off/On)
- Round Limit slider (3-20, only active when Speed Play enabled, default 10)

#### Game Screen
**File:** `lib/screens/games/monster_mash/monster_mash_game_screen.dart`

**Layout:**
- Active player panel (left 28%): Monster image, health bar, target shield, darts thrown
- Opponent grid (right side): Bottom-heavy perspective layout
- Round progress bar (top-center): Round display with buff indicators
- Dartboard emulator (bottom overlay)

#### Results Screen
**File:** `lib/screens/games/monster_mash/monster_mash_results_screen.dart`

**Layout:**
- Winner monster image(s) with glow
- "LAST MONSTER STANDING!" or "TIED!" text
- Winner name(s) with player photo
- Three stone action buttons with different lightning colors
- Confetti animation from 3 directions

## Complex Algorithms

### Health Image Selection (4-Tier System)
**Purpose:** Select correct monster image based on current HP percentage

```dart
String getMonsterImagePath(String playerId) {
  final healthPercent = health[playerId]! / healthMax;
  final monsterName = monsterAssignments[playerId]!.name;

  if (healthPercent <= 0) return '$monsterName-Eliminated.png';
  if (healthPercent <= 0.30) return '$monsterName-30Health.png';
  if (healthPercent <= 0.70) return '$monsterName-70Health.png';
  return '$monsterName-FullHealth.png';
}
```

**Thresholds:** 0% → Eliminated, <=30% → 30Health, <=70% → 70Health, >70% → FullHealth

### Turn State Snapshots for Edit Score
**Purpose:** Allow score editing by replaying turn from saved state

```dart
void saveInitialTurnStartState() {
  // Captures health, eliminated, and buff state at turn start
  _savedHealth = Map.from(health);
  _savedEliminated = Map.from(eliminated);
  _savedActiveBuff = activeBuff;
}

void resetToStartOfTurn() {
  // Restores state to turn start, then replays edited darts
  health = Map.from(_savedHealth!);
  eliminated = Map.from(_savedEliminated!);
  activeBuff = _savedActiveBuff;
}
```

### Buff System
**Purpose:** Random buff activation at round boundaries

```dart
void _checkBuffActivation() {
  if (!bonusBuffsEnabled) return;
  if (Random().nextInt(3) == 0) {  // ~33% chance
    activeBuff = BonusBuff.values[Random().nextInt(BonusBuff.values.length)];
  } else {
    activeBuff = null;
  }
}
```

**Rules:**
- Checked at round boundary (when turn order wraps back to first player)
- Only one buff active at a time
- ~33% activation probability (`Random().nextInt(3) == 0`)

### Speed Play Winner Determination
**Purpose:** Determine winner(s) when round limit is reached

```dart
List<Player> getWinners(List<Player> allPlayers) {
  // 1. Filter to non-eliminated players
  // 2. Sort by HP (descending)
  // 3. If tie, sort by total damage dealt (descending)
  // 4. Return all players matching top HP and damage
}
```

**Tiebreak Order:** HP first → Total damage dealt → Multiple winners (tie)

### Turn Advancement
**Purpose:** Skip eliminated players when advancing turns

```dart
void advanceToNextPlayer() {
  int attempts = 0;
  do {
    currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;
    attempts++;
  } while (eliminated[playerIds[currentPlayerIndex]] == true && attempts < playerIds.length);
}
```

Uses do-while with attempt counter to prevent infinite loops when all players eliminated.

### Opponent Grid Layout
**Purpose:** Position 1-7 opponents with perspective scaling

```dart
List<CellAssignment> _getCellAssignments(int opponentCount) {
  // Returns grid positions with scale factors
  // Back rows: 0.75x scale (smaller, further away)
  // Front rows: 1.25x scale (larger, closer)
  // Dynamic column count based on opponent count
}
```

## Gotchas and Quirks

### Buff State During Edit Score
**Issue:** Editing scores must preserve the buff that was active during the original turn
**Why:** Buff affects damage/healing calculations, so replaying darts with wrong buff gives wrong results
**How:** `saveInitialTurnStartState()` captures `activeBuff`, `resetToStartOfTurn()` restores it

### Monster Image Flipping
**Issue:** Active player monster faces right, opponents face left
**Why:** Creates visual "facing off" effect between active player and opponents
**How:** Active player image is horizontally flipped via Transform widget

### Eliminated Player Grid Positioning
**Issue:** Eliminated opponents remain in grid but visually offset down and faded
**Why:** Removing them would cause grid to shift, confusing players
**How:** Eliminated tiles use reduced opacity and vertical offset, shields/health hidden

## Performance Considerations

### 32 Character Images
**Concern:** Loading 32 character images (8 monsters x 4 states)
**Mitigation:** Images loaded on demand via `Image.asset()`, Flutter caches loaded images
**Monitoring:** Watch for initial load time with all 8 players

### Perspective Grid Scaling
**Concern:** Transform.scale on grid cells may impact rendering
**Mitigation:** Scales are static per layout, no animation on scale values
**Monitoring:** Watch for frame drops with 7 opponents

## Integration Points

### Global User Management
```dart
// On game complete (results screen)
final gameDuration = DateTime.now().difference(game.startedAt);
for (final playerId in game.playerIds) {
  await playerProvider.updatePlayerStats(
    playerId,
    won: winners.contains(playerId),
    gameName: 'Monster Mash',
    gameDuration: gameDuration,
    dartThrows: game.getDartThrowCount(playerId),
    turns: game.getTurnCount(playerId),
    playerCount: game.playerIds.length,
    totalDamageDealt: game.getTotalDamageDealt(playerId),
  );
}
```

### Shared Widget: StoneDialogButton
**File:** `lib/widgets/stone_dialog_button.dart`

Previously game-specific, `StoneDialogButton` was promoted to a shared widget at the `lib/widgets/` level. It is used by:
- Monster Mash menu screen (Start button)
- Monster Mash results screen (3 action buttons)
- Monster Mash Add Player dialog (Cancel and Add buttons via `customCancelButton`/`customAddButton`)

### Promoted Widgets
Two widgets were promoted from `lib/widgets/horse_race/` to `lib/widgets/` during Monster Mash development:
- `player_selection_card.dart` - Shared player selection card
- `player_avatar_widget.dart` - Shared player avatar display

## Stats Tracking

Monster Mash tracks per-player statistics:
- `dartThrows` - Total darts thrown
- `turns` - Total turns taken
- `playerCount` - Number of players in game
- `totalDamageDealt` - Cumulative damage dealt to opponents

## Reference Implementations

### Similar Patterns in Other Games
- Turn-based gameplay: Target Tag uses similar turn advancement (skip eliminated)
- Edit score dialog: Target Tag has same pattern with different config
- Announcer integration: Target Tag shows complete announcement helper
- Victory music: Target Tag demonstrates identical pattern
- Dartboard emulator: All games use same shared components

### External Resources
- Flutter Provider package: https://pub.dev/packages/provider
- Google Fonts package: https://pub.dev/packages/google_fonts
- Dart Shelf server: https://pub.dev/packages/shelf
