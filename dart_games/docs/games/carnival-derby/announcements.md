# Carnival Derby - Announcements and Sound Effects

## Announcement Helper

**Class:** `CarnivalDerbyAnnouncementHelper`
**File:** `lib/services/carnival_derby_announcement_helper.dart`

### Initialization
```dart
class _HorseRaceGameScreenState extends State<HorseRaceGameScreen> {
  CarnivalDerbyAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = CarnivalDerbyAnnouncementHelper(globalQueue);
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

#### announceTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each player's turn
**Message:** "$playerName, it's your turn"
**Sound Effect:** CarnivalDerbySoundEffects.horseraceStart

#### announceDart(int score, String multiplier)
**Priority:** hitConfirm (2)
**Triggers:** After each dart lands on the board
**Message:** Varies by multiplier type:
  - Bullseye: "Bullseye! 50 points!"
  - Outer Bull: "25. Outer bull."
  - Triple: "triple [base] for [score]" (e.g., "triple 20 for 60")
  - Double: "double [base] for [score]" (e.g., "double 15 for 30")
  - Single: "[score]" (e.g., "20")
**Sound Effect:**
  - Bullseye: CarnivalDerbySoundEffects.bullseye
  - Outer Bull: CarnivalDerbySoundEffects.outerBull
  - Triple: CarnivalDerbySoundEffects.tripleHit
  - Double: CarnivalDerbySoundEffects.doubleHit
  - Single: CarnivalDerbySoundEffects.singleHit

#### announceMiss()
**Priority:** hitConfirm (2)
**Triggers:** When a dart misses the scoring area
**Message:** "Miss"
**Sound Effect:** CarnivalDerbySoundEffects.miss

#### announceBust(String playerName)
**Priority:** statusChange (4)
**Triggers:** In Perfect Finish mode when player exceeds target score
**Message:** "$playerName, you busted and your turn is over"
**Sound Effect:** CarnivalDerbySoundEffects.bust

#### announceRemoveDarts(String playerName)
**Priority:** turnTransition (1)
**Triggers:** After 3 darts thrown or turn skipped
**Message:** "$playerName, remove your darts"
**Sound Effect:** CarnivalDerbySoundEffects.removeDarts

#### announceGameComplete()
**Priority:** victory (5)
**Triggers:** When a player reaches the target score
**Message:** "The game is complete"
**Sound Effect:** CarnivalDerbySoundEffects.gameComplete

#### announceWinner(String playerName)
**Priority:** victory (5)
**Triggers:** After game completion
**Message:** "$playerName is the winner"
**Sound Effect:** None (allows victory music to play)

## Sound Effects

**Service:** `CarnivalDerbySoundEffects`
**File:** `lib/services/carnival_derby_sound_effects.dart`
**Base Path:** `assets/games/carnival_derby/sounds/` and `assets/games/target_tag/sounds/` (shared)

### Sound Effect Inventory

#### horseraceStart
- **File:** `CarnivalDerby-HorseRace-Start.mp3`
- **Duration:** ~2.3 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when announcing player's turn
- **Priority Context:** turnTransition (1)

#### gameComplete
- **File:** `CarnivalDerby-Horse-Gallop.mp3`
- **Duration:** ~2.5 seconds
- **Trim:** Full file (0.0s to end)
- **Usage:** Played when game is complete
- **Priority Context:** victory (5)

#### removeDarts (Shared from Target Tag)
- **File:** `TargetTag-Swipe.mp3`
- **Duration:** 3.0+ seconds
- **Trim:** 0.0s to 3.0s
- **Usage:** Played when prompting player to remove darts
- **Priority Context:** turnTransition (1)

#### miss (Shared from Target Tag)
- **File:** `TargetTag-Teasing.mp3`
- **Duration:** ~1 second
- **Trim:** Full file
- **Usage:** Played when dart misses
- **Priority Context:** hitConfirm (2)

#### singleHit (Shared from Target Tag)
- **File:** `TargetTag-Spring.mp3`
- **Duration:** Full file from 3.5s
- **Trim:** 3.5s to end
- **Usage:** Played when single number is hit
- **Priority Context:** hitConfirm (2)

#### doubleHit (Shared from Target Tag)
- **File:** `TargetTag-Blink.mp3`
- **Duration:** 1.25 seconds
- **Trim:** 0.5s to 1.25s
- **Usage:** Played when double ring is hit
- **Priority Context:** hitConfirm (2)

#### tripleHit (Shared from Target Tag)
- **File:** `TargetTag-Dream.mp3`
- **Duration:** 2.0 seconds
- **Trim:** 0.0s to 2.0s
- **Usage:** Played when triple ring is hit
- **Priority Context:** hitConfirm (2)

#### bullseye (Shared from Target Tag)
- **File:** `TargetTag-Choir.mp3`
- **Duration:** ~2 seconds
- **Trim:** Full file
- **Usage:** Played when bullseye (50) is hit
- **Priority Context:** hitConfirm (2)

#### outerBull (Shared from Target Tag)
- **File:** `TargetTag-Whistle.mp3`
- **Duration:** ~1 second
- **Trim:** Full file
- **Usage:** Played when outer bull (25) is hit
- **Priority Context:** hitConfirm (2)

#### bust (Shared from Target Tag)
- **File:** `TargetTag-Ominous.mp3`
- **Duration:** ~2 seconds
- **Trim:** Full file
- **Usage:** Played when player busts in Perfect Finish mode
- **Priority Context:** statusChange (4)

### Configuration Example
```dart
class CarnivalDerbySoundEffects {
  static const String _basePath = 'games/carnival_derby/sounds/';
  static const String _targetTagPath = 'games/target_tag/sounds/';

  static const SoundEffectConfig horseraceStart = SoundEffectConfig(
    assetPath: '${_basePath}CarnivalDerby-HorseRace-Start.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );

  static const SoundEffectConfig gameComplete = SoundEffectConfig(
    assetPath: '${_basePath}CarnivalDerby-Horse-Gallop.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );

  static const SoundEffectConfig miss = SoundEffectConfig(
    assetPath: '${_targetTagPath}TargetTag-Teasing.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );
}
```

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** - Turn start/end announcements
2. **hitConfirm (2)** - Immediate feedback for dart throws
3. **shieldStatus (3)** - Not used in Carnival Derby
4. **statusChange (4)** - General game state changes (busts)
5. **victory (5)** - Game over and winner announcements

### Priority Usage in This Game
- **turnTransition:** Player turn announcements, remove darts prompts
- **hitConfirm:** All dart hit confirmations (singles, doubles, triples, bulls, misses)
- **statusChange:** Bust announcements in Perfect Finish mode
- **victory:** Game complete and winner announcements

## Voice Scripts

### Game Start
Not announced at game start. First player's turn is announced after 1 second delay.

### Player Turn
**Text:** "$playerName, it's your turn"
**Personality Variations:**
- Professional: "Alice, it's your turn"
- Excited: "Alice, it's your turn!"
- Calm: "Alice, your turn"
- Funny: "Alllllice, it's your turrrrn!"
- Drill Sergeant: "ALICE! YOUR TURN! MOVE IT!"

### Dart Hit
**Text:** Varies by multiplier (see announceDart method above)

### Player Bust
**Text:** "$playerName, you busted and your turn is over"
**Example:** "Alice, you busted and your turn is over"

### Remove Darts
**Text:** "$playerName, remove your darts"
**Example:** "Alice, remove your darts"

### Game Complete
**Text:** "The game is complete"

### Winner
**Text:** "$playerName is the winner"
**Example:** "Alice is the winner"

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announceTurn(playerName);
_audioQueue?.announceGameComplete();
```

### Announcement with Parameters
```dart
_audioQueue?.announceDart(score, multiplier);
_audioQueue?.announceBust(playerName);
```

### Conditional Announcements
```dart
if (currentPlayerBusted) {
  _audioQueue?.announceBust(player.name);
}

if (dartsThrown >= 3) {
  _audioQueue?.announceRemoveDarts(player.name);
}
```
