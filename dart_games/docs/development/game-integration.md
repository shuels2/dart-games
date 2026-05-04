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
- [ ] Victory flow waits for DARTS REMOVED before navigating to results (no auto-navigate on hasWinner)
- [ ] Edit score winner/stats toggle tests present (`edit_creates_winner_stats_test.dart`, `edit_removes_winner_no_stats_test.dart`)
- [ ] Pause modal tests present (`pause_modal/menu_pause_test.dart`, `gameplay_pause_test.dart`, `results_pause_test.dart`)
- [ ] Follow navigation rules (menu→Home, game→menu, Change Settings uses `route.isFirst`)
- [ ] Create component config factory methods
- [ ] Implement PlayToCompleteStrategy for the game
- [ ] Create PlayToCompleteButtonConfig factory method
- [ ] Wire Play to Complete into game screen (runner, guards, callbacks)
- [ ] Write Play to Complete UI tests (default settings + game-critical settings + mid-game)
- [ ] Write navigation UI tests (menu→home, game→menu+settings, change settings→back→home, change settings→verify settings)
- [ ] Outer-Stack modal pattern on game screen (Scaffold inside Stack, modals as Stack siblings -- NOT inside body)
- [ ] AppBar back button uses size 32 + transparent hover/highlight/splash colors
- [ ] Generic avatars on player tiles (no game character images on tiles or rankings)

## Outer-Stack Modal Architecture

Every game screen (menu, game, results) MUST wrap `Scaffold` in an outer `Stack` so that modals paint OVER the AppBar. The `build()` method's return value is `Stack`, NOT `Scaffold`.

**Why:** Modals placed inside the Scaffold body (as body-Stack children) cannot paint over the AppBar or FAB. The back arrow remains tappable behind the modal, leading to confusing or destructive taps. Outer-Stack siblings of the Scaffold paint over the entire Scaffold, including the AppBar and FAB.

**Game screen z-order** (back to front):
1. `Scaffold` (AppBar + body content)
2. `RemoveDartsModal` (conditional)
3. `DartboardEmulatorSection` (conditional)
4. `SaveGameModal` (conditional)
5. `DartboardPausedModal` (conditional, always last -- paints on top of everything)

`EditScoreDialog` is NOT an outer-Stack child -- it is a routed dialog launched via `showDialog()` which automatically paints above the entire outer Stack.

**Provider data must be hoisted to the top of `build()`** so outer-Stack modals can reference `currentPlayer`, `shouldPromptTakeout`, etc. Use `context.watch<XProvider>()` at the start of `build()` rather than inside a `Consumer<X>` builder.

## AppBar Back Button Specification

The AppBar back arrow MUST follow this canonical pattern on menu AND game screens:

```dart
leading: IconButton(
  key: YourGameMenuKeys.backButton,
  icon: const Icon(Icons.arrow_back, color: specTextColor, size: 32),
  onPressed: () => Navigator.of(context).pop(),
  hoverColor: Colors.transparent,
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
),
```

- Icon size MUST be 32 (matches all 5 existing games)
- All three hover-suppression properties MUST be `Colors.transparent` (tablet/touch UX)
- Results screen MUST NOT have a back arrow -- set `automaticallyImplyLeading: false`

## Mandatory Test Requirements

This is the centralized checklist of ALL required tests for every new game. Implementers should verify all items in one place:

### Navigation Tests (4 tests in `integration_test/your_game/navigation/`)
- [ ] `menu_back_to_home_test.dart` -- back arrow on menu returns to home with >=3 game cards
- [ ] `game_back_settings_persist_test.dart` -- back from game preserves non-default settings
- [ ] `change_settings_back_to_home_test.dart` -- Change Settings then back to home
- [ ] `change_settings_preserves_settings_test.dart` -- Change Settings preserves settings

### Results Screen Tests (3 tests in `integration_test/your_game/results_screen/`)
- [ ] Exit button navigates to game selection (assert >=3 game cards, use `popUntil route.isFirst`)
- [ ] `winner_stats_updated_test.dart` -- winner `gamesWon == 1`, loser `gamesWon == 0`
- [ ] `victory_music_initialized_test.dart` -- `VictoryMusicService().isInitialized == true`

### Edit Score Tests (2 tests in `integration_test/your_game/edit_score/`)
- [ ] `edit_creates_winner_stats_test.dart` -- edit darts to winning values, verify stats updated
- [ ] `edit_removes_winner_no_stats_test.dart` -- edit winning darts to non-winning, verify game continues

### Play-to-Complete Tests (in `integration_test/your_game/play_to_complete/`)
- [ ] `default_settings_test.dart` -- default settings complete successfully
- [ ] One test per game-critical setting
- [ ] `mid_game_test.dart` -- manual darts first, then auto-complete

### Player Count Tests (2 tests in `integration_test/your_game/gameplay/`)
- [ ] `min_player_count_test.dart` -- spec minimum players, all UI elements render
- [ ] `max_player_count_test.dart` -- spec maximum players, no overflow or layout errors

### Opponent Display Test (1 test in `integration_test/your_game/gameplay/`)
- [ ] `opponent_display_test.dart` -- inactive players visible, per-opponent state updates after turn

### Game With Announcements Test (1 test in `test/screens/games/your_game/`)
- [ ] `your_game_game_with_announcements_test.dart` -- full game flow with announcements (~18 tests)

### Pause Modal Tests (3 tests in `integration_test/your_game/pause_modal/`)
- [ ] `menu_pause_test.dart` -- dartboard disconnect on menu screen
- [ ] `gameplay_pause_test.dart` -- dartboard disconnect during gameplay
- [ ] `results_pause_test.dart` -- dartboard disconnect on results screen

### Visual Validation (in `integration_test/your_game/visual_validation/`)
- [ ] Screenshot test (1 file using `test_driver/screenshot_test.dart`)
- [ ] At least 4 programmatic visual state tests:
  - [ ] Dart indicator state test
  - [ ] Active player highlight test
  - [ ] Score/state display threshold test
  - [ ] Conditional UI element test

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
