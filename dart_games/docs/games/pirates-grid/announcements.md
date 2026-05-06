# Pirate's Grid - Announcements and Sound Effects

## Announcement Helper

**Class:** `PiratesGridAnnouncementHelper`
**File:** `lib/services/pirates_grid_announcement_helper.dart`

### Initialization
```dart
class _PiratesGridGameScreenState extends State<PiratesGridGameScreen> {
  PiratesGridAnnouncementHelper? _audioQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalQueue = GameAnnouncementQueueService();
      await globalQueue.loadSettings();
      _audioQueue = PiratesGridAnnouncementHelper(globalQueue);
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

#### announceGameStart()
**Priority:** statusChange (4)
**Triggers:** When the game screen first loads
**Message:** "Set sail! The grid awaits, captains!"
**Sound Effect:** Ship Bell

#### announcePlayerTurn(String playerName)
**Priority:** turnTransition (1)
**Triggers:** At the start of each player's turn
**Message:** "{name}, take the helm!"
**Sound Effect:** Ship Bell

#### announceFlagPlanted(String playerName, String target)
**Priority:** hitConfirm (2)
**Triggers:** When a player successfully claims an empty cell
**Message:** "{name} plants a flag at {target}!"
**Sound Effect:** Flag Plant

#### announceSquareStolen(String playerName, String opponentName)
**Priority:** hitConfirm (2)
**Triggers:** When Steal Mode ON and a player replaces an opponent's flag
**Message:** "Mutiny! {name} steals the square from {opponent}!"
**Sound Effect:** Sword Clash

#### announceMiss()
**Priority:** hitConfirm (2)
**Triggers:** When a dart hits no valid unclaimed cell (no matching target in the grid)
**Message:** "Lost at sea! No square claimed."
**Sound Effect:** Wave Crash

#### announceAlreadyClaimed(bool isOwn)
**Priority:** hitConfirm (2)
**Triggers:** When a dart hits a cell already claimed — either by the throwing player or by the opponent when Steal Mode is OFF
**Message (own):** "Yer flag already flies there, captain!"
**Message (opponent, no steal):** "That square is defended!"
**Sound Effect:** Wave Crash (both cases)

#### announceTwoInARow(String playerName)
**Priority:** statusChange (4)
**Triggers:** When a player's flag placement creates exactly 2-in-a-row in any line (but not 3-in-a-row)
**Message:** "{name} has two in a row! One more for treasure!"
**Sound Effect:** Flag Plant

#### announceRoundVictory(String playerName)
**Priority:** victory (5)
**Triggers:** When a player achieves 3-in-a-row (round win in Best Of, or match win in Bo1)
**Message:** "Treasure found! {name} claims the map!"
**Sound Effect:** Treasure Found

#### announceRoundDraw()
**Priority:** statusChange (4)
**Triggers:** When all 9 squares are filled with no 3-in-a-row
**Message:** "A stalemate! Neither captain claims the map!"
**Sound Effect:** Wave Crash

#### announceMatchVictory(String playerName)
**Priority:** victory (5)
**Triggers:** When a player wins the required number of rounds in a Best Of 3 or 5 match
**Message:** "Captain {name} rules the seas!"
**Sound Effect:** Cannon Boom

#### announceMatchDraw()
**Priority:** statusChange (4)
**Triggers:** When all rounds in a Best Of match end in a draw (neither player wins any round)
**Message:** "The seas remain unclaimed! A true stalemate!"
**Sound Effect:** Wave Crash

#### announceRoundTransition(int roundNumber)
**Priority:** statusChange (4)
**Triggers:** Between rounds in Best Of 3 or 5, after the previous round result is displayed
**Message:** "Round {n}! Reset the grid!"
**Sound Effect:** Ship Bell

#### announceTimerExpired()
**Priority:** statusChange (4)
**Triggers:** When Speed Play timer reaches 0
**Message:** "Time's up! The wind takes yer darts!"
**Sound Effect:** Timer Tick

## Announcement Stacking Rules

**CRITICAL:** Maximum **2 announcements** per dart event (1 game-moment announcement + the unconditional Remove Darts announcement). The Remove Darts announcement is **NEVER suppressed**.

### Priority Chain (highest = fires first)
| Priority Level | Events |
|----------------|--------|
| victory (5) — highest | Match Victory, Round Victory |
| statusChange (4) | Round Draw / Match Draw, Two in a Row, Round Transition, Speed Play Timer Expired, Game Start |
| hitConfirm (2) | Flag Planted, Square Stolen, Miss, Already Claimed (own), Already Claimed (opponent) |
| turnTransition (1) | Player Turn |

### Per-Dart Stacking Order (what fires for each dart outcome)

| Outcome | Announcement 1 | Announcement 2 (always) |
|---------|---------------|------------------------|
| Steal + Match Win (Best Of) | Match Victory | Remove Darts |
| Steal + Round Win | Round Victory | Remove Darts |
| Steal + Draw | Round Draw | Remove Darts |
| Steal + Two in a Row | Square Stolen | Remove Darts |
| Steal (no special) | Square Stolen | Remove Darts |
| Flag + Match Win | Match Victory | Remove Darts |
| Flag + Round Win | Round Victory | Remove Darts |
| Flag + Draw | Round Draw | Remove Darts |
| Flag + Two in a Row | Two in a Row | Remove Darts |
| Flag Planted (no special) | Flag Planted | Remove Darts |
| Already Claimed (own) | Already Claimed (own) | Remove Darts |
| Already Claimed (opp, no steal) | Already Claimed (opponent) | Remove Darts |
| Miss | Miss | Remove Darts |

### Worst-Case Scenario (Steal + 3-in-a-row + Match Win)
Only **Match Victory** + Remove Darts fire. Round Victory and Square Stolen are both suppressed because Match Victory has higher priority and the MAX 2 rule applies.

### announceRemoveDarts Pattern
`announceRemoveDarts` is called UNCONDITIONALLY in the takeout handler — it is never conditional on any game state. This ensures players are always prompted to remove their darts regardless of what happened during the turn.

## Sound Effects

**Service:** `PiratesGridSoundEffects`
**File:** `lib/services/pirates_grid_sound_effects.dart`
**Base Path:** `assets/games/pirates_grid/sounds/`

### Sound Effect Inventory

#### Flag Plant
- **File:** `flag_plant.mp3`
- **Trim:** Full file
- **Usage:** When a flag is successfully planted in a cell; also used for Two in a Row announcement
- **Priority Context:** hitConfirm, statusChange

#### Cannon Boom
- **File:** `cannon_boom.mp3`
- **Trim:** Start 0s, End 2.0s
- **Usage:** Match Victory announcement
- **Priority Context:** victory

#### Wave Crash
- **File:** `wave_crash.mp3`
- **Trim:** Start 0s, End 5.0s
- **Usage:** Miss, Already Claimed, Round Draw, Match Draw announcements
- **Priority Context:** hitConfirm, statusChange

#### Treasure Found
- **File:** `treasure_found.mp3`
- **Trim:** Start 0s, End 1.25s
- **Usage:** Round Victory announcement
- **Priority Context:** victory

#### Ship Bell
- **File:** `ship_bell.mp3`
- **Trim:** Full file
- **Usage:** Game Start, Player Turn, Round Transition announcements
- **Priority Context:** statusChange, turnTransition

#### Sword Clash
- **File:** `sword_clash.mp3`
- **Trim:** Full file
- **Usage:** Square Stolen (Mutiny!) announcement
- **Priority Context:** hitConfirm

#### Timer Tick
- **File:** `timer_tick.mp3`
- **Trim:** Start 0s, End 2.0s
- **Usage:** Speed Play timer expired announcement; also played in-screen at 5, 4, 3, 2, 1 seconds
- **Priority Context:** statusChange

### Configuration Example
```dart
class PiratesGridSoundEffects {
  static const String _basePath = 'assets/games/pirates_grid/sounds/';

  static const SoundEffectConfig flagPlant = SoundEffectConfig(
    assetPath: '${_basePath}flag_plant.mp3',
    startSeconds: null,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig cannonBoom = SoundEffectConfig(
    assetPath: '${_basePath}cannon_boom.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );

  static const SoundEffectConfig waveCrash = SoundEffectConfig(
    assetPath: '${_basePath}wave_crash.mp3',
    startSeconds: 0.0,
    endSeconds: 5.0,
  );

  static const SoundEffectConfig treasureFound = SoundEffectConfig(
    assetPath: '${_basePath}treasure_found.mp3',
    startSeconds: 0.0,
    endSeconds: 1.25,
  );

  static const SoundEffectConfig shipBell = SoundEffectConfig(
    assetPath: '${_basePath}ship_bell.mp3',
    startSeconds: null,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig swordClash = SoundEffectConfig(
    assetPath: '${_basePath}sword_clash.mp3',
    startSeconds: null,
    endSeconds: null, // Full file
  );

  static const SoundEffectConfig timerTick = SoundEffectConfig(
    assetPath: '${_basePath}timer_tick.mp3',
    startSeconds: 0.0,
    endSeconds: 2.0,
  );
}
```

## Priority Levels

The announcement queue uses the following priority levels (lower number = higher priority):

1. **turnTransition (1)** — Player turn start announcement
2. **hitConfirm (2)** — Immediate dart hit feedback (Flag Planted, Stolen, Miss, Already Claimed)
3. **statusChange (4)** — Game state changes (Two in a Row, Round Draw, Round Transition, etc.)
4. **victory (5)** — Round and match win announcements

### Priority Usage in Pirate's Grid
- **turnTransition:** Only `announcePlayerTurn` — fires at the very start of each player's turn
- **hitConfirm:** All per-dart outcomes (flag planted, stolen, miss, already claimed)
- **statusChange:** Two in a Row, all draw variants, round transition, game start, timer expired
- **victory:** Round win (`announceRoundVictory`) and match win (`announceMatchVictory`)

## Voice Scripts

### Game Start
**Text:** "Set sail! The grid awaits, captains!"

### Player Turn
**Text:** "{name}, take the helm!"

### Flag Planted
**Text:** "{name} plants a flag at {target}!"

### Square Stolen
**Text:** "Mutiny! {name} steals the square from {opponent}!"

### Miss
**Text:** "Lost at sea! No square claimed."

### Already Claimed — Own Cell
**Text:** "Yer flag already flies there, captain!"

### Already Claimed — Opponent, No Steal
**Text:** "That square is defended!"

### Two in a Row
**Text:** "{name} has two in a row! One more for treasure!"

### Round Victory
**Text:** "Treasure found! {name} claims the map!"

### Round Draw
**Text:** "A stalemate! Neither captain claims the map!"

### Match Victory (Best Of 3/5)
**Text:** "Captain {name} rules the seas!"

### Match Draw (Best Of, rare)
**Text:** "The seas remain unclaimed! A true stalemate!"

### Round Transition
**Text:** "Round {n}! Reset the grid!"

### Speed Play Timer Expired
**Text:** "Time's up! The wind takes yer darts!"

## Audio Integration Pattern

### Basic Announcement
```dart
_audioQueue?.announceFlagPlanted(playerName, targetLabel);
```

### Conditional Announcement (Steal Mode)
```dart
if (game.stealModeEnabled && cellWasStolen) {
  _audioQueue?.announceSquareStolen(playerName, opponentName);
} else {
  _audioQueue?.announceFlagPlanted(playerName, targetLabel);
}
```

### Win Detection Chain
```dart
if (game.isMatchOver) {
  _audioQueue?.announceMatchVictory(winnerId);
} else if (game.isRoundOver) {
  _audioQueue?.announceRoundVictory(winnerId);
} else if (game.isRoundDraw) {
  _audioQueue?.announceRoundDraw();
} else if (checker.hasTwoInARow(game.grid, activePlayerId)) {
  _audioQueue?.announceTwoInARow(playerName);
} else {
  _audioQueue?.announceFlagPlanted(playerName, targetLabel);
}
```
