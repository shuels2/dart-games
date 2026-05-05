# Lunar Lander - Announcements and Sound Effects

## Announcement Helper

**Class:** `LunarLanderAnnouncementHelper`
**File:** `lib/services/lunar_lander_announcement_helper.dart`

### Initialization

```dart
class _LunarLanderGameScreenState extends State<LunarLanderGameScreen> {
  LunarLanderAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = LunarLanderAnnouncementHelper(globalQueue);
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

## Announcement Events

All 10 announcement event types are listed below with their priority, trigger condition, example text, and sound effect.

### 1. announceGameStart(int startingAltitude)
**Priority:** statusChange
**Triggers:** When the game screen initializes (first turn start)
**Message:** `"Mission control, altitude $startingAltitude! Begin descent!"`
**Sound Effect:** MissionControl

### 2. announcePlayerTurn(String playerName)
**Priority:** turnTransition
**Triggers:** At the start of each player's turn (after the previous turn's Remove Darts)
**Message:** `"$playerName, you have the controls!"`
**Sound Effect:** RadioBeep

### 3. announceStandardDescent(String playerName, int descended, int altitude)
**Priority:** hitConfirm
**Triggers:** When a dart scores 1-39 points (non-zero, non-big descent)
**Message:** `"$playerName descends $descended! Altitude: $altitude!"`
**Sound Effect:** ThrusterBurn

### 4. announceBigDescent(String playerName, int descended, int altitude)
**Priority:** hitConfirm
**Triggers:** When a dart scores 40 or more points
**Message:** `"Major burn! $playerName drops $descended! Altitude: $altitude!"`
**Sound Effect:** ThrusterBurn

### 5. announceMiss(String playerName)
**Priority:** hitConfirm
**Triggers:** When a dart scores 0 (miss)
**Message:** `"$playerName drifts in orbit!"`
**Sound Effect:** DriftSound

### 6. announceNearLanding(String playerName, int altitude)
**Priority:** statusChange
**Triggers:** When the player's altitude drops to 20 or below (but still above 0) after a dart
**Message:** `"Final approach! $playerName at altitude $altitude!"`
**Sound Effect:** WarningAlarm

### 7. announceCrashLanding(String playerName, int revertedAltitude)
**Priority:** hitConfirm
**Triggers:** When a dart brings altitude below 0 AND Hard Landing is ON (bust)
**Message:** `"Crash landing! $playerName pulls back to $revertedAltitude!"`
**Sound Effect:** CrashLanding

### 8. announceNegativeAltitude(String playerName, int altitude)
**Priority:** hitConfirm
**Triggers:** When a dart brings altitude below 0 AND Hard Landing is OFF (the altitude is now negative but not a win — only occurs mid-turn before game ends, e.g., if somehow a dart after an already-negative altitude)
**Message:** `"$playerName overshot! Altitude: $altitude!"`
**Sound Effect:** CrashLanding

### 9. announceClimbingBack(String playerName, int altitude)
**Priority:** hitConfirm
**Triggers:** When a dart reduces the magnitude of a negative altitude (e.g., altitude goes from -10 to -5)
**Message:** `"$playerName is climbing back! Altitude: $altitude!"`
**Sound Effect:** ThrusterBurn

### 10. announceTouchdown(String playerName)
**Priority:** victory
**Triggers:** When a player reaches altitude 0 or below (wins the game)
**Message:** `"Touchdown! $playerName lands on the moon!"`
**Sound Effects:** Touchdown + VictoryFanfare (two sounds queued together)

### 11. announceRemoveDarts()
**Priority:** hitConfirm (end-of-turn)
**Triggers:** UNCONDITIONALLY at the end of every turn (after 3 darts, a bust, a skip, or a win)
**Message:** `"Remove your darts"`
**Sound Effect:** None (voice only)

## Announcement Priority Levels

The announcement queue uses these priority levels (lower number = higher priority):

| Level | Name | Value |
|-------|------|-------|
| 1 | turnTransition | Highest |
| 2 | hitConfirm | High |
| 3 | shieldStatus | Medium (not used by Lunar Lander) |
| 4 | statusChange | Low |
| 5 | victory | Lowest |

**Note on priorities in Lunar Lander:** Lower priority number = plays sooner / wins precedence. In the stacking logic below, "highest priority" means the lowest numeric level.

## Stacking Precedence (Per Dart — Max 2 Announcements)

When a single dart throw could trigger multiple moment-type announcements, exactly **one moment announcement** is selected using this precedence chain (highest priority wins):

| Rank | Announcement | Condition |
|------|-------------|-----------|
| 1 (wins) | Touchdown | altitude <= 0, any Hard Landing setting |
| 2 | Crash Landing | altitude < 0, Hard Landing ON (bust) |
| 3 | Climbing Back | Hard Landing OFF, altitude was negative and becomes less negative |
| 4 | Negative Altitude | Hard Landing OFF, altitude first goes below 0 |
| 5 | Near Landing | altitude > 0 and <= 20 |
| 6 | Big Descent | scored >= 40 |
| 7 | Standard Descent | scored 1-39 |
| 8 (lowest) | Miss | scored 0 |

The **Remove Darts** announcement is UNCONDITIONAL — it is called outside the precedence if/else block and always plays at the end of a turn, regardless of which moment announcement won.

**Result:** Each turn event produces at most 2 announcements: (1) the highest-priority moment announcement, and (2) Remove Darts at turn end.

## Sound Effects

**Service:** `LunarLanderSoundEffects`
**File:** `lib/services/lunar_lander_sound_effects.dart`
**Base Path:** `assets/games/lunar_lander/sounds/`

### Sound Effect Inventory

#### ThrusterBurn
- **File:** `LunarLander-ThrusterBurn.mp3`
- **Trim:** Start 0.5s, end 3.0s
- **Usage:** Standard descent, big descent, climbing back announcements
- **Priority Context:** hitConfirm

#### CrashLanding
- **File:** `LunarLander-CrashLanding.mp3`
- **Trim:** Full file
- **Usage:** Crash landing (Hard Landing ON bust) and negative altitude (Hard Landing OFF overshoot) announcements
- **Priority Context:** hitConfirm

#### RadioBeep
- **File:** `LunarLander-RadioBeep.mp3`
- **Trim:** Full file
- **Usage:** Player turn announcement
- **Priority Context:** turnTransition

#### Touchdown
- **File:** `LunarLander-Touchdown.mp3`
- **Trim:** Full file
- **Usage:** Victory announcement (plays together with VictoryFanfare)
- **Priority Context:** victory

#### MissionControl
- **File:** `LunarLander-MissionControl.mp3`
- **Trim:** Start 0s, end 1.25s
- **Usage:** Game start announcement
- **Priority Context:** statusChange

#### WarningAlarm
- **File:** `LunarLander-WarningAlarm.mp3`
- **Trim:** Full file
- **Usage:** Near landing announcement (altitude <= 20, > 0)
- **Priority Context:** statusChange

#### DriftSound
- **File:** `LunarLander-DriftSound.mp3`
- **Trim:** Start 1.0s, end 4.0s
- **Usage:** Miss/drift announcement (dart scores 0)
- **Priority Context:** hitConfirm

#### VictoryFanfare
- **File:** `LunarLander-VictoryFanfare.mp3`
- **Trim:** Start 0.5s, end 8.0s
- **Usage:** Victory announcement (plays together with Touchdown sound)
- **Priority Context:** victory

### Configuration Example

```dart
class LunarLanderSoundEffects {
  static const String _basePath = 'assets/games/lunar_lander/sounds/';

  static const SoundEffectConfig thrusterBurn = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-ThrusterBurn.mp3',
    startSeconds: 0.5,
    endSeconds: 3.0,
  );

  static const SoundEffectConfig crashLanding = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-CrashLanding.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig radioBeep = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-RadioBeep.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig touchdown = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-Touchdown.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig missionControl = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-MissionControl.mp3',
    startSeconds: 0.0,
    endSeconds: 1.25,
  );

  static const SoundEffectConfig warningAlarm = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-WarningAlarm.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig driftSound = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-DriftSound.mp3',
    startSeconds: 1.0,
    endSeconds: 4.0,
  );

  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}LunarLander-VictoryFanfare.mp3',
    startSeconds: 0.5,
    endSeconds: 8.0,
  );
}
```

## Audio Integration Pattern

### Precedence-based dart event announcement

```dart
// In _processDartThrow (game screen):
if (provider.hasWinner) {
  _audioQueue?.announceTouchdown(playerName);
} else if (provider.lastDartWasBust) {
  _audioQueue?.announceCrashLanding(playerName, provider.currentAltitude);
} else if (isClimbingBack) {
  _audioQueue?.announceClimbingBack(playerName, provider.currentAltitude);
} else if (isNegative) {
  _audioQueue?.announceNegativeAltitude(playerName, provider.currentAltitude);
} else if (provider.currentAltitude <= 20 && provider.currentAltitude > 0) {
  _audioQueue?.announceNearLanding(playerName, provider.currentAltitude);
} else if (dartScore >= 40) {
  _audioQueue?.announceBigDescent(playerName, dartScore, provider.currentAltitude);
} else if (dartScore > 0) {
  _audioQueue?.announceStandardDescent(playerName, dartScore, provider.currentAltitude);
} else {
  _audioQueue?.announceMiss(playerName);
}

// UNCONDITIONAL — always called, outside the if/else chain above:
_audioQueue?.announceRemoveDarts();
```

### Game Start

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _audioQueue?.announceGameStart(provider.startingAltitude);
});
```

### Player Turn

```dart
_audioQueue?.announcePlayerTurn(provider.currentPlayerName);
```
