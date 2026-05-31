# Tiki Golf - Announcements and Sound Effects

## Announcement Helper

**Class:** `TikiGolfAnnouncementHelper`
**File:** `lib/services/tiki_golf_announcement_helper.dart`

### Initialization
```dart
class _TikiGolfGameScreenState extends State<TikiGolfGameScreen> {
  TikiGolfAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = TikiGolfAnnouncementHelper(globalQueue);
    });
  }

  @override
  void dispose() {
    _audioQueue?.dispose();
    super.dispose();
  }
}
```

## Announcement Events (14 total)

| Event | Priority | Text | Sound |
|-------|----------|------|-------|
| Game Start | statusChange | "Welcome to Tiki Golf! Let's tee off!" | Ukulele Strum |
| Player Turn | turnTransition | "{name}, you're on the tee!" | Ukulele Strum |
| New Hole | statusChange | "Hole {X}: Aim for number {N}!" | Tiki Chime |
| Birdie | hitConfirm | "Birdie! {name} sinks it on the first dart!" | Crowd Clap |
| Par | hitConfirm | "Par! Solid shot, {name}!" | Ball Drop |
| Bogey | hitConfirm | "Bogey! Just squeaked that one in!" | Putt |
| Double Bogey | hitConfirm | "Double bogey! Squeaked it out, {name}!" | Putt |
| Triple Bogey | hitConfirm | "Triple bogey! Barely hung in, {name}!" | Putt |
| Quadruple Bogey | hitConfirm | "Quadruple bogey! That was a wild one, {name}!" | Putt |
| Splash | hitConfirm | "Splash! {name} misses them all!" | Splash |
| Individual Miss (not last dart) | hitConfirm | "That one went wide!" | Splash |
| Almost There (dart 1 missed) | statusChange | "{name}, one dart left to save par!" | Tiki Chime |
| Mulligan Used | statusChange | "Mulligan! {name} gets a do-over!" | Mulligan |
| Mulligan Available Reminder (on Splash) | statusChange | "Splash! Use your mulligan?" | Tiki Chime |
| Near Win (last hole) | statusChange | "Final hole! {name} leads by {X}!" | Ukulele Strum |
| Victory | victory | "{name} wins the Golden Tiki!" | Victory Fanfare |
| Hole Complete (all players done) | statusChange | "On to hole {X}!" | Tiki Chime |

> **Random-target note:** The "New Hole" announcement reads the hole's randomly-assigned target from `game.holeTargets[currentHole - 1]`. Because targets are shuffled per game, the announced number for "Hole 3" differs every round.

> **Team mode player turn:** When in Team mode, the player turn announcement includes the team name: "Sharks: Alice up to putt!" (Ukulele Strum).

## Priority Levels Used

The announcement queue uses priority levels (lower number = higher priority):

1. **turnTransition (1)** — Player turn start: "Alice, you're on the tee!" / "Sharks: Alice up to putt!"
2. **hitConfirm (2)** — Immediate dart result: Birdie, Par, Bogey, Splash, Individual Miss, Almost There
3. **statusChange (4)** — State changes: New Hole, Game Start, Mulligan Used, Mulligan Reminder, Near Win, Hole Complete
4. **victory (5)** — Game over: Victory announcement

## 11-Rank Precedence Chain

When multiple announcements would fire for the same dart event, the MAX 2 announcements rule is enforced. Ranking (1 = highest priority, fires first):

1. **Victory** — `{name} wins the Golden Tiki!` (Victory Fanfare)
2. **Birdie** — Hit on dart 1 (Crowd Clap)
3. **Mulligan Used** — After USE MULLIGAN tapped (Mulligan sound)
4. **Par** — Hit on dart 2 (Ball Drop)
5. **Bogey / Double Bogey / Triple Bogey / Quadruple Bogey** — Hit on dart 3 / 4 / 5 / 6 respectively (Putt). Per-stroke variant is selected from `holeScore`.
6. **Splash + Mulligan Reminder** — `Splash! Use your mulligan?` when mulligan available (Tiki Chime) — replaces plain Splash announcement
7. **Splash (no mulligan)** — `Splash! {name} misses them all!` (Splash)
8. **Near Win** — On last hole, leader's final announcement (Ukulele)
9. **Hole Complete** — All players finished hole (Tiki Chime)
10. **Almost There** — Dart 1 missed (next dart can still land Par) (Tiki Chime)
11. **Individual Miss** — Non-last dart miss (Splash sound, lowest priority)

**MAX 2 rule:** A single dart event fires at most 2 announcements. "Remove your darts" (end-of-turn) ALWAYS fires unconditionally and does NOT count against the 2-announcement budget.

**Auto-play suppression:** The "announceRemoveDarts" event fires unconditionally at turn end regardless of all other announcements. It is implemented as a forced push into the queue that bypasses priority ordering.

## Announcement Methods

### announceGameStart()
**Priority:** statusChange (4)
**Triggers:** Once when game screen loads
**Message:** "Welcome to Tiki Golf! Let's tee off!"
**Sound:** Ukulele Strum (full)

### announcePlayerTurn(String playerName, {String? teamName})
**Priority:** turnTransition (1)
**Triggers:** Each time the active player changes
**Message:** Solo: "{playerName}, you're on the tee!" / Team: "{teamName}: {playerName} up to putt!"
**Sound:** Ukulele Strum (full)

### announceNewHole(int holeNumber, int targetNumber)
**Priority:** statusChange (4)
**Triggers:** When current hole advances (after all players complete a hole)
**Message:** "Hole {holeNumber}: Aim for number {targetNumber}!"
**Sound:** Tiki Chime (full)

### announceBirdie(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 1
**Message:** "Birdie! {playerName} sinks it on the first dart!"
**Sound:** Crowd Clap (full)

### announcePar(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 2
**Message:** "Par! Solid shot, {playerName}!"
**Sound:** Ball Drop (0s–1.6s)

### announceBogey(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 3
**Message:** "Bogey! Just squeaked that one in!"
**Sound:** Putt (0s–0.2s)

### announceDoubleBogey(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 4 (only when Max Darts ≥ 4)
**Message:** "Double bogey! Squeaked it out, {playerName}!"
**Sound:** Putt (0s–0.2s)

### announceTripleBogey(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 5 (only when Max Darts ≥ 5)
**Message:** "Triple bogey! Barely hung in, {playerName}!"
**Sound:** Putt (0s–0.2s)

### announceQuadrupleBogey(String playerName)
**Priority:** hitConfirm (2)
**Triggers:** Player hits target on dart 6 (only when Max Darts = 6)
**Message:** "Quadruple bogey! That was a wild one, {playerName}!"
**Sound:** Putt (0s–0.2s)

> **Splash precedence:** When `holeScore == maxStrokes + 1` (target never hit), Splash always wins over any bogey-flavor announcement — e.g. at Max Darts = 3 with no hits, the player gets Splash (not Double Bogey).

### announceSplash(String playerName, {bool mulliganAvailable = false})
**Priority:** hitConfirm (2)
**Triggers:** All Max Darts thrown without hitting target
**Message (mulligan available):** "Splash! Use your mulligan?"
**Message (no mulligan):** "Splash! {playerName} misses them all!"
**Sound (mulligan available):** Tiki Chime (full) — replaces plain Splash
**Sound (no mulligan):** Splash (full)

### announceMiss()
**Priority:** hitConfirm (2)
**Triggers:** Individual dart miss that is NOT the final dart of the turn
**Message:** "That one went wide!"
**Sound:** Splash (full)

### announceAlmostThere(String playerName)
**Priority:** statusChange (4)
**Triggers:** Player has thrown 1 dart and missed — the next dart (dart 2) is still the Par dart. Fires regardless of Max Darts; later mid-turn misses fall through to Individual Miss.
**Message:** "{playerName}, one dart left to save par!"
**Sound:** Tiki Chime (full)

### announceMulliganUsed(String playerName)
**Priority:** statusChange (4)
**Triggers:** Player taps USE MULLIGAN in the Mulligan modal
**Message:** "Mulligan! {playerName} gets a do-over!"
**Sound:** Mulligan (full)

### announceNearWin(String playerName, int leadBy)
**Priority:** statusChange (4)
**Triggers:** On the last hole (hole 9), if one player/team leads the field by any amount
**Message:** "Final hole! {playerName} leads by {leadBy}!"
**Sound:** Ukulele Strum (full)

### announceVictory(String winnerName)
**Priority:** victory (5)
**Triggers:** Game ends — all players/teams complete hole 9
**Message:** "{winnerName} wins the Golden Tiki!" (Solo) / "{teamName} wins the Golden Tiki!" (Team)
**Sound:** Victory Fanfare (7.0s–11.0s trim)

### announceHoleComplete(int nextHoleNumber)
**Priority:** statusChange (4)
**Triggers:** All players/teams complete the current hole; advances to next
**Message:** "On to hole {nextHoleNumber}!"
**Sound:** Tiki Chime (full)

### announceRemoveDarts()
**Priority:** Unconditional (does not count against 2-announcement budget)
**Triggers:** Turn end detected (`currentTurnEnded || hasWinner`)
**Message:** "Remove your darts."
**Sound:** None (TTS only)

## Sound Effects

**Service:** `TikiGolfSoundEffects`
**File:** `lib/services/tiki_golf_sound_effects.dart`
**Base Path:** `assets/games/tiki_golf/sounds/`

### Sound Effect Inventory

#### Putt
- **File:** `TikiGolf-Putt.mp3`
- **Trim:** 0s–0.2s
- **Usage:** Bogey announcement (target hit on dart 3+)
- **Priority Context:** hitConfirm (2)

#### Ball Drop
- **File:** `TikiGolf-BallDrop.mp3`
- **Trim:** 0s–1.6s
- **Usage:** Par announcement (target hit on dart 2)
- **Priority Context:** hitConfirm (2)

#### Crowd Clap
- **File:** `TikiGolf-Clap.mp3`
- **Trim:** Full file
- **Usage:** Birdie announcement (target hit on dart 1)
- **Priority Context:** hitConfirm (2)

#### Ukulele Strum
- **File:** `TikiGolf-Ukulele.mp3`
- **Trim:** Full file
- **Usage:** Game start, player turn, near win announcements
- **Priority Context:** turnTransition (1) or statusChange (4)

#### Splash
- **File:** `TikiGolf-Splash.mp3`
- **Trim:** Full file
- **Usage:** Splash announcement (no mulligan), individual miss announcement
- **Priority Context:** hitConfirm (2)

#### Tiki Chime
- **File:** `TikiGolf-TikiChime.mp3`
- **Trim:** Full file
- **Usage:** New hole, almost there, mulligan reminder, hole complete announcements
- **Priority Context:** statusChange (4)

#### Victory Fanfare
- **File:** `TikiGolf-VictoryFanfare.mp3`
- **Trim:** 7.0s–11.0s
- **Usage:** Victory announcement
- **Priority Context:** victory (5)

#### Mulligan
- **File:** `TikiGolf-Mulligan.mp3`
- **Trim:** Full file
- **Usage:** Mulligan used announcement (comedic "do-over" sound)
- **Priority Context:** statusChange (4)

### Configuration Example
```dart
class TikiGolfSoundEffects {
  static const String _basePath = 'assets/games/tiki_golf/sounds/';

  static const SoundEffectConfig putt = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Putt.mp3',
    startSeconds: 0.0,
    endSeconds: 0.2,
  );

  static const SoundEffectConfig ballDrop = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-BallDrop.mp3',
    startSeconds: 0.0,
    endSeconds: 1.6,
  );

  static const SoundEffectConfig clap = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Clap.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig ukulele = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Ukulele.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig splash = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Splash.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig tikiChime = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-TikiChime.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig victoryFanfare = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-VictoryFanfare.mp3',
    startSeconds: 7.0,
    endSeconds: 11.0,
  );

  static const SoundEffectConfig mulligan = SoundEffectConfig(
    assetPath: '${_basePath}TikiGolf-Mulligan.mp3',
    startSeconds: 0.0,
    endSeconds: null, // Full file
  );
}
```

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announcePlayerTurn(playerName);
```

### Announcement with Mulligan Check
```dart
if (turnEndedAsSplash) {
  final mulliganAvail = provider.playerMulliganAvailable[currentPlayerId] ?? false;
  _audioQueue?.announceSplash(playerName, mulliganAvailable: mulliganAvail);
} else if (dartHitTarget) {
  if (dartsThrown == 1) {
    _audioQueue?.announceBirdie(playerName);
  } else if (dartsThrown == 2) {
    _audioQueue?.announcePar(playerName);
  } else {
    _audioQueue?.announceBogey();
  }
}
```

### Penultimate Dart Check
```dart
// "Almost There" fires when player is on their last-chance dart
if (dartsThrown == game.maxDarts - 1 && !hitTarget) {
  _audioQueue?.announceAlmostThere(playerName);
}
```
