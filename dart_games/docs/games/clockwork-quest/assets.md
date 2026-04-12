# Clockwork Quest - Assets

## Asset Organization

All Clockwork Quest assets are stored in `assets/games/clockwork_quest/` with subdirectories for images and sounds.

## Directory Structure

```
assets/games/clockwork_quest/
├── images/
│   ├── characters/      (8 files)
│   ├── gears/          (42 files: 20 inactive + 20 active + 2 bullseye)
│   ├── backgrounds/    (2 files)
│   └── icon.png        (1 file)
└── sounds/             (7 files)
```

**Total Assets:** 59 files (52 images + 7 sounds)

## Image Assets (52 files)

### Game Icon (1 file)

**Home Screen Card Icon:**
- **Path:** `assets/games/clockwork_quest/images/icon.png`
- **Size:** 512x512 pixels
- **Description:** Grand clocktower face with ornate brass gears visible behind clock hands, Roman numerals in gold, warm steampunk style
- **Format:** PNG with transparent background

### Backgrounds (2 files)

**Game Background:**
- **Path:** `assets/games/clockwork_quest/images/backgrounds/game_background.png`
- **Size:** 1920x1080 pixels
- **Description:** Inside of grand Victorian clocktower with massive interlocking brass gears, copper pipes, warm amber lighting from gas lamps, dark iron base color
- **Format:** PNG

**Menu Background:**
- **Path:** `assets/games/clockwork_quest/images/backgrounds/menu_background.png`
- **Size:** 1920x1080 pixels (same as game background, may use same file)
- **Description:** Warm steampunk clocktower interior suitable for menu screen
- **Format:** PNG

### Character Images (8 files)

All characters are 256x256 pixels, PNG with transparent background (green #00FF00 removed).

| Character | Filename | Description |
|-----------|----------|-------------|
| Cogsworth the Owl | `characters/cogsworth_owl.png` | Wise owl with brass goggles, gold feathers, copper gear pendant |
| Gizmo the Fox | `characters/gizmo_fox.png` | Clever fox with aviator cap, gear earring, orange-red fur |
| Piston the Cat | `characters/piston_cat.png` | Sleek cat with brass monocle, copper bowtie, gray-blue fur |
| Sprocket the Rabbit | `characters/sprocket_rabbit.png` | Bouncy rabbit with top hat (gear on band), leather cuffs |
| Rivet the Badger | `characters/rivet_badger.png` | Sturdy badger with tool belt, welding goggles, black/white face |
| Whistle the Mouse | `characters/whistle_mouse.png` | Tiny mouse with ear trumpet hat, copper wrench, light brown fur |
| Boiler the Bear | `characters/boiler_bear.png` | Gentle bear with leather apron, pressure gauge badge, brown fur |
| Ticker the Hedgehog | `characters/ticker_hedgehog.png` | Perky hedgehog with clockwork wings, pocket watch, gold-tipped quills |

### Gear Images (42 files)

Each numbered gear has 2 states (inactive + active). Bullseye has 2 states.

**Numbered Gears (40 files):**
- **Inactive:** `gears/gear_[N]_inactive.png` (N = 1-20)
  - Size: 120x120 pixels
  - Color: Rivet Silver (#8A8D93)
  - Number engraved in center (Victorian serif font)
  - Transparent background

- **Active:** `gears/gear_[N]_active.png` (N = 1-20)
  - Size: 120x120 pixels
  - Color: Brass Gold (#C5A54E)
  - Number glowing in Amber Glow (#FFBF00)
  - Steam wisps around edges
  - Transparent background

**Bullseye Gear (2 files):**
- **Inactive:** `gears/gear_bullseye_inactive.png`
  - Size: 150x150 pixels
  - Color: Rivet Silver
  - Bullseye target pattern in center
  - Ornate filigree details
  - Transparent background

- **Active:** `gears/gear_bullseye_active.png`
  - Size: 150x150 pixels
  - Color: Polished brass and copper
  - Bullseye center glowing bright amber
  - Radiating light beams and steam wisps
  - Transparent background

## Sound Assets (7 files)

All sounds stored in `assets/games/clockwork_quest/sounds/`

| Sound | Filename | Duration | Description |
|-------|----------|----------|-------------|
| Turn Bell | `turn_bell.mp3` | ~1s | Light metallic bell chime, warm and inviting |
| Clock Chime | `clock_chime.mp3` | ~2s | Deep, resonant clocktower chime with brass reverb |
| Victory Fanfare | `victory_fanfare.mp3` | ~3s | Triumphant brass fanfare with mechanical flourishes |
| Gear Click | `gear_click.mp3` | ~0.5s | Single crisp mechanical click, like a gear engaging |
| Gear Spin | `gear_spin.mp3` | ~2s | Sustained mechanical whirring with brass undertones |
| Steam Hiss | `steam_hiss.mp3` | ~1s | Short pressurized steam release, not harsh |
| Tick Tock | `tick_tock.mp3` | ~2s | Classic clockwork ticking, accelerating slightly |

## Asset Generation

All images should be generated using Gemini with bright green (#00FF00) backgrounds for easy removal.

### Image Prompts Reference

Full image generation prompts are documented in the game spec at:
`docs/research/games/tier1/clockwork-quest.md` - Section 3

### Asset Checklist

**Before declaring assets complete:**
- [ ] 1 game icon (512x512)
- [ ] 2 backgrounds (1920x1080)
- [ ] 8 character images (256x256)
- [ ] 40 numbered gear images (20 inactive + 20 active, 120x120)
- [ ] 2 bullseye gear images (inactive + active, 150x150)
- [ ] 7 sound effects (MP3 format)
- [ ] All images have transparent backgrounds (green removed)
- [ ] All sounds are family-friendly and warm-toned

## Asset Loading

Assets are preloaded in `ClockworkQuestProvider` initialization:

```dart
Future<void> _preloadAssets() async {
  // Preload character images
  for (int i = 1; i <= 8; i++) {
    await precacheImage(
      AssetImage('assets/games/clockwork_quest/images/characters/character_$i.png'),
      context,
    );
  }

  // Preload gear images
  for (int i = 1; i <= 20; i++) {
    await precacheImage(
      AssetImage('assets/games/clockwork_quest/images/gears/gear_${i}_inactive.png'),
      context,
    );
    await precacheImage(
      AssetImage('assets/games/clockwork_quest/images/gears/gear_${i}_active.png'),
      context,
    );
  }

  // Preload bullseye gears
  await precacheImage(
    AssetImage('assets/games/clockwork_quest/images/gears/gear_bullseye_inactive.png'),
    context,
  );
  await precacheImage(
    AssetImage('assets/games/clockwork_quest/images/gears/gear_bullseye_active.png'),
    context,
  );
}
```

## Asset Attribution

All assets are custom-generated using Gemini AI specifically for Clockwork Quest. No third-party licenses required.
