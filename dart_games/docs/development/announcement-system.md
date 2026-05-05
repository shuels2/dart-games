# Announcement System Integration

## Overview

**ALL games MUST use the global `GameAnnouncementQueueService` for announcements.**

The announcement system provides:
- Priority-based announcement queuing
- Prevents announcement overlap
- Optional sound effects
- Uses global `DartAnnouncerService` for voice output
- Respects user's announcer settings (voice, personality, enabled/disabled)

## Architecture

```
Game Screen
    ↓
Game-Specific Announcement Helper (convenience methods)
    ↓
GameAnnouncementQueueService (global queue)
    ↓
DartAnnouncerService (voice output)
    ↓
Browser TTS or ResponsiveVoice
```

## Integration Pattern

### Step 1: Create Game-Specific Announcement Helper

**File:** `lib/services/[game_name]_announcement_helper.dart`

```dart
import 'game_announcement_queue_service.dart';
import '[game_name]_sound_effects.dart'; // Optional, for sound effects

class YourGameAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  YourGameAnnouncementHelper(this._queue);

  // Add game-specific convenience methods

  void announceGameStart() {
    _queue.announce(
      'Game starting',
      AudioPriority.statusChange,
      soundEffect: YourGameSoundEffects.gameStart, // Optional
    );
  }

  void announcePlayerTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: YourGameSoundEffects.turnStart, // Optional
    );
  }

  void announceScore(String playerName, int score) {
    _queue.announce(
      '$playerName scored $score points',
      AudioPriority.hitConfirm,
    );
  }

  void announceWinner(String playerName) {
    _queue.announce(
      'Congratulations $playerName, you win!',
      AudioPriority.victory,
      soundEffect: YourGameSoundEffects.victory, // Optional
    );
  }

  void dispose() {
    _queue.dispose();
  }
}
```

### Step 2: Initialize Helper in Game Screen

**File:** `lib/screens/games/[game_name]/[game_name]_game_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../../services/game_announcement_queue_service.dart';
import '../../../services/[game_name]_announcement_helper.dart';

class YourGameScreen extends StatefulWidget {
  @override
  _YourGameScreenState createState() => _YourGameScreenState();
}

class _YourGameScreenState extends State<YourGameScreen> {
  YourGameAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize global queue with game-specific helper
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = YourGameAnnouncementHelper(globalQueue);

      // Optional: Announce game start
      _audioQueue?.announceGameStart();
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... build UI
  }
}
```

### Step 3: Use Helper Throughout Game

Trigger announcements in response to game events:

```dart
// Player turn starts
_audioQueue?.announcePlayerTurn(currentPlayer.name);

// Score update
_audioQueue?.announceScore(player.name, score);

// Game over
_audioQueue?.announceWinner(winner.name);
```

## Priority Levels

The announcement queue uses five priority levels (lower number = higher priority):

### 1. turnTransition (Priority 1) - Highest Priority
**Usage:** Turn start/end announcements

**Examples:**
```dart
_queue.announce(
  '$playerName, your turn',
  AudioPriority.turnTransition,
);
```

### 2. hitConfirm (Priority 2)
**Usage:** Immediate feedback for dart throws

**Examples:**
```dart
_queue.announce(
  'Triple 20!',
  AudioPriority.hitConfirm,
);
```

### 3. shieldStatus (Priority 3)
**Usage:** Status changes (shields, tagged-in, special states)

**Examples:**
```dart
_queue.announce(
  '$playerName gained a shield',
  AudioPriority.shieldStatus,
);
```

### 4. statusChange (Priority 4)
**Usage:** General game state changes

**Examples:**
```dart
_queue.announce(
  'Game mode changed to hard difficulty',
  AudioPriority.statusChange,
);
```

### 5. victory (Priority 5) - Lowest Priority
**Usage:** Game over and winner announcements

**Examples:**
```dart
_queue.announce(
  'Congratulations $winner, you win!',
  AudioPriority.victory,
);
```

### Priority Guidelines

**When to use each priority:**
- **turnTransition:** Always for turn changes (most frequent, needs to play quickly)
- **hitConfirm:** Dart throw feedback, scoring confirmations
- **shieldStatus:** Game-specific status changes (Target Tag shields, etc.)
- **statusChange:** Less urgent game state changes
- **victory:** End-of-game announcements (can wait)

## Sound Effects

Sound effects can be played simultaneously with announcements.

### Creating Sound Effects Service

**File:** `lib/services/[game_name]_sound_effects.dart`

```dart
import 'game_announcement_queue_service.dart';

class YourGameSoundEffects {
  static const String _basePath = 'assets/games/your_game/sounds/';

  static const SoundEffectConfig gameStart = SoundEffectConfig(
    assetPath: '${_basePath}GameStart.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Use entire file
  );

  static const SoundEffectConfig turnStart = SoundEffectConfig(
    assetPath: '${_basePath}TurnStart.mp3',
    startSeconds: 0.5, // Trim first 0.5 seconds
    endSeconds: 2.0,   // End at 2.0 seconds
  );

  static const SoundEffectConfig victory = SoundEffectConfig(
    assetPath: '${_basePath}Victory.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );
}
```

### Sound Effect Trimming

Trim sound effects to remove silence or unwanted portions:

```dart
static const SoundEffectConfig sound = SoundEffectConfig(
  assetPath: '${_basePath}Sound.mp3',
  startSeconds: 0.3,  // Skip first 0.3 seconds
  endSeconds: 1.8,    // End at 1.8 seconds
);
```

**Benefits:**
- Faster playback (no silence delay)
- Better synchronization with announcements
- Smaller perceived latency

## Complete Example: Target Tag

### Announcement Helper
**File:** `lib/services/target_tag_announcement_helper.dart`

```dart
import 'game_announcement_queue_service.dart';
import 'target_tag_sound_effects.dart';

class TargetTagAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  TargetTagAnnouncementHelper(this._queue);

  void announcePlayerTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
    );
  }

  void announceShieldUp(String playerName) {
    _queue.announce(
      '$playerName gained a shield',
      AudioPriority.shieldStatus,
      soundEffect: TargetTagSoundEffects.shieldUp,
    );
  }

  void announceTaggedIn(String playerName) {
    _queue.announce(
      '$playerName is tagged in!',
      AudioPriority.statusChange,
      soundEffect: TargetTagSoundEffects.taggedIn,
    );
  }

  void announceHitOpponent(String attackerName, String targetName) {
    _queue.announce(
      '$attackerName hit $targetName!',
      AudioPriority.hitConfirm,
      soundEffect: TargetTagSoundEffects.hitOpponent,
    );
  }

  void announceEliminated(String playerName) {
    _queue.announce(
      '$playerName has been eliminated',
      AudioPriority.statusChange,
      soundEffect: TargetTagSoundEffects.eliminated,
    );
  }

  void announceWinner(String playerName) {
    _queue.announce(
      'Congratulations $playerName, you are the Target Tag champion!',
      AudioPriority.victory,
      soundEffect: TargetTagSoundEffects.victory,
    );
  }

  void dispose() {
    _queue.dispose();
  }
}
```

### Usage in Game Screen
**File:** `lib/screens/games/target_tag/target_tag_game_screen.dart`

```dart
// Initialize
TargetTagAnnouncementHelper? _audioQueue;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final globalQueue = GameAnnouncementQueueService();
    await globalQueue.loadSettings();
    _audioQueue = TargetTagAnnouncementHelper(globalQueue);
  });
}

// Use throughout game
void _processDartThrow(int score, int multiplier) {
  // ... game logic

  if (playerGainedShield) {
    _audioQueue?.announceShieldUp(player.name);
  }

  if (playerGotTaggedIn) {
    _audioQueue?.announceTaggedIn(player.name);
  }

  if (hitOpponent) {
    _audioQueue?.announceHitOpponent(currentPlayer.name, opponent.name);
  }

  if (playerEliminated) {
    _audioQueue?.announceEliminated(player.name);
  }

  if (gameWon) {
    _audioQueue?.announceWinner(winner.name);
  }
}
```

## Announcement Stacking Prevention

**During game development, always analyze announcement stacking and present optimization options to the user.**

When multiple game events occur from a single dart throw (e.g., hitting an opponent's target while gaining shields and triggering a status change), naively firing every applicable announcement creates audio overload. The goal is **max 2 announcements per dart throw**: 1 moment announcement + Remove Darts (if applicable).

### The Problem

Without precedence rules, a single dart can trigger 5-7 stacked announcements:
```
Turn → Hit → Shield Gained → Tagged In → Tag! → Tagged Out → Remove Darts
```

This creates an overwhelming audio experience where announcements queue up and play long after the dart was thrown.

### The Solution: Gather Facts, Pick Winner

Use the "gather facts, then pick single winner" pattern:

1. **Process the dart throw** and update all game state
2. **Gather facts** — collect boolean flags for every announcement-worthy event that occurred
3. **Apply precedence** — pick the single highest-priority moment and fire only that announcement
4. **Always fire Remove Darts** if applicable (not counted toward the moment limit)
5. **Always fire Turn announcement** on first dart (not counted toward the moment limit)

### Precedence Rules

Define a priority order for moment announcements. Higher-severity events suppress lower ones:

```
Highest:  Elimination (opponent eliminated)
          Vulnerable (opponent at 0 shields/HP)
          Low Shields/Critical HP (opponent near death)
          Status Change (opponent lost a status)
          Successful Attack (hit opponent, no status change)
          Player Gained Status (current player powered up)
          Player Gained Resource (shields, HP, etc.)
Lowest:   Hit/Miss (only when no secondary effect exists)
```

**Key suppression rules:**
- **Hit/Miss suppressed** when any secondary effect (shield gain, attack, status change) exists — the player can see what they threw on screen
- **Attack suppressed** when any status change (elimination, vulnerable, low shields) exists — the status change is more important
- **Player status gain suppressed** when any opponent status change exists — opponent impact takes priority

### Implementation Pattern

```dart
void _handleDartThrow(int score) {
  // 1. Process throw and update game state
  provider.processDartThrow(score);

  // 2. Gather facts
  final hasElimination = /* check if opponent eliminated */;
  final hasVulnerable = /* check if opponent at 0 shields */;
  final hasLowShields = /* check if opponent at 1 shield */;
  final hasStatusChange = /* check if opponent lost status */;
  final hasAttack = /* check if hit opponent target */;
  final hasPlayerGain = /* check if current player gained resource */;
  final hasSecondary = hasElimination || hasVulnerable || hasLowShields ||
      hasStatusChange || hasAttack || hasPlayerGain;

  // 3. Apply precedence — fire exactly 1 moment announcement
  if (hasElimination) {
    audioQueue.announceEliminated(opponentName);
  } else if (hasVulnerable) {
    audioQueue.announceVulnerable(opponentName);
  } else if (hasLowShields) {
    audioQueue.announceLowShields(opponentName);
  } else if (hasStatusChange) {
    audioQueue.announceStatusChange(opponentName);
  } else if (hasAttack) {
    audioQueue.announceAttack(opponentName);
  } else if (hasPlayerGain) {
    audioQueue.announceGain(playerName);
  } else {
    // No secondary — announce hit or miss
    audioQueue.announceHit(score);
  }

  // 4. Always fire Remove Darts if applicable
  if (provider.shouldPromptTakeout) {
    audioQueue.announceRemoveDarts(playerName);
  }
}
```

### Development Checklist

When building or modifying a game's announcement system:

- [ ] **Identify worst case** — find the dart throw that triggers the most simultaneous events
- [ ] **Count max announcements** — if more than 2 per dart (1 moment + Remove Darts), optimization is needed
- [ ] **Present options to user** — show the stacking analysis and recommend precedence rules
- [ ] **Implement precedence** — use the gather-facts-pick-winner pattern
- [ ] **Update test helper** — mirror the precedence logic in the test helper for unit testing
- [ ] **Update game screen** — apply matching precedence logic in the production game screen
- [ ] **Update test expectations** — adjust all `verifyAnnouncements` calls to reflect suppressed announcements
- [ ] **Verify Remove Darts** — the "Remove your darts" announcement must always play when applicable

### Reference Implementations

- **Target Tag:** Complex precedence with 8 priority tiers (elimination, vulnerable, low shields, tagged out, successful tag, tagged in, shield gained, hit/miss)
- **Carnival Derby:** Simple precedence — bust suppresses dart score (only change needed)
- **Monster Mash:** Precedence with healing, attack, elimination, and buff-modified announcements

### The "Remove Your Darts" Rule

**The "Remove your darts" announcement must always play.** It serves a functional purpose — telling the player to physically remove their darts from the board before the next player throws. This announcement is never suppressed by precedence rules and is not counted toward the per-dart moment limit.

### Max-2-Announcements: A Design-Time Convention

The max-2-announcements-per-dart rule is a **design-time convention** enforced by the precedence chain structure, not a runtime limiter. The game screen's `_handleDartThrow` calls exactly ONE moment announcement (via the if/else precedence chain) plus remove darts separately -- this structure inherently limits to max 2 per dart. There is no runtime counter or enforcer; if the code is structured correctly following the gather-facts-pick-winner pattern, the limit is satisfied by construction.

### Game Screen Audio Wiring Checklist

Every game screen MUST wire the announcement system following this 8-point checklist:

1. **`_audioQueue` field** typed as the game's `AnnouncementHelper?`
2. **Initialized in `_initializeGame()`** via `GameAnnouncementQueueService` + `loadSettings()`
3. **`announceGameStart()`** called after initialization
4. **First turn announced** with 2000ms delay
5. **Per-dart moment announcements** in `_handleDartThrow` (precedence chain + `isAutoPlaying` guard)
6. **Remove darts announcement** at 1500ms delay when `shouldPromptTakeout`
7. **Turn announcement** in `_handleTakeoutFinished` at 500ms delay (with `isAutoPlaying` guard)
8. **`_audioQueue?.dispose()`** in `dispose()`

## Best Practices

### DO:
✅ Create a game-specific helper with convenience methods
✅ Use appropriate priority levels
✅ Include sound effects for important events
✅ Dispose of the helper in dispose()
✅ Initialize helper in initState() with addPostFrameCallback
✅ Use optional chaining (`_audioQueue?.method()`)
✅ Analyze announcement stacking and apply precedence rules
✅ Ensure "Remove your darts" always plays

### DON'T:
❌ Use `DartAnnouncerService` directly (use queue service instead)
❌ Create multiple queue instances (use singleton pattern)
❌ Forget to dispose of the helper
❌ Use wrong priority levels
❌ Create very long announcements (keep under 5 seconds)
❌ Fire every applicable announcement per dart — use precedence to pick one

## Announcer Settings

The queue service automatically respects user settings:

### Voice Enabled/Disabled
If user has disabled announcer, all announcements are silently skipped (sound effects still play).

### Voice Engine
- **Browser Voices:** Built-in browser TTS
- **ResponsiveVoice:** External TTS API

### Personality
- **Professional:** Formal, clear
- **Excited:** Enthusiastic, energetic
- **Calm:** Relaxed, soothing
- **Funny:** Humorous, playful
- **Drill Sergeant:** Commanding, military

These settings are managed in System Settings and automatically applied to all announcements.

## Testing Announcements

### Manual Testing
1. Enable announcer in System Settings
2. Select voice engine and personality
3. Play game and listen to announcements
4. Verify correct timing and priority
5. Test with announcer disabled

### Unit Testing
```dart
test('Announcement helper triggers correct announcements', () {
  final mockQueue = MockGameAnnouncementQueueService();
  final helper = TargetTagAnnouncementHelper(mockQueue);

  helper.announcePlayerTurn('Alice');

  verify(mockQueue.announce(
    'Alice, your turn',
    AudioPriority.turnTransition,
    soundEffect: null,
  )).called(1);
});
```

## Reference Implementations

- **Target Tag:** `lib/services/target_tag_announcement_helper.dart`
- **Carnival Derby:** `lib/services/carnival_derby_announcement_helper.dart`

## Related Documentation

- [Adding New Games](adding-games.md)
- [Shared Systems - GameAnnouncementQueueService](../architecture/shared-systems.md#5-game-announcement-queue-gameannouncementqueueservice)
- [Game Template - Announcements](../games/_GAME_TEMPLATE/announcements.md)
- [Target Tag - Announcements](../games/target-tag/announcements.md)
- [Carnival Derby - Announcements](../games/carnival-derby/announcements.md)
