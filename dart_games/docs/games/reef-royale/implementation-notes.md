# Reef Royale — Implementation Notes

## Code Architecture

### Provider Pattern
`lib/providers/reef_royale_provider.dart`
- Manages game state via `ReefRoyaleGame` model
- Handles dart throw processing, turn management, and takeout flow
- Provides per-dart tracking arrays (marks, pearls, claims, neighbor flags, target counts)
- Integrates with `ReefRoyaleAnnouncementHelper` for audio

### Model
`lib/models/reef_royale_game.dart`
- Immutable game configuration (mode, options, targets, coral order)
- Mutable game state (marks, pearls, claimed sets, locked targets, buff, round)
- All scoring logic self-contained in model
- Factory constructor `ReefRoyaleGame.create()` handles setup (creature assignment, target selection)

### Screen Architecture

1. **Menu Screen** — Game description, 8 option controls, player list, Dive In button
2. **Game Screen** — Active player panel (left), coral tracker (center), opponent bar (bottom), dartboard
3. **Results Screen** — Winner creature, rankings, action buttons, confetti

## Key Algorithms

### Target Resolution
Two-phase resolution for neighbor numbers:
1. `resolveTarget(hitNumber)` — Returns first matching target (direct or neighbor)
2. `resolveAllTargets(hitNumber)` — Returns ALL matching targets (handles shared neighbors)

A shared neighbor is a number adjacent to two targets on the dartboard. Hitting it adds marks to both targets in a single dart throw.

### Pearl Scoring
```
pearlValue = targetNumber × multiplierValue
if (Pearl Fever buff): pearlValue × 2
if (Cursed Tide): pearls go to all opponents who haven't claimed that target
else: pearls go to the throwing player
```

### Coral Claiming with Excess Marks
When marks exceed the threshold on a single dart:
1. Coral is claimed
2. Excess marks convert to pearl scoring (if opponents haven't claimed)
3. Both claim and pearl events fire on the same dart

### Ranking
```dart
getRankedPlayerIds() {
  sort by: most corals claimed (descending)
  tiebreak: most pearls (standard) or fewest pearls (cursedTide)
}
```

### Edit Score (Turn Revert)
1. `resetToStartOfTurn()` — Restores marks, pearls, claimed, locked to turn-start snapshot
2. Replay modified darts via `processDart()` with new values
3. Preserves active buff state during replay

## Dartboard Layout Utility

`DartboardLayout` class in `reef_royale_game.dart`:
- `getNeighbors(number)` — Returns left and right adjacent numbers on physical dartboard
- `findNeighborTarget(hitNumber, targets)` — Finds first target neighboring the hit
- `findAllNeighborTargets(hitNumber, targets)` — Finds all targets neighboring the hit

The dartboard number order (clockwise): 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5

## Integration Points

### Global Systems Used
- **PlayerProvider** — Player management, photos, avatars
- **DartboardProvider** — WebSocket connection, emulator mode
- **GameAnnouncementQueueService** — Audio announcement queue
- **VictoryMusicService** — Victory screen music
- **GameHistoryService** — Game stats persistence

### Shared Components Used
- AddPlayerDialog (with reef config)
- EditScoreDialog (with reef config)
- RemoveDartsModal (with reef config)
- DartboardPausedModal (with reef config)
- DartboardEmulatorSection / FAB (with reef config)
- DartboardConnectionInfo
- PlayerListPanel
- InteractiveDartboard

### Emulator vs Real Dartboard
Emulator visibility is based on `!dartboardProvider.isEmulator` (not `isConnected`), so disconnecting a real dartboard mid-game shows only the paused modal, not the emulator.

## Gotchas

- **pumpAndSettle()** — Never use in integration tests; splash screen `CircularProgressIndicator` prevents settling
- **Buff during edit score** — Must preserve active buff for correct mark/pearl recalculation
- **Shared neighbors** — A single dart can add marks to 2 targets simultaneously; both targets fire claim/lock events independently
- **Cursed Tide excess marks** — When claiming with excess marks, the pearl recipient is the first opponent who hasn't claimed that target
- **Random Reefs coral order** — Coral types are shuffled independently of target numbers; Bull always maps to PearlOyster
- **Inner Bull vs Outer Bull** — Inner bull (50) gives 2 marks, outer bull (25) gives 1 mark; pearl values match (50 and 25 respectively)

## Stats Tracking

Game history records:
- `dartThrows` — Total darts thrown
- `turns` — Total turns played
- `playerCount` — Number of players
- `totalPearlsScored` — Total pearls earned
