# Critical Rule: Cross-Platform Compatibility

## Overview
**All features must work on both web and tablet devices (iOS and Android).**

Dart Games is designed to run on:
- Web browsers (Chrome, Safari, Firefox, Edge)
- iOS tablets (iPad)
- Android tablets

## Requirements When Implementing Features

When implementing new features or modifying existing code, ensure:

✅ Compatibility with web browsers (Chrome, Safari, Firefox, Edge)
✅ Compatibility with iOS tablets (iPad)
✅ Compatibility with Android tablets
✅ Use platform-specific code only when necessary, with proper conditional imports
✅ Test platform-specific features on all target platforms

## Platform-Specific Considerations

### File Storage

**Web:** Uses IndexedDB
**Native:** Uses file system

**Pattern:**
```dart
// All data is stored on the server via API calls — no platform-specific storage needed
final apiClient = ApiClient(config: ApiConfig());
await apiClient.saveSettings(key, value);
```

### Audio Playback

**Web:** Use HTML audio elements or web-compatible audio plugins
**Native:** Use native audio players

**Ensure:**
- Audio formats are supported across all platforms (MP3 is safest)
- Volume controls work on all platforms
- Audio can be stopped/paused on all platforms

**Current Implementation:**
- Uses audioplayers package (cross-platform)
- MP3 format (supported everywhere)

### File Picking

**Web:** Different APIs than native
**Native:** Uses native file pickers

**Pattern:**
```dart
import 'package:file_picker/file_picker.dart';

Future<String?> pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result != null) {
    if (kIsWeb) {
      // Web: File is in bytes, need to handle differently
      return result.files.first.name;
    } else {
      // Native: File has a path
      return result.files.first.path;
    }
  }
  return null;
}
```

### Responsive Layouts

**Test on different screen sizes and orientations:**
- Web desktop (large screens)
- Web mobile (small screens)
- iPad landscape and portrait
- Android tablet landscape and portrait

**Use:**
- MediaQuery for screen dimensions
- LayoutBuilder for responsive widgets
- Flexible/Expanded for adaptive layouts

### Touch vs Mouse Input

**Both should work seamlessly:**
- Touch gestures on tablets
- Mouse clicks on web
- Mouse hover states (but don't require them for functionality)

**Ensure:**
- Tap targets are large enough for touch (minimum 44x44 points)
- Hover states are optional, not required
- Drag gestures work with both touch and mouse

## Conditional Imports

When you need platform-specific code:

```dart
// Conditional import based on platform
import 'stub.dart' // Stub implementation
  if (dart.library.html) 'web_impl.dart' // Web implementation
  if (dart.library.io) 'mobile_impl.dart'; // Mobile implementation
```

**Avoid in Shared Code:**
- ❌ `dart:html` - Web only
- ❌ `dart:js` - Web only
- ❌ `dart:io` - Native only (without conditional import)

**Safe to use:**
- ✅ `dart:core` - Cross-platform
- ✅ `package:flutter/foundation.dart` - Includes kIsWeb
- ✅ Most Flutter packages (check pub.dev for platform support)

## Testing Cross-Platform Features

### Manual Testing Checklist

When adding a new feature:

- [ ] Test on Chrome (web)
- [ ] Test on Safari (web, if available)
- [ ] Test on Firefox (web)
- [ ] Test on Edge (web)
- [ ] Test on iPad (if available)
- [ ] Test on Android tablet (if available)

At minimum, test on:
- [ ] Web (Chrome)
- [ ] One mobile platform (iOS or Android)

### Common Cross-Platform Issues

**Issue 1: File paths**
- Web uses data URLs or blob URLs
- Native uses file system paths
- Always check `kIsWeb` before using paths

**Issue 2: Audio playback**
- Different audio APIs on web vs native
- Use cross-platform packages like `audioplayers`
- Test volume control on all platforms

**Issue 3: Storage**
- Web has limited file system access
- All settings are stored on the server via API calls
- No client-side storage needed

**Issue 4: Permissions**
- Camera/microphone permissions different on web vs native
- Check permission status before accessing
- Handle permission denial gracefully

**Issue 5: Keyboard input**
- Physical keyboard on web
- Virtual keyboard on tablets
- Ensure both work correctly
- Test keyboard shortcuts (if any)

## Current Cross-Platform Features

### Working Cross-Platform
✅ Player management (server API)
✅ Dartboard connection (API-based)
✅ Victory music (audioplayers package)
✅ Announcer system (web_speech_api for web, flutter_tts for native)
✅ Game state management (Provider)
✅ All game logic

### Platform-Specific Implementations
- **Photo Upload:** Uses PhotoService with platform-specific file picking
- **Victory Music Storage:** Data URLs on web, file paths on native
- **Announcer Voices:** Browser voices on web, native TTS on mobile

## Development Guidelines

### Do's
✅ Use `kIsWeb` checks when platforms differ
✅ Use cross-platform packages when available
✅ Test on both web and at least one native platform
✅ Document platform-specific behavior
✅ Provide fallback behavior when feature unavailable

### Don'ts
❌ Use web-only APIs in shared code without conditional imports
❌ Use mobile-only APIs in web builds
❌ Assume file paths work the same everywhere
❌ Assume permissions work the same everywhere
❌ Build features that only work on one platform (without good reason)

## Future Considerations

### Desktop Support (Future)
If Dart Games expands to desktop (Windows/Mac/Linux):
- File system access will be like native mobile
- Audio will be like native mobile
- Permissions will differ from web and mobile
- Window management will be new consideration

### Progressive Web App (PWA)
If Dart Games becomes a PWA:
- Offline support needed
- Service workers for caching
- Install prompts
- Push notifications (optional)

## Reference Implementations

See these files for cross-platform patterns:
- `lib/services/victory_music_service.dart` - Cross-platform file handling
- `lib/services/photo_service.dart` - Cross-platform photo picking
- `lib/services/dart_announcer_service.dart` - Cross-platform TTS
- `lib/providers/player_provider.dart` - Cross-platform data persistence

## Testing Commands

```bash
# Test on web
flutter run -d chrome

# Test on iOS (requires Mac + Xcode)
flutter run -d ios

# Test on Android (requires Android SDK)
flutter run -d android

# Build for web
flutter build web

# Build for iOS (requires Mac + Xcode)
flutter build ios

# Build for Android
flutter build appbundle
```
