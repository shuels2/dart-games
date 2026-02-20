# Carnival Derby - Asset Inventory

## Asset Location
**Base Path:** `assets/games/carnival_derby/`

## Asset Summary
- **Icons:** 3 files
- **Images:** 1 file
- **Sounds:** 2 files
- **Total Assets:** 6 files (~20MB total)

## Icons

**Location:** `assets/games/carnival_derby/icons/`

### horse.png
- **Size:** 485 KB
- **Format:** PNG with transparency
- **Usage:** Horse avatar icon for players on the race track
- **Description:** Racing horse silhouette used to represent player position

### track.png
- **Size:** 4.5 MB
- **Format:** PNG with transparency
- **Usage:** Race track visualization background
- **Description:** Oval horse racing track graphic showing the racing path

### finish_line.png
- **Size:** 4.7 MB
- **Format:** PNG with transparency
- **Usage:** Finish line marker at end of race track
- **Description:** Checkered finish line flag graphic marking the target score

## Images

**Location:** `assets/games/carnival_derby/images/`

### CarnivalDerby-WoodPlanks.jpg
- **Size:** 10.5 MB
- **Format:** JPG
- **Usage:** Background texture for menu and game screens
- **Description:** Rustic wood plank texture rotated 90 degrees and tiled
- **Processing:** Applied with Cedar (#8B5E3C) color tint at 0.7 opacity using multiply blend mode, overlaid with radial gradient for warm spotlight effect
- **Source:** Stock texture
- **License:** Project asset

## Sounds

**Location:** `assets/games/carnival_derby/sounds/`

### CarnivalDerby-HorseRace-Start.mp3
- **Duration:** ~2.3 seconds (total file)
- **Trim:** Full file (0.0s to end)
- **Format:** MP3
- **Usage:** Played when announcing player's turn
- **Description:** Horse race starting trumpet fanfare
- **Source:** Sound effect library
- **License:** Project asset

### CarnivalDerby-Horse-Gallop.mp3
- **Duration:** ~2.5 seconds (total file)
- **Trim:** Full file (0.0s to end)
- **Format:** MP3
- **Usage:** Played when game is complete (victory announcement)
- **Description:** Horse galloping sound effect
- **Source:** Sound effect library
- **License:** Project asset

## Asset Usage in Code

### Loading Icons
```dart
// Horse icon for player avatars
Image.asset('assets/games/carnival_derby/icons/horse.png')

// Track background
Image.asset('assets/games/carnival_derby/icons/track.png')

// Finish line marker
Image.asset('assets/games/carnival_derby/icons/finish_line.png')
```

### Loading Images
```dart
// Wood plank background
AssetImage('assets/games/carnival_derby/images/CarnivalDerby-WoodPlanks.jpg')

// As tiled background with color tint
decoration: BoxDecoration(
  color: const Color(0xFF8B5E3C), // Cedar base color
  image: DecorationImage(
    image: AssetImage('assets/games/carnival_derby/images/CarnivalDerby-WoodPlanks.jpg'),
    fit: BoxFit.cover,
    repeat: ImageRepeat.repeat,
    colorFilter: ColorFilter.mode(
      const Color(0xFF8B5E3C).withOpacity(0.7),
      BlendMode.multiply,
    ),
  ),
)
```

### Loading Sounds
```dart
// In sound effects service
class CarnivalDerbySoundEffects {
  static const String _basePath = 'games/carnival_derby/sounds/';

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
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other assets ...

  # Carnival Derby assets
  - assets/games/carnival_derby/
```

**Note:** Directory-level declaration includes all files within subdirectories (icons/, images/, sounds/).

## Asset Creation Guidelines

### Icons
- **Format:** PNG with transparency
- **Size:** Variable (optimize for web - keep under 5MB)
- **Style:** Illustrative carnival/horse racing theme
- **Color Scheme:** Should complement Carnival Derby palette (Lava Red, Canary Yellow, Electric Teal)

### Images
- **Format:** JPG for photos/textures, PNG for graphics with transparency
- **Size:** Optimize for web performance while maintaining visual quality
- **Optimization:** Use compression to reduce file size
- **Style:** Rustic carnival theme with warm wood tones

### Sounds
- **Format:** MP3 (best cross-platform compatibility)
- **Bitrate:** 128-192 kbps
- **Sample Rate:** 44.1kHz
- **Duration:** Keep under 5 seconds for quick feedback
- **Volume Normalization:** Normalize to -6dB to maintain consistent volume across all sound effects

## Shared Assets from Other Games

Carnival Derby reuses sound effects from Target Tag to maintain consistency and reduce asset duplication:
- TargetTag-Swipe.mp3 (remove darts)
- TargetTag-Teasing.mp3 (miss)
- TargetTag-Spring.mp3 (single hit)
- TargetTag-Blink.mp3 (double hit)
- TargetTag-Dream.mp3 (triple hit)
- TargetTag-Choir.mp3 (bullseye)
- TargetTag-Whistle.mp3 (outer bull)
- TargetTag-Ominous.mp3 (bust)

See `lib/services/carnival_derby_sound_effects.dart` for complete configuration.

## Future Asset Needs
- [ ] Animated horse sprite sheets for smoother racing animation
- [ ] Additional carnival-themed background music
- [ ] Victory celebration sound effects beyond horse gallop
- [ ] Crowd cheering sound effects for close finishes
- [ ] Different horse icons for player customization

## Asset Credits

### Icons
- **horse.png:** Stock carnival asset
- **track.png:** Stock racing track graphic
- **finish_line.png:** Stock checkered flag graphic

### Images
- **CarnivalDerby-WoodPlanks.jpg:** Stock texture asset

### Sounds
- **CarnivalDerby-HorseRace-Start.mp3:** Sound effect library
- **CarnivalDerby-Horse-Gallop.mp3:** Sound effect library

### Licenses
All assets are project assets licensed for use in Dart Games.
