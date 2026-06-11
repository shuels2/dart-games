# Treasure Divide - Announcements and Sound Effects

## Announcement Helper

**Class:** `TreasureDivideAnnouncementHelper`
**File:** `lib/services/treasure_divide_announcement_helper.dart`

### Initialization

```dart
class _TreasureDivideGameScreenState extends State<TreasureDivideGameScreen> {
  TreasureDivideAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = TreasureDivideAnnouncementHelper(globalQueue);
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

### Announcement Methods

#### announceGameStart(int rounds)
**Priority:** statusChange (4)
**Triggers:** When the game screen first loads after SET SAIL
**Message:** "Set sail! {rounds} islands to plunder!"
**Sound Effect:** Map Unfurl

#### announceNewRound(int round, dynamic target)
**Priority:** statusChange (4)
**Triggers:** At the start of each new round (non-custom)
**Message:** "Island {round}: Target is {target}!"
**Sound Effect:** Map Unfurl
**Special round variants:**
- Any Double round → also fires `announceDoubleRound()`
- Any Triple round → also fires `announceTripleRound()`
- Bull round → also fires `announceBullRound()`
- Last round → also fires `announceLastRound()`

#### announceCustomTargetReveal(int round, dynamic target)
**Priority:** statusChange (4)
**Triggers:** At the start of each round when Custom Targets is ON
**Message:** "The map reveals... {target}!"
**Sound Effect:** Map Unfurl

#### announcePlayerTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each player's turn (Solo mode)
**Message:** "{playerName}, grab your darts!"
**Sound Effect:** Turn Bell

#### announceCrewTurn(String crewName, String firstPlayerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each crew's turn (Team mode — fires for the first player in the crew)
**Message:** "The {crewName} are up — {firstPlayerName}, grab yer darts!"
**Sound Effect:** Turn Bell

#### announceHitTarget(int value)
**Priority:** hitConfirm (2)
**Triggers:** Per-dart, when a dart hits the current round's target (standard hit)
**Message:** "Plunder! {value} gold coins!"
**Sound Effect:** Coin Clink

#### announceBigHit(int value)
**Priority:** hitConfirm (2)
**Triggers:** Per-dart, when a dart hits with a triple multiplier (not on Bull round — see Bull Hit)
**Message:** "Triple treasure! {value} gold!"
**Sound Effect:** Coin Shower

#### announceBullHit(int value)
**Priority:** hitConfirm (2)
**Triggers:** Per-dart, when a dart hits during the Bull round (inner or outer bull)
**Message:** "X marks the spot! {value} gold!"
**Sound Effect:** Coin Shower

#### announceMiss()
**Priority:** hitConfirm (2)
**Triggers:** Per-dart, when a dart misses the current round's target
**Message:** "Splash! That one's in the ocean!"
**Sound Effect:** Miss Splash

#### announceScoreHalved()
**Priority:** statusChange (4)
**Triggers:** After all darts are thrown and the player/crew missed all (Quarter It OFF)
**Message:** "Treasure overboard! Half the loot is gone!"
**Sound Effect:** Splash

#### announceScoreQuartered()
**Priority:** statusChange (4)
**Triggers:** After all darts are thrown and the player/crew missed all (Quarter It ON)
**Message:** "A storm hits! Three-quarters of the treasure is lost!"
**Sound Effect:** Quarter Storm

#### announceSafe()
**Priority:** statusChange (4)
**Triggers:** After all darts are thrown and at least one hit was scored (player/crew is safe)
**Message:** "The treasure holds! Moving on!"
**Sound Effect:** Coin Clink

#### announceDoubleRound()
**Priority:** statusChange (4)
**Triggers:** At the start of Any Double round (fires alongside announceNewRound)
**Message:** "Double Doubloon round! Hit any double!"
**Sound Effect:** Map Unfurl

#### announceTripleRound()
**Priority:** statusChange (4)
**Triggers:** At the start of Any Triple round
**Message:** "Triple Treasure round! Hit any triple!"
**Sound Effect:** Map Unfurl

#### announceBullRound()
**Priority:** statusChange (4)
**Triggers:** At the start of Bull round
**Message:** "Treasure Island! Hit the bullseye!"
**Sound Effect:** Map Unfurl

#### announceLastRound()
**Priority:** statusChange (4)
**Triggers:** At the start of the final round (before Bull round fires, if different)
**Message:** "Final island! Last chance for treasure!"
**Sound Effect:** Map Unfurl

#### announceHighScoreLeader(String playerName, int score)
**Priority:** statusChange (4)
**Triggers:** After round resolution when the current leader changes or extends lead
**Message:** "{playerName} leads with {score} gold!"
**Sound Effect:** Coin Shower

#### announceVictory(String playerName)
**Priority:** victory (5)
**Triggers:** ONLY from `_handleGameWon()` in the game screen when `hasWinner` becomes true (Solo)
**Message:** "{playerName} is crowned Pirate Captain! Richest on the seas!"
**Sound Effect:** Victory Fanfare

#### announceCrewPlunder(String crewName, int value)
**Priority:** statusChange (4)
**Triggers:** When a crew banks a positive haul (at least one crew member hit) — Team mode
**Message:** "The {crewName} haul in {value} gold!"
**Sound Effect:** Coin Shower

#### announceCrewWipeout(String crewName)
**Priority:** statusChange (4)
**Triggers:** When ALL darts from ALL crew members miss the target (whole crew misses) — Team mode
**Message:** "All hands lost! The {crewName}'s treasure spills overboard!"
**Sound Effect:** Splash

#### announceTeamVictory(String crewName)
**Priority:** victory (5)
**Triggers:** ONLY from `_handleGameWon()` when `hasWinner` becomes true (Team mode)
**Message:** "The {crewName} are crowned Captain's Crew! Richest on the seas!"
**Sound Effect:** Victory Fanfare

## Sound Effects

**Service:** `TreasureDivideSoundEffects`
**File:** `lib/services/treasure_divide_sound_effects.dart`
**Base Path:** `assets/games/treasure_divide/sounds/`

### Sound Effect Inventory

#### Coin Clink
- **File:** `TreasureDivide-CoinClink.mp3`
- **Trim:** 0s to 0.24s
- **Usage:** Standard hit on target, Safe announcement
- **Priority Context:** hitConfirm (2)

#### Coin Shower
- **File:** `TreasureDivide-CoinClink.mp3` (same file, different trim)
- **Trim:** 2.0s to 3.0s
- **Usage:** Triple/bull hits, crew plunder, high score leader
- **Priority Context:** hitConfirm (2) / statusChange (4)

#### Splash
- **File:** `TreasureDivide-Splash.mp3`
- **Trim:** 0.5s to 2.0s, 500ms fade-out
- **Usage:** Score halved, crew wipeout
- **Priority Context:** statusChange (4)

#### Map Unfurl
- **File:** `TreasureDivide-MapUnfurl.mp3`
- **Trim:** 0s to 1.25s, 500ms fade-out
- **Usage:** Game start, new round, special rounds (Double/Triple/Bull/Last Round), custom reveal
- **Priority Context:** statusChange (4)

#### Miss Splash
- **File:** `TreasureDivide-MissSplash.mp3`
- **Trim:** 0s to 0.2s
- **Usage:** Single dart miss
- **Priority Context:** hitConfirm (2)

#### Turn Bell
- **File:** `TreasureDivide-Bell.mp3`
- **Trim:** 0s to 0.1s, 250ms fade-out
- **Usage:** Player turn / crew turn start
- **Priority Context:** turnTransition (1)

#### Victory Fanfare
- **File:** `TreasureDivide-Fanfare.mp3`
- **Trim:** 0s to 4.0s, 500ms fade-out
- **Usage:** Victory (Solo and Team)
- **Priority Context:** victory (5)

#### Quarter Storm
- **File:** `TreasureDivide-Storm.mp3`
- **Trim:** 0s to 1.5s, 500ms fade-out
- **Usage:** Score quartered (Quarter It ON miss penalty)
- **Priority Context:** statusChange (4)

### Configuration Example

```dart
class TreasureDivideSoundEffects {
  static const String _basePath = 'assets/games/treasure_divide/sounds/';

  static const SoundEffectConfig coinClink = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 0.0,
    endSeconds: 0.24,
  );

  static const SoundEffectConfig coinShower = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-CoinClink.mp3',
    startSeconds: 2.0,
    endSeconds: 3.0,
  );

  static const SoundEffectConfig splash = SoundEffectConfig(
    assetPath: '${_basePath}TreasureDivide-Splash.mp3',
    startSeconds: 0.5,
    endSeconds: 2.0,
  );

  // ... (all 8 effects follow the same pattern)
}
```

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** — Turn start / crew intro
2. **hitConfirm (2)** — Immediate per-dart feedback (Bull Hit, Big Hit, Hit Target, Miss)
3. **statusChange (4)** — Round-resolution and game-state changes
4. **victory (5)** — Game over and winner announcements

### Per-Dart Precedence Chain

When multiple events fire simultaneously for a single dart:

1. **Bull Hit** — highest per-dart priority (Bull round + inner/outer bull)
2. **Big Hit (Triple)** — triple multiplier hit (not Bull round)
3. **Hit Target** — standard hit on the target
4. **Miss** — dart missed the target

Then at turn/round end:
- **Solo:** Quartered > Halved > Safe
- **Team Crew Wipeout** > Crew Plunder

At round transition:
- **Last Round** > Bull Round > Triple Round > Double Round > Custom Reveal > Standard New Round

**Victory** fires only from `_handleGameWon()` and always takes precedence over all other simultaneous announcements.

**Maximum 2 announcements per event:** The "Remove your darts" end-of-turn announcement ALWAYS plays and does not count against the budget.

## Audio Integration Pattern

### Basic dart-hit announcement

```dart
// Per-dart — called from the dart throw handler
if (isBullRound && isBullHit) {
  _audioQueue?.announceBullHit(value);
} else if (multiplier == 3) {
  _audioQueue?.announceBigHit(value);
} else if (isHit) {
  _audioQueue?.announceHitTarget(value);
} else {
  _audioQueue?.announceMiss();
}
```

### Round-end announcement

```dart
// After all players complete the round
if (playerWasHalved && quarterItEnabled) {
  _audioQueue?.announceScoreQuartered();
} else if (playerWasHalved) {
  _audioQueue?.announceScoreHalved();
} else {
  _audioQueue?.announceSafe();
}
```

### Victory (always from _handleGameWon)

```dart
void _handleGameWon() {
  if (provider.isTeamMode) {
    _audioQueue?.announceTeamVictory(provider.winningCrewName);
  } else {
    _audioQueue?.announceVictory(provider.winnerName);
  }
  // Navigate to results screen
}
```
