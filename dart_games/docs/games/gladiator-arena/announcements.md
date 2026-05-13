# Gladiator Arena - Announcements and Sound Effects

## Announcement Helper

**Class:** `GladiatorArenaAnnouncementHelper`
**File:** `lib/services/gladiator_arena_announcement_helper.dart`

### Initialization
```dart
class _GladiatorArenaGameScreenState extends State<GladiatorArenaGameScreen> {
  GladiatorArenaAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = GladiatorArenaAnnouncementHelper(globalQueue);
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

#### announceGameStart(int targetScore)
**Priority:** statusChange (4)
**Triggers:** Game screen `initState` after provider is ready
**Message:** "Gladiators, enter the arena! Race to {targetScore}!"
**Sound Effect:** TrumpetFanfare

#### announcePlayerTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** Start of each player's turn (after takeout completes)
**Message:** "{playerName}, step into the arena!"
**Sound Effect:** TurnBell

#### announceSmallHit(String playerName, int points)
**Priority:** hitConfirm (2)
**Triggers:** After a dart scores 1–19 points
**Message:** "{playerName} scores {points} points."
**Sound Effect:** SwordClash

#### announceGoodHit(int points)
**Priority:** hitConfirm (2)
**Triggers:** After a dart scores 20–39 points (not triple, not bull)
**Message:** "A mighty strike! {points} points!"
**Sound Effect:** SwordClash

#### announceGreatHit(int points)
**Priority:** hitConfirm (2)
**Triggers:** After a dart scores 40+ points (not triple, not bull)
**Message:** "The crowd goes wild! {points} points!"
**Sound Effect:** CrowdCheer

#### announceTripleHit(int points)
**Priority:** hitConfirm (2)
**Triggers:** After a dart lands on a triple segment
**Message:** "A triple! {points} glory points!"
**Sound Effect:** CrowdCheer

#### announceBullHit()
**Priority:** hitConfirm (2)
**Triggers:** After a dart hits inner bull (Bullseye, 50 pts)
**Message:** "Bullseye! 50 glory points!"
**Sound Effect:** CrowdCheer

#### announceOuterBullHit()
**Priority:** hitConfirm (2)
**Triggers:** After a dart hits outer bull (25 pts)
**Message:** "Outer bull! 25 glory points!"
**Sound Effect:** SwordClash

#### announceMiss()
**Priority:** hitConfirm (2)
**Triggers:** After a dart scores 0 (miss)
**Message:** "The dart finds only sand!"
**Sound Effect:** MissThud

#### announceKnockoff(String victimName)
**Priority:** shieldStatus (3)
**Triggers:** After a knockoff resets a victim's score
**Message:** "{victimName} is knocked off! Back to zero!"
**Sound Effect:** CrowdGasp

#### announceShieldBlock(String protectedName)
**Priority:** shieldStatus (3)
**Triggers:** When a knockoff would have occurred but Shield Round is active
**Message:** "Shields up! {protectedName} is protected!"
**Sound Effect:** ShieldBlock

#### announceBustOvershoot(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** After a turn where the prospective score exceeded the target (Double Finish ON only)
**Message:** "{playerName} overshoots! Score unchanged!"
**Sound Effect:** CrowdGasp

#### announceBustNoDouble(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** After a turn where the final dart reached the target but was not a double (Double Finish ON only)
**Message:** "Not a double! The champion must earn their laurel!"
**Sound Effect:** CrowdGasp

#### announceVictoryDoubleFinish(String playerName)
**Priority:** victory (5)
**Triggers:** When a player wins with Double Finish ON
**Message:** "A champion's strike! {playerName} finishes on a double!"
**Sound Effect:** TrumpetFanfare

#### announceVictoryStandard(String playerName, int score)
**Priority:** victory (5)
**Triggers:** When a player wins with Double Finish OFF
**Message:** "{playerName} reaches glory at {score}!"
**Sound Effect:** TrumpetFanfare

#### announceNearVictory(String playerName)
**Priority:** statusChange (4)
**Triggers:** When a player's score comes within 40 of the target
**Message:** "{playerName} is close to glory!"
**Sound Effect:** TrumpetFanfare

#### announceDoubleRange(String playerName)
**Priority:** statusChange (4)
**Triggers:** When a player's score enters double-finish range (Double Finish ON only)
**Message:** "{playerName} enters double range!"
**Sound Effect:** SwordClash

#### announceShieldRoundStart()
**Priority:** statusChange (4)
**Triggers:** At the start of each Shield Round (every 5th round, when Shield Round option is ON)
**Message:** "Shield round! The arena grants mercy!"
**Sound Effect:** ShieldBlock

#### announceSpeedTimerWarning()
**Priority:** statusChange (4)
**Triggers:** When Speed Play timer reaches 5 seconds remaining
**Message:** "The sands are running out!"
**Sound Effect:** TimerTick

#### announceSpeedTimerExpired()
**Priority:** statusChange (4)
**Triggers:** When Speed Play timer reaches 0
**Message:** "Time! The arena waits for no one!"
**Sound Effect:** TurnBell

#### announceRemoveDarts()
**Priority:** turnTransition (1)
**Triggers:** Always fires at end of every turn, unconditionally (regardless of other announcements)
**Message:** "Remove your darts."
**Sound Effect:** (none — uses default remove-darts audio if configured)

## Announcement Priority and Stacking Rules

The announcement queue enforces a maximum of **2 announcements per dart-throw event**. The "Remove your darts" end-of-turn prompt ALWAYS fires regardless of the other 2 slots. The precedence chain (highest priority first) when multiple events compete:

1. **Victory** — Champion announced (game-ending)
2. **Knockoff** — Victim reset to zero
3. **Shield Block** — Knockoff was blocked by Shield Round
4. **Bust (overshoot)** — Turn voided, score above target
5. **Bust (no double)** — Turn voided, reached target without a double
6. **Bull inner** — Bullseye, 50 points
7. **Bull outer** — Outer bull, 25 points
8. **Triple** — Triple segment hit
9. **Great Hit** — 40+ points
10. **Good Hit** — 20–39 points
11. **Small Hit** — 1–19 points
12. **Miss** — 0 points

`announceRemoveDarts()` fires unconditionally at the end of every turn, outside the 2-slot cap. It always plays.

## Sound Effects

**Service:** `GladiatorArenaSoundEffects`
**File:** `lib/services/gladiator_arena_sound_effects.dart`
**Base Path:** `assets/games/gladiator_arena/sounds/`

### Sound Effect Inventory

#### SwordClash
- **File:** `GladiatorArena-SwordClash.mp3`
- **Trim:** Full file
- **Usage:** Small hits (1–19), good hits (20–39), outer bull, double-range announcement
- **Priority Context:** hitConfirm / statusChange

#### CrowdCheer
- **File:** `GladiatorArena-CrowdCheer.mp3`
- **Trim:** Full file
- **Usage:** Great hits (40+), triple hits, inner bull
- **Priority Context:** hitConfirm

#### CrowdGasp
- **File:** `GladiatorArena-CrowdGasp.mp3`
- **Trim:** 0s to 1.5s
- **Usage:** Knockoff, overshoot bust, no-double bust
- **Priority Context:** shieldStatus / hitConfirm

#### ShieldBlock
- **File:** `GladiatorArena-ShieldBlock.mp3`
- **Trim:** Full file
- **Usage:** Shield block announcement, shield round start
- **Priority Context:** shieldStatus / statusChange

#### TrumpetFanfare
- **File:** `GladiatorArena-TrumpetFanfare.mp3`
- **Trim:** Full file
- **Usage:** Game start, near victory, victory announcements
- **Priority Context:** statusChange / victory

#### TurnBell
- **File:** `GladiatorArena-TurnBell.mp3`
- **Trim:** 0s to 4.0s
- **Usage:** Player turn announcement, speed play timer expired
- **Priority Context:** turnTransition / statusChange

#### MissThud
- **File:** `GladiatorArena-MissThud.mp3`
- **Trim:** Full file
- **Usage:** Miss announcement (dart scores 0)
- **Priority Context:** hitConfirm

#### TimerTick
- **File:** `GladiatorArena-TimerTick.mp3`
- **Trim:** 0s to 2.0s
- **Usage:** Speed Play timer warning (at 5 seconds remaining)
- **Priority Context:** statusChange

### Configuration
```dart
class GladiatorArenaSoundEffects {
  static const String _basePath = 'assets/games/gladiator_arena/sounds/';

  static const SoundEffectConfig swordClash = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-SwordClash.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig crowdCheer = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-CrowdCheer.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig crowdGasp = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-CrowdGasp.mp3',
    startSeconds: 0.0,
    endSeconds: 1.5,
  );

  static const SoundEffectConfig shieldBlock = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-ShieldBlock.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig trumpetFanfare = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TrumpetFanfare.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig turnBell = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TurnBell.mp3',
    startSeconds: 0.0,
    endSeconds: 4.0,
  );

  static const SoundEffectConfig missThud = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-MissThud.mp3',
    startSeconds: null,
    endSeconds: null,
  );

  static const SoundEffectConfig timerTick = SoundEffectConfig(
    assetPath: '${_basePath}GladiatorArena-TimerTick.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );
}
```

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announcePlayerTurn(playerName);
```

### Conditional Announcements (example: post-turn evaluation)
```dart
if (provider.hasWinner) {
  if (provider.doubleFinishEnabled) {
    _audioQueue?.announceVictoryDoubleFinish(provider.winnerName);
  } else {
    _audioQueue?.announceVictoryStandard(provider.winnerName, provider.winnerScore);
  }
} else if (provider.lastKnockoffVictim != null) {
  _audioQueue?.announceKnockoff(provider.lastKnockoffVictim!);
} else if (provider.lastTurnWasBust) {
  if (provider.lastBustWasOvershoot) {
    _audioQueue?.announceBustOvershoot(currentPlayerName);
  } else {
    _audioQueue?.announceBustNoDouble(currentPlayerName);
  }
}
```

### Remove Darts (always fires)
```dart
_audioQueue?.announceRemoveDarts();
```
