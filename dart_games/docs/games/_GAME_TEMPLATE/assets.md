# [Game Name] - Asset Inventory

## Asset Location
**Base Path:** `assets/games/[game_name]/`

## Asset Summary
- **Icons:** [N] files
- **Images:** [N] files
- **Sounds:** [N] files
- **Total Assets:** [N] files

## Icons

**Location:** `assets/games/[game_name]/icons/`

### [Icon1Name].png
- **Size:** [width]x[height]px
- **Format:** PNG
- **Usage:** [Where/how this icon is used]
- **Description:** [What the icon depicts]

### [Icon2Name].png
- **Size:** [width]x[height]px
- **Format:** PNG
- **Usage:** [Where/how this icon is used]
- **Description:** [What the icon depicts]

[List all icon assets]

## Images

**Location:** `assets/games/[game_name]/images/`

### [Image1Name].jpg
- **Size:** [width]x[height]px
- **Format:** JPG
- **Usage:** [Where/how this image is used]
- **Description:** [What the image depicts]
- **Source:** [Where the image came from, if applicable]
- **License:** [License info if applicable]

### [Image2Name].png
- **Size:** [width]x[height]px
- **Format:** PNG
- **Usage:** [Where/how this image is used]
- **Description:** [What the image depicts]
- **Source:** [Where the image came from, if applicable]
- **License:** [License info if applicable]

[List all image assets]

## Sounds

**Location:** `assets/games/[game_name]/sounds/`

### [Sound1Name].mp3
- **Duration:** [X.X] seconds (total file)
- **Trim:** [Start]s to [End]s (or "Full file")
- **Format:** MP3
- **Usage:** [When this sound plays]
- **Description:** [What the sound is]
- **Source:** [Where the sound came from, if applicable]
- **License:** [License info if applicable]

### [Sound2Name].mp3
- **Duration:** [X.X] seconds (total file)
- **Trim:** [Start]s to [End]s (or "Full file")
- **Format:** MP3
- **Usage:** [When this sound plays]
- **Description:** [What the sound is]
- **Source:** [Where the sound came from, if applicable]
- **License:** [License info if applicable]

[List all sound assets]

## Asset Usage in Code

### Loading Icons
```dart
Image.asset('assets/games/[game_name]/icons/[IconName].png')
```

### Loading Images
```dart
AssetImage('assets/games/[game_name]/images/[ImageName].jpg')

// Or as background
decoration: BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/games/[game_name]/images/[ImageName].jpg'),
    fit: BoxFit.cover,
  ),
)
```

### Loading Sounds
```dart
// In sound effects service
class [GameName]SoundEffects {
  static const String _basePath = 'assets/games/[game_name]/sounds/';

  static const SoundEffectConfig [soundName] = SoundEffectConfig(
    assetPath: '${_basePath}[SoundName].mp3',
    startSeconds: [X.X],
    endSeconds: [Y.Y],
  );
}
```

## pubspec.yaml Declaration

```yaml
assets:
  # ... other assets ...

  # [Game Name] assets
  - assets/games/[game_name]/
```

**Note:** Directory-level declaration includes all files within subdirectories (icons/, images/, sounds/).

## Asset Creation Guidelines

### Icons
- **Format:** PNG with transparency
- **Size:** [Recommended size]
- **Style:** [Style guide - flat, 3D, illustrative, etc.]
- **Color Scheme:** [Should match game color palette]

### Images
- **Format:** JPG for photos, PNG for graphics with transparency
- **Size:** [Recommended dimensions]
- **Optimization:** [Compression settings]
- **Style:** [Style guide]

### Sounds
- **Format:** MP3 (best cross-platform compatibility)
- **Bitrate:** [Recommended bitrate - e.g., 128kbps]
- **Sample Rate:** [Recommended rate - e.g., 44.1kHz]
- **Duration:** Keep individual files under [X] seconds for performance
- **Volume Normalization:** Normalize to [X]dB to maintain consistent volume

## Future Asset Needs
[List any planned assets or asset improvements]
- [ ] [Asset 1 description]
- [ ] [Asset 2 description]
- [ ] [Asset 3 description]

## Asset Credits

### [Asset Category]
- **[Asset Name]:** [Credit/Attribution]
- **[Asset Name]:** [Credit/Attribution]

### Licenses
[Any license information for third-party assets]
