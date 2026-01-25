# Natural Voice Selection

## Overview

The dartboard emulator now supports natural-sounding voices by accessing your browser's built-in text-to-speech voices. This provides a much more pleasant listening experience compared to the default robotic voice.

## Features

### 🎙️ System Voice Selection
- **Browse available voices** - See all English voices available on your system/browser
- **Select your favorite** - Choose from Google, Microsoft, or other high-quality voices
- **Automatic selection** - The app tries to select the best available voice by default

### 🎭 Personality Styles (Combined with Natural Voices)
You can still choose from 5 different announcement styles:
1. **Professional** - Formal and precise
2. **Excited** - High-energy and enthusiastic
3. **Calm** - Soothing and relaxed
4. **Funny** - Humorous and playful
5. **Drill Sergeant** - Commanding and intense

### How It Works

The app now has **two separate controls**:

1. **Voice** - Select the actual voice/speaker (natural-sounding voices from your system)
2. **Style** - Select the personality/phrase style (what they say and how they say it)

This gives you combinations like:
- A female Google voice with a Funny style
- A male Microsoft voice with a Drill Sergeant style
- A British voice with a Professional style

## Available Voices

The voices available depend on your browser and operating system:

### Chrome/Edge on Windows typically provides:
- **Microsoft voices** - David, Zira, Mark, etc.
- **Google voices** (if available) - Enhanced natural voices

### Chrome on Mac typically provides:
- **Apple voices** - Samantha, Alex, Victoria, etc.
- **Google voices** - Natural and enhanced options

### Chrome on Linux typically provides:
- **eSpeak voices** - Various language options
- **Google voices** - If available through Chrome

## Finding Better Voices

### On Windows:
1. Go to Settings > Time & Language > Speech
2. Under "Manage voices", download additional voices
3. Look for "Natural" or "Neural" voices for best quality

### On Mac:
1. Go to System Preferences > Accessibility > Spoken Content
2. Click "System Voice" dropdown
3. Download additional voices (look for Enhanced or Premium)

### In Chrome:
- Chrome includes Google's voices on all platforms
- These often sound more natural than system voices

## Usage Tips

1. **Try different voices** - Each voice sounds different; find one you like
2. **Match voice to style** - A deep voice works well with Drill Sergeant, a cheerful voice with Excited
3. **Adjust browser volume** - Control announcer volume in your browser
4. **Locale matters** - Voices marked (en-US) or (en-GB) will sound most natural

## Technical Details

### Voice Selection
- The app automatically filters to English voices only
- It prefers Google, Enhanced, Premium, or Natural voices when available
- Falls back to any available English voice if premium voices aren't found

### Voice Names
The dropdown shows:
- Voice name (cleaned up - removes "Microsoft", "Google" prefix)
- Locale code in parentheses (e.g., "en-US", "en-GB")

Example: `David (en-US)` is Microsoft David with US English accent

## Troubleshooting

### "Loading voices..." never changes
- Wait 1-2 seconds after app loads
- Refresh the page if it doesn't populate
- Check browser console for errors

### Voice sounds robotic
- Try selecting a different voice from the dropdown
- Look for voices with "Natural", "Neural", or "Enhanced" in the name
- Google voices typically sound more natural than default system voices

### No voices available
- Make sure you're using a modern browser (Chrome, Edge, Safari)
- Try refreshing the page
- Check browser permissions for speech/audio

### Voice doesn't change when selected
- Wait for current announcement to finish
- The next dart throw will use the new voice
- Try toggling the announcer off and back on

## Future Enhancements

Potential additions:
- Voice preview/test button
- Voice favorites/bookmarks
- Custom voice rate/pitch controls per voice
- Voice packs for download
- Regional accent preferences
