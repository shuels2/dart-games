# Asset Organization

## Overview

**ALL game assets (images, sounds, icons) MUST be organized in game-specific folders.**

This prevents file name conflicts between games and creates a clear separation of concerns.

## Asset Structure

```
assets/
├── common/                          # Shared assets used across all games
│   ├── icons/
│   │   └── icon.png                # App icon
│   └── images/
│       ├── logo.png                # Dart Games logo
│       └── connect_dartboard_icon.png
│
└── games/
    ├── carnival_derby/             # Carnival Derby game assets
    │   ├── icons/
    │   │   ├── horse.png
    │   │   ├── track.png
    │   │   └── finish_line.png
    │   ├── images/
    │   │   └── CarnivalDerby-WoodPlanks.jpg
    │   └── sounds/
    │       ├── CarnivalDerby-HorseRace-Start.mp3
    │       └── CarnivalDerby-Horse-Gallop.mp3
    │
    ├── target_tag/                 # Target Tag game assets
    │   ├── icons/
    │   │   ├── TargetTag-Icon.png
    │   │   └── TargetTag-TeamIcon-01.png through TargetTag-TeamIcon-10.png
    │   └── sounds/
    │       └── (15 sound effect files)
    │
    └── your_game/                  # ← New game assets go here
        ├── icons/
        ├── images/
        └── sounds/
```

## Adding Assets for a New Game

### Step 1: Create Game-Specific Asset Folders

```bash
mkdir -p assets/games/your_game/icons
mkdir -p assets/games/your_game/images
mkdir -p assets/games/your_game/sounds
```

### Step 2: Place ALL Game Assets in the Game Folder

**Icons:** `assets/games/your_game/icons/`
- Game icon
- UI icons
- Player markers
- Status indicators

**Images:** `assets/games/your_game/images/`
- Background images
- Decorative graphics
- Splash screens (if game-specific)

**Sounds:** `assets/games/your_game/sounds/`
- Sound effects
- Background music (if any)
- Audio cues

**IMPORTANT:**
- ❌ DO NOT mix game assets with other games' folders
- ❌ DO NOT place game-specific assets in `assets/common/`
- ✅ Keep all game assets contained in your game's folder

### Step 3: Update pubspec.yaml

Add your game's asset directory to `pubspec.yaml`:

```yaml
flutter:
  assets:
    # Shared/common assets
    - assets/common/icons/
    - assets/common/images/

    # Game-specific assets
    - assets/games/carnival_derby/
    - assets/games/target_tag/
    - assets/games/your_game/        # ← Add your game folder
```

**Note:** Directory-level declaration includes all files within subdirectories automatically.

### Step 4: Reference Assets Using Full Paths

Always use complete paths when referencing game assets in code.

#### Icons
```dart
Image.asset('assets/games/your_game/icons/your_icon.png')
```

#### Images
```dart
// As Image widget
Image.asset('assets/games/your_game/images/background.jpg')

// As AssetImage
AssetImage('assets/games/your_game/images/background.jpg')

// As background decoration
decoration: BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/games/your_game/images/background.jpg'),
    fit: BoxFit.cover,
  ),
)
```

#### Sound Effects
```dart
// In sound effects service
class YourGameSoundEffects {
  static const String _basePath = 'assets/games/your_game/sounds/';

  static const SoundEffectConfig yourSound = SoundEffectConfig(
    assetPath: '${_basePath}YourSound.mp3',
    startSeconds: 0.0,
    endSeconds: null,
  );
}
```

## Benefits of Game-Specific Asset Organization

### No File Name Conflicts
Each game can have:
- `icon.png` without conflicting with other games
- `background.jpg` without conflicts
- `hit.mp3` sound effect without conflicts

### Clear Ownership
- Easy to identify which assets belong to which game
- Clear responsibility for asset maintenance
- Simple to remove entire game and all its assets

### Easy to Add/Remove Games
```bash
# Add new game
mkdir -p assets/games/new_game/{icons,images,sounds}

# Remove old game
rm -rf assets/games/old_game
```

### Consistent with Code Organization
Mirrors the code structure:
- Code: `lib/screens/games/[game_name]/`
- Assets: `assets/games/[game_name]/`

### Simplified pubspec.yaml
Directory-based declarations instead of individual file entries:

**Before (bad):**
```yaml
assets:
  - assets/game1_icon.png
  - assets/game1_background.jpg
  - assets/game1_sound1.mp3
  - assets/game1_sound2.mp3
  # ... hundreds of entries
```

**After (good):**
```yaml
assets:
  - assets/games/game1/  # Includes all subdirectories
```

## Common Assets

The `assets/common/` directory is for assets used across multiple games or in the container app:

**Appropriate for common:**
- App icon (shown in home screen, splash screen)
- Dart Games logo
- Dartboard connection icons
- Shared UI elements

**NOT appropriate for common:**
- Game-specific icons
- Game-specific backgrounds
- Game-specific sound effects

## Asset Naming Conventions

### Recommended Naming Pattern

Use descriptive, prefixed names to avoid confusion:

**Icons:**
```
[GameName]-[Element]-[Variant].png

Examples:
- TargetTag-Icon.png
- TargetTag-TeamIcon-01.png
- CarnivalDerby-Horse.png
```

**Images:**
```
[GameName]-[Description].jpg

Examples:
- CarnivalDerby-WoodPlanks.jpg
- TargetTag-TechBackground.jpg
```

**Sounds:**
```
[GameName]-[Event]-[Variant].mp3

Examples:
- CarnivalDerby-HorseRace-Start.mp3
- CarnivalDerby-Horse-Gallop.mp3
- TargetTag-ShieldUp.mp3
- TargetTag-Hit-Opponent.mp3
```

### Naming Guidelines

**DO:**
- ✅ Use descriptive names
- ✅ Use hyphens for word separation
- ✅ Include game name prefix
- ✅ Use lowercase for consistency
- ✅ Include variant numbers if multiple versions

**DON'T:**
- ❌ Use spaces in file names
- ❌ Use generic names like `icon.png`, `background.jpg`
- ❌ Use special characters (except hyphens)
- ❌ Use inconsistent capitalization

## Asset Formats

### Icons
- **Format:** PNG with transparency
- **Size:** 512x512px (scaled down as needed)
- **Color Mode:** RGBA

### Images
- **Photos/Realistic:** JPG (smaller file size)
- **Graphics/Transparency:** PNG
- **Recommended Size:** 1920x1080px or larger
- **Compression:** Balance quality and file size

### Sounds
- **Format:** MP3 (best cross-platform compatibility)
- **Bitrate:** 128-192kbps (balance quality and size)
- **Sample Rate:** 44.1kHz
- **Channels:** Stereo or Mono (depending on content)
- **Duration:** Keep individual files under 10 seconds for performance

## File Size Considerations

### Web Performance
- Keep total game assets under 5MB if possible
- Compress images appropriately
- Use audio trimming for sound effects

### Optimization Tools
- **Images:** TinyPNG, ImageOptim, Squoosh
- **Audio:** Audacity (trim + export with compression)

## pubspec.yaml Complete Example

```yaml
flutter:
  uses-material-design: true

  fonts:
    - family: Nunito
      fonts:
        - asset: fonts/Nunito-Regular.ttf
        - asset: fonts/Nunito-Bold.ttf
          weight: 700

  assets:
    # Common/shared assets
    - assets/common/icons/
    - assets/common/images/

    # Game-specific assets (directory-level)
    - assets/games/carnival_derby/
    - assets/games/target_tag/
    - assets/games/your_game/
```

## Reference Implementations

### Carnival Derby Assets
**Location:** `assets/games/carnival_derby/`

**Total:** 6 assets
- **Icons (3):** horse.png, track.png, finish_line.png
- **Images (1):** CarnivalDerby-WoodPlanks.jpg
- **Sounds (2):** CarnivalDerby-HorseRace-Start.mp3, CarnivalDerby-Horse-Gallop.mp3

### Target Tag Assets
**Location:** `assets/games/target_tag/`

**Total:** 26 assets
- **Icons (11):** TargetTag-Icon.png, TargetTag-TeamIcon-01.png through TargetTag-TeamIcon-10.png
- **Sounds (15):** Various sound effects for game events

## Asset Documentation

Create an asset inventory in your game's documentation:

**File:** `docs/games/your_game/assets.md`

Document:
- Complete list of all assets
- File sizes
- Descriptions and usage
- Sources and licenses (if applicable)

See [Game Template](../games/_GAME_TEMPLATE/assets.md) for template.

## Migration from Old Structure

If you have assets in the wrong location:

```bash
# Move assets to correct location
mkdir -p assets/games/your_game/icons
mv assets/old_icon.png assets/games/your_game/icons/

# Update code references
# Change: Image.asset('assets/old_icon.png')
# To: Image.asset('assets/games/your_game/icons/old_icon.png')

# Update pubspec.yaml
# Remove individual file entries
# Add directory entry
```

## Summary

**Key Points:**
- ✅ All game assets in `assets/games/[game_name]/`
- ✅ Organize by type (icons, images, sounds)
- ✅ Use full paths in code
- ✅ Add directory to pubspec.yaml
- ✅ Use descriptive, prefixed file names
- ✅ Document assets in game documentation

**Benefits:**
- No file name conflicts
- Clear ownership
- Easy to add/remove games
- Simplified pubspec.yaml
- Consistent with code structure

## Related Documentation

- [Adding New Games](adding-games.md)
- [Game Template - Assets](../games/_GAME_TEMPLATE/assets.md)
- [Carnival Derby Assets](../games/carnival-derby/assets.md)
- [Target Tag Assets](../games/target-tag/assets.md)
