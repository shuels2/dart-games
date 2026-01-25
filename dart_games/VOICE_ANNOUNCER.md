# Dartboard Voice Announcer

## Overview

The dartboard emulator now includes a voice announcer that calls out scores and adds personality to each dart throw!

## Features

### 5 Unique Announcer Voices

1. **Professional** - Standard professional announcer
   - Precise and formal
   - "Bullseye! 50 points!"
   - "Triple 20 for 60"

2. **Excited** - High-energy enthusiastic caller
   - Energetic and animated
   - "BULLSEYE! Fifty points! What a shot!"
   - "Wow! Triple 20! That's 60 points!"

3. **Calm** - Soothing and relaxed announcer
   - Peaceful and measured
   - "Perfect center. Bullseye. Fifty points."
   - "Triple 20. 60 points."

4. **Funny** - Comedic and entertaining caller
   - Humorous and playful
   - "Boom! Right in the eye! Bullseye! 50!"
   - "Oh baby! Triple 20! 60 points of pure awesome!"

5. **Drill Sergeant** - Military-style motivational caller
   - Commanding and intense
   - "BULLSEYE! FIFTY! Outstanding shot, soldier!"
   - "OUTSTANDING! Triple 20! 60 points! Hooah!"

## What Gets Announced

- **All dart throws** with score and multiplier
- **Special callouts** for:
  - Bullseye (50 points)
  - Outer bull (25 points)
  - High scores (triple 20, etc.)
  - Misses
  - Specific funny scores (like 69)

## Voice Characteristics

Each voice has unique:
- **Speech rate** - How fast they talk
- **Pitch** - Voice tone (higher/lower)
- **Phrases** - Multiple variations for the same score
- **Personality** - Different reactions to high scores, misses, etc.

## How to Use

1. **Select a voice** from the dropdown menu
2. **Toggle announcer** on/off with the switch
3. **Throw darts** and listen to the callouts!

## Technical Details

- **Package**: flutter_tts (Text-to-Speech)
- **Service**: `DartAnnouncerService`
- **Location**: `lib/services/dart_announcer_service.dart`

## Sample Phrases

### Bullseye
- Professional: "Bullseye! 50 points!"
- Excited: "Oh my! Bullseye for 50!"
- Calm: "Perfect center. Bullseye. Fifty points."
- Funny: "Boom! Right in the eye! Bullseye! 50!"
- Drill: "BULLSEYE! FIFTY! Outstanding shot, soldier!"

### Triple 20 (60 points)
- Professional: "Triple 20 for 60"
- Excited: "What a throw! Triple 20 for 60!"
- Calm: "Triple 20. 60 points."
- Funny: "Crushed it! Triple 20 for 60!"
- Drill: "OUTSTANDING! Triple 20! 60 points! Hooah!"

### Miss
- Professional: "Miss. No score."
- Excited: "Ooh! Just missed the board!"
- Calm: "Off the board. No score."
- Funny: "Whoops! Missed the boat! Zero points!"
- Drill: "MISS! Get back in the fight!"

## Adding New Voices

To add a new voice:

1. Add voice to the `AnnouncerVoice` enum
2. Update `_updateVoiceSettings()` with speech rate and pitch
3. Add phrases for each announcement type:
   - `_getBullseyePhrase()`
   - `_getOuterBullPhrase()`
   - `_getMissPhrase()`
   - `_getScoringPhrase()`

## Future Enhancements

Potential additions:
- Custom voice recordings
- Multiple language support
- Tournament mode announcements
- Player-specific callouts
- Game state announcements (180s, checkout attempts, etc.)
