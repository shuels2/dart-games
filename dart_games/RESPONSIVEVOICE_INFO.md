# ResponsiveVoice Integration

The Dart Games app now uses ResponsiveVoice for natural-sounding text-to-speech announcements!

## What is ResponsiveVoice?

ResponsiveVoice is a browser-based text-to-speech library that provides high-quality, natural-sounding voices without requiring any server setup or installation.

## Features

✅ **Natural voices** - Much better quality than basic browser TTS
✅ **No server required** - Works directly in the browser
✅ **Cross-browser support** - Works in Chrome, Edge, Firefox, Safari
✅ **Free for non-commercial use** - Perfect for personal projects
✅ **Multiple voices** - US/UK English (male/female), Australian, and more

## Available Voices

- **US English Female** - Natural American female voice (default)
- **US English Male** - Natural American male voice
- **UK English Female** - British female voice
- **UK English Male** - British male voice
- **Australian Female** - Australian female voice
- **Australian Male** - Australian male voice

## How to Use

1. Launch the app: `flutter run -d chrome`
2. In the dartboard emulator, select **"ResponsiveVoice"** from the Engine dropdown
3. If ResponsiveVoice is loaded, you'll see a green checkmark ✓
4. Choose your preferred voice
5. Select your personality style (Professional, Excited, Calm, Funny, Drill Sergeant)
6. Start throwing darts and enjoy natural announcements!

## Personality Styles

Each personality affects the speech rate and pitch:

- **Professional** - Standard, clear announcements
- **Excited** - Faster, higher pitch for enthusiasm
- **Calm** - Slower, lower pitch for relaxation
- **Funny** - Slightly faster with varied pitch
- **Drill Sergeant** - Fast-paced, commanding tone

## Fallback to Browser Voices

If ResponsiveVoice doesn't load (rare), the app automatically falls back to browser built-in voices. Just select "Browser Voices" from the engine dropdown.

## Technical Details

- **Library**: ResponsiveVoice Text-To-Speech
- **Integration**: JavaScript interop via dart:js
- **License**: Free for non-commercial use
- **Documentation**: https://responsivevoice.org/

## Files Modified

- `lib/services/responsive_voice_service.dart` - ResponsiveVoice wrapper service
- `lib/services/dart_announcer_service.dart` - Updated to use ResponsiveVoice
- `lib/screens/test_dartboard_screen.dart` - Updated UI for ResponsiveVoice
- `web/index.html` - Added ResponsiveVoice script tag

## Commercial Use

If you plan to use this app commercially, you'll need to:
1. Get a ResponsiveVoice commercial license: https://responsivevoice.org/pricing/
2. Update the API key in `web/index.html`

## Support

ResponsiveVoice works in all modern browsers. If you encounter issues:
1. Check browser console for errors
2. Ensure you have an active internet connection
3. Try refreshing the page
4. Fall back to Browser Voices if needed
