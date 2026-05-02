# Game Integration Requirements

## Overview

**ALL games in the Dart Games app MUST integrate with the global systems.**

This ensures consistency, proper user management, and unified experience across all games.

## Required Integrations

### 1. Global User Management (PlayerProvider)

✅ **Use global player list** for available players  
✅ **Add new players to global list** via `PlayerProvider.savePlayer()`  
✅ **Update player stats** for ALL players (winners AND losers)

```dart
// Update stats for every player in the game
for (final playerId in game.playerIds) {
  final isWinner = winnerIds.contains(playerId);
  await playerProvider.updatePlayerStats(
    playerId,
    won: isWinner,
    gameName: 'Your Game Name',
    gameDuration: gameDuration,  // SAME duration for all players
  );
}
```

### 2. Announcer Integration (GameAnnouncementQueueService)

✅ **Create game-specific announcement helper**
✅ **DO NOT use DartAnnouncerService directly**
✅ **Use priority-based queuing**
✅ **Analyze announcement stacking** — identify worst-case per-dart announcement count
✅ **Apply precedence rules** — max 2 announcements per dart (1 moment + Remove Darts)
✅ **"Remove your darts" must always play** — never suppress this announcement

See [Announcement System Integration](announcement-system.md) for complete guide including the stacking prevention pattern.

### 3. Victory Music (VictoryMusicService)

✅ **Play victory music on win**  
✅ **Check if custom music available**  
✅ **Handle cross-platform music sources**

```dart
final musicService = VictoryMusicService();
if (await musicService.hasCustomMusic()) {
  final musicSource = await musicService.getRandomMusicSource();
  if (musicSource != null) {
    // Play music
  }
}
```

### 4. Dartboard Connection (DartboardProvider)

✅ **Use for dart input**  
✅ **Check connection status**  
✅ **Support emulator mode**

```dart
final dartboardProvider = Provider.of<DartboardProvider>(context);
if (dartboardProvider.isConnected) {
  // Using real dartboard
} else {
  // Show emulator
}
```

### 5. Game Duration Tracking

✅ **Track game start time** when game begins  
✅ **Calculate duration** when game completes  
✅ **Pass to updatePlayerStats()** for ALL players

```dart
class GameProvider {
  DateTime? _gameStartTime;

  void startGame() {
    _gameStartTime = DateTime.now();
  }

  void endGame() {
    final duration = DateTime.now().difference(_gameStartTime!);
    // Pass duration to updatePlayerStats for all players
  }
}
```

### 6. Navigation Rules

Every game MUST follow these back-navigation rules:

✅ **Game menu back arrow** → returns to Home (game selection)  
✅ **Game screen back arrow** → returns to that game's menu (show save modal if darts thrown)  
✅ **Results → Change Settings** → keeps Home in the stack  
✅ **Results → Play Again** → replaces results with new game screen  
✅ **Results → Home** → pops to first route  

```dart
// Menu screen back arrow — pops to Home
leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => Navigator.pop(context),
),

// Game screen back arrow — pops to Menu (with save guard)
onPressed: () {
  if (hasDartsThrown) {
    setState(() => _showSaveModal = true);
  } else {
    Navigator.of(context).pop();
  }
},

// Results → Change Settings — keep Home, remove game + results
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => YourGameMenuScreen(...)),
  (route) => route.isFirst,  // MUST use route.isFirst, NOT (route) => false
);

// Results → Play Again — replace results with new game
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const YourGameScreen()),
);

// Results → Home — pop everything back to Home
Navigator.popUntil(context, (route) => route.isFirst);
```

**Critical:** Never use `(route) => false` in Change Settings — this clears the Home route from the stack, breaking the menu back arrow.

### Required Navigation Tests

Every game MUST have these 4 navigation UI tests in `integration_test/your_game/navigation/`:

1. **`menu_back_to_home_test.dart`** — Navigate to menu, tap back button, verify ≥3 home screen game cards visible
2. **`game_back_settings_persist_test.dart`** — Change non-default settings, start game, tap game back button, verify settings preserved on menu
3. **`change_settings_back_to_home_test.dart`** — Complete game, click Change Settings, tap menu back, verify home screen (catches the `route.isFirst` bug)
4. **`change_settings_preserves_settings_test.dart`** — Complete game, click Change Settings, verify settings and players preserved on menu

See existing implementations in `integration_test/*/navigation/` for all 5 games.

## Optional But Recommended Integrations

### Dartboard Emulator Components

Use shared components for consistent behavior.  
See [Dartboard Emulator Integration](dartboard-emulator.md).

### Add Player Dialog Component

Use shared dialog for player creation.  
See [Add Player Dialog Integration](add-player-dialog.md).

### Edit Score Dialog Component

Use shared dialog for score editing.
See [Edit Score Dialog Integration](edit-score-dialog.md).

### Dartboard Paused Modal Component

Use shared modal to pause gameplay when dartboard connection is lost.
See [Dartboard Paused Modal Integration](dartboard-paused-modal.md).

## Integration Checklist

- [ ] Use PlayerProvider for user management
- [ ] Create game-specific announcement helper
- [ ] Analyze announcement stacking and apply precedence rules (max 2 per dart)
- [ ] Ensure "Remove your darts" announcement always plays
- [ ] Call updatePlayerStats() for ALL players (winners and losers)
- [ ] Track game duration from start to end
- [ ] Play victory music on win
- [ ] Use DartboardProvider for dart input
- [ ] Use dartboard emulator components
- [ ] Use add player dialog component
- [ ] Use edit score dialog component
- [ ] Use dartboard paused modal component
- [ ] Follow navigation rules (menu→Home, game→menu, Change Settings uses `route.isFirst`)
- [ ] Create component config factory methods
- [ ] Implement PlayToCompleteStrategy for the game
- [ ] Create PlayToCompleteButtonConfig factory method
- [ ] Wire Play to Complete into game screen (runner, guards, callbacks)
- [ ] Write Play to Complete UI tests (default settings + game-critical settings + mid-game)
- [ ] Write navigation UI tests (menu→home, game→menu+settings, change settings→back→home, change settings→verify settings)

## Critical: Game Duration Tracking for ALL Players

**IMPORTANT:** Both winners AND losers MUST receive game duration tracking.

```dart
// ✅ CORRECT - All players receive duration
for (final playerId in game.playerIds) {
  await playerProvider.updatePlayerStats(
    playerId,
    won: winnerIds.contains(playerId),
    gameName: 'Your Game',
    gameDuration: gameDuration,  // Same for all
  );
}

// ❌ WRONG - Only winner gets duration
await playerProvider.updatePlayerStats(
  winnerId,
  won: true,
  gameName: 'Your Game',
  gameDuration: gameDuration,
);
```

## Testing Requirements

Create tests that verify:
- Player stats updated for all players
- Game duration tracked correctly
- Winners have gamesWon incremented
- Losers have gamesPlayed incremented
- Stats persist across app restarts

See `test/screens/games/target_tag/target_tag_user_management_test.dart` for reference.

## Reference Implementations

- **Target Tag:** Complete integration example
- **Carnival Derby:** Complete integration example

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems](../architecture/shared-systems.md)
- [Announcement System Integration](announcement-system.md)
