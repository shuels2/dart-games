# Monster Mash - Asset Inventory

## Asset Location
**Base Path:** `assets/games/monster_mash/`

## Asset Summary
- **Characters:** 32 images (8 monsters x 4 health states)
- **Icons:** 3 files (1 main icon + 2 shield icons)
- **Images:** 2 files (background + stone texture)
- **Sounds:** 4 files (+ 7 borrowed from Target Tag)
- **Total Native Assets:** 41 files

## Characters

**Location:** `assets/games/monster_mash/characters/`

### Naming Convention
`{MonsterName}-{HealthState}.png`

### Health States
- **FullHealth** - Monster at >70% HP (vibrant, powerful appearance)
- **70Health** - Monster at 30-70% HP (showing wear, some damage)
- **30Health** - Monster at 10-30% HP (heavily damaged, weakened)
- **Eliminated** - Monster at 0% HP (defeated, faded)

### Monster Characters (8 monsters x 4 states = 32 images)

| Monster | FullHealth | 70Health | 30Health | Eliminated |
|---------|-----------|----------|----------|------------|
| Dracula | Dracula-FullHealth.png | Dracula-70Health.png | Dracula-30Health.png | Dracula-Eliminated.png |
| Frankenstein | Frankenstein-FullHealth.png | Frankenstein-70Health.png | Frankenstein-30Health.png | Frankenstein-Eliminated.png |
| Mummy | Mummy-FullHealth.png | Mummy-70Health.png | Mummy-30Health.png | Mummy-Eliminated.png |
| Wolf Man | WolfMan-FullHealth.png | WolfMan-70Health.png | WolfMan-30Health.png | WolfMan-Eliminated.png |
| Invisible Man | InvisibleMan-FullHealth.png | InvisibleMan-70Health.png | InvisibleMan-30Health.png | InvisibleMan-Eliminated.png |
| Gill Man | GillMan-FullHealth.png | GillMan-70Health.png | GillMan-30Health.png | GillMan-Eliminated.png |
| Mr. Hyde | MrHyde-FullHealth.png | MrHyde-70Health.png | MrHyde-30Health.png | MrHyde-Eliminated.png |
| Phantom | Phantom-FullHealth.png | Phantom-70Health.png | Phantom-30Health.png | Phantom-Eliminated.png |

### Image Selection Logic
```dart
String getMonsterImagePath(String monsterName, double healthPercentage) {
  if (healthPercentage <= 0) return '$monsterName-Eliminated.png';
  if (healthPercentage <= 0.30) return '$monsterName-30Health.png';
  if (healthPercentage <= 0.70) return '$monsterName-70Health.png';
  return '$monsterName-FullHealth.png';
}
```

## Icons

**Location:** `assets/games/monster_mash/icons/`

### MonsterMash-Icon.png
- **Format:** PNG with transparency
- **Usage:** Main game icon displayed on home screen game card

### Shield-Health.png
- **Format:** PNG with transparency
- **Usage:** Health shield indicator in opponent tiles and active player panel

### Shield-HitPoint.png
- **Format:** PNG with transparency
- **Usage:** Hit point/target number shield indicator

## Images

**Location:** `assets/games/monster_mash/images/`

### MonsterMash-Background.png
- **Format:** PNG
- **Usage:** Background texture for menu screen

### stone-texture.png
- **Format:** PNG
- **Usage:** Stone texture overlay for StoneDialogButton widgets

## Sounds

**Location:** `assets/games/monster_mash/sounds/`

### Native Sounds (4 files)

#### MonsterMash-Organ.mp3
- **Trim:** 1.75s to 9.0s
- **Format:** MP3
- **Usage:** Game start announcement
- **Description:** Haunted organ music

#### MonsterMash-MonsterScream.mp3
- **Trim:** 3.0s to 7.5s
- **Format:** MP3
- **Usage:** Turn start announcement
- **Description:** Monster scream/howl

#### MonsterMash-Growl.mp3
- **Trim:** Full file
- **Format:** MP3
- **Usage:** Attack on opponent
- **Description:** Menacing growl

#### MonsterMash-MonsterRoar.mp3
- **Trim:** 0.0s to 2.5s
- **Format:** MP3
- **Usage:** Hat trick events
- **Description:** Powerful monster roar

### Borrowed from Target Tag (7 files)

Monster Mash reuses 7 sound effects from Target Tag to reduce asset duplication:

| Monster Mash Effect | Target Tag File | Usage in Monster Mash |
|---------------------|-----------------|----------------------|
| removeDarts | TargetTag-Swipe.mp3 | Remove darts prompt |
| dartHit | TargetTag-Spring.mp3 | All dart hit confirmations |
| healing | TargetTag-Whistle.mp3 | Healing events |
| healthWarning | TargetTag-Ominous.mp3 | Health threshold warnings |
| elimination | TargetTag-Villain.mp3 | Player elimination |
| clutchHeal | TargetTag-Dream.mp3 | Clutch heal events |
| buffActivation | TargetTag-Fanfare.mp3 | Buff activation |

## Asset Usage in Code

### Loading Character Images
```dart
// Dynamic monster image based on health
Image.asset(
  'assets/games/monster_mash/characters/${game.getMonsterImagePath(playerId)}',
)
```

### Loading Icons
```dart
// Main game icon
Image.asset('assets/games/monster_mash/icons/MonsterMash-Icon.png')

// Shield icons
Image.asset('assets/games/monster_mash/icons/Shield-Health.png')
Image.asset('assets/games/monster_mash/icons/Shield-HitPoint.png')
```

### Loading Sounds
```dart
class MonsterMashSoundEffects {
  static const String _basePath = 'games/monster_mash/sounds/';
  static const String _targetTagPath = 'games/target_tag/sounds/';

  static const SoundEffectConfig gameStart = SoundEffectConfig(
    assetPath: '${_basePath}MonsterMash-Organ.mp3',
    startSeconds: 1.75,
    endSeconds: 9.0,
  );
  // ...
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other assets ...

  # Monster Mash assets
  - assets/games/monster_mash/icons/
  - assets/games/monster_mash/images/
  - assets/games/monster_mash/sounds/
  - assets/games/monster_mash/characters/
```

## Asset Creation Guidelines

### Character Images
- **Format:** PNG with transparency
- **Style:** Classic horror monsters, cartoon/stylized aesthetic
- **States:** Must provide all 4 health states per monster
- **Naming:** `{MonsterName}-{HealthState}.png` (PascalCase monster name)

### Sounds
- **Format:** MP3 (best cross-platform compatibility)
- **Duration:** Keep most sounds under 3 seconds for quick feedback
- **Trimming:** Use `startSeconds` and `endSeconds` in SoundEffectConfig to trim
- **Reuse:** Check Target Tag sounds before creating new ones

## Asset Credits

### Character Art
- Custom monster character designs with 4 health-state variations each

### Icons
- Custom shield and game icon designs

### Sounds
- Monster-themed sound effects (organ, screams, growls, roars)
- 7 effects shared from Target Tag library

### Licenses
All assets are project assets licensed for use in Dart Games.
