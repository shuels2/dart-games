# Build Process

## Mandatory Testing Before Any Build

**ALL NON-UI TESTS MUST PASS BEFORE ANY BUILD OR DEPLOYMENT.**

This is a critical requirement with no exceptions.

## Pre-Build Checklist

Before any build, commit, or deployment:

### 1. Run Non-UI Test Suite (MANDATORY)
```bash
cd dart_games
flutter test
```

**Requirements:**
- ✅ All 272 non-UI tests must pass (100% pass rate required)
- ❌ If ANY test fails, DO NOT proceed with build
- 🔧 Fix all failing tests first, then re-run test suite
- ✅ Only build after confirming all tests pass

**Test Categories:**
- Model tests (40 tests)
- Provider tests (44 tests)
- Service tests (42 tests)
- Integration tests (83 tests)
- Shared component tests (24 tests)
- Widget tests (23 tests)
- Carnival Derby tests (26 tests)
- Target Tag tests (46 tests)

### 2. UI Automation Tests (OPTIONAL)

The 77 UI automation tests take longer to run (~51 minutes) and require chromedriver.

**Before running a build, ASK the user:**
```
Would you like me to run the UI automation tests before this build?
```

**If the user says yes:**
```bash
# Terminal 1 - Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2 - Run UI tests (77 tests, ~51 minutes)
cd dart_games
./run_ui_tests.bat
```

**If the user says no:**
- Proceed with build after non-UI tests pass
- UI automation tests are supplementary and not required for every build

## Build Commands

### Web Build
```bash
flutter build web
```

**Output:** `build/web/`

**Use Case:** Deploy to web hosting (Firebase, Netlify, etc.)

### Android APK Build
```bash
flutter build apk
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

**Use Case:** Sideload to Android devices for testing

### Android App Bundle Build (Production)
```bash
flutter build appbundle
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

**Use Case:** Upload to Google Play Store

### iOS Build (Requires Mac)
```bash
flutter build ios
```

**Output:** `build/ios/iphoneos/Runner.app`

**Use Case:** Deploy to App Store or TestFlight

## Development Workflow

### Standard Development Process

1. **Make code changes** (excluding protected dartboard emulator code)

2. **MANDATORY: Run full non-UI test suite**
   ```bash
   cd dart_games
   flutter test
   ```

3. **Verify ALL 272 non-UI tests pass** (100% pass rate required)

4. **OPTIONAL: Ask user if they want to run UI automation tests** (77 tests, ~51 minutes)

5. **If ANY tests fail:**
   - DO NOT proceed
   - Investigate and fix the failing tests
   - Re-run the test suite
   - Only continue after all tests pass

6. **Commit changes locally** (if appropriate)

7. **Ask user for permission before pushing to remote**

8. **Wait for explicit user approval**

9. **Only then proceed with build/deployment**

## Build Process Steps

### Step 1: Verify Tests Pass
```bash
flutter test
```

Output should show:
```
All tests passed!
```

### Step 2: Clean Previous Build (Optional but Recommended)
```bash
flutter clean
flutter pub get
```

### Step 3: Run Build Command
```bash
# Choose platform
flutter build web
# or
flutter build apk
# or
flutter build appbundle
# or
flutter build ios
```

### Step 4: Verify Build Success

Look for:
```
✓ Built build/web/.
```

Or equivalent for other platforms.

### Step 5: Test Built App

- **Web:** Test locally with:
  ```bash
  cd build/web
  python -m http.server 8000
  # Visit http://localhost:8000
  ```

- **Android APK:** Install on test device:
  ```bash
  flutter install
  ```

- **iOS:** Test on simulator or device

## Build Optimization Flags

### Release Mode (Default)
```bash
flutter build web --release
```

**Characteristics:**
- Optimized code
- Minified JavaScript (web)
- No debug symbols
- Smaller file size
- Production-ready

### Profile Mode (Performance Testing)
```bash
flutter build web --profile
```

**Characteristics:**
- Performance profiling enabled
- Some optimizations
- Debug symbols included
- Larger than release

### Debug Mode (Not for Production)
```bash
flutter run --debug
```

**Characteristics:**
- All debug symbols
- Hot reload enabled
- Larger file size
- Slower performance
- For development only

## Web Build Specific

### Build with Custom Base URL
```bash
flutter build web --base-href /dart-games/
```

### PWA Configuration
Edit `web/manifest.json` for PWA settings.

## Platform-Specific Notes

### Web
- Test on multiple browsers (Chrome, Safari, Firefox, Edge)
- Check responsive design
- Verify audio playback works
- Test dartboard emulator

### Android
- Test on multiple device sizes
- Check permissions (camera, storage, etc.)
- Verify audio playback
- Test dartboard emulator
- Test on different Android versions if possible

### iOS
- Requires Mac with Xcode
- Sign with Apple Developer account for distribution
- Test on iPad specifically (primary target)
- Verify audio playback
- Test dartboard emulator

## What to Build When

### Development Testing
```bash
flutter run -d chrome  # Web testing
flutter run -d android  # Android testing
flutter run -d ios      # iOS testing
```

### Beta Testing
```bash
flutter build web --release          # Web beta
flutter build apk --release          # Android beta (sideload)
flutter build ios --release          # iOS TestFlight
```

### Production Release
```bash
flutter build web --release          # Web production
flutter build appbundle --release    # Android Play Store
flutter build ios --release          # iOS App Store
```

## Pre-Deployment Checklist

Before deploying to production:

- [ ] All 272 non-UI tests pass
- [ ] (Optional) All 77 UI automation tests pass
- [ ] Code has been reviewed
- [ ] Changes have been committed
- [ ] User has approved push to remote
- [ ] Build completes successfully
- [ ] Built app has been manually tested
- [ ] No console errors or warnings
- [ ] Performance is acceptable
- [ ] Cross-platform compatibility verified

## If Build Fails

### Common Build Errors

**Error: "Gradle build failed"**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build apk
```

**Error: "Xcode build failed"**
```bash
# Clean and retry
flutter clean
cd ios
pod install
cd ..
flutter build ios
```

**Error: "Web build failed"**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build web
```

### Still Failing?

1. Check Flutter version:
   ```bash
   flutter doctor -v
   ```

2. Update Flutter:
   ```bash
   flutter upgrade
   ```

3. Update dependencies:
   ```bash
   flutter pub upgrade
   ```

4. Report issue to user with:
   - Error message
   - Flutter doctor output
   - Steps already attempted

## Build Artifacts

### Web Build Output
```
build/web/
├── index.html
├── main.dart.js
├── flutter_service_worker.js
├── assets/
└── ...
```

### Android APK Output
```
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle Output
```
build/app/outputs/bundle/release/app-release.aab
```

### iOS Build Output
```
build/ios/iphoneos/Runner.app
```

## Deployment Targets

### Web
- Firebase Hosting
- Netlify
- GitHub Pages
- Custom web server

### Android
- Google Play Store (use app bundle)
- Direct APK distribution
- Internal testing (Google Play)

### iOS
- Apple App Store
- TestFlight (beta testing)
- Enterprise distribution

## Testing Requirements Summary

**CRITICAL REQUIREMENTS:**
- ✅ All 272 non-UI tests must pass (MANDATORY)
- ✅ 100% pass rate required (no exceptions)
- ❓ UI automation tests optional (ask user before running)
- ✅ Manual testing after build
- ✅ Cross-platform verification

**NEVER:**
- ❌ Build without running non-UI tests
- ❌ Proceed with failing tests
- ❌ Deploy untested builds
- ❌ Skip manual verification
