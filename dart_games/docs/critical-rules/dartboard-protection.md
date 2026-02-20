# Critical Rule: Dartboard Emulator Code Protection

## Overview
The dartboard emulator code is working correctly and has been thoroughly tested. Any changes to this component must be explicitly requested and approved by the user before implementation.

## Protected Files

The following files require explicit user permission before modification:

- `lib/widgets/interactive_dartboard.dart` - Interactive dartboard widget
- Segment calculation logic
- Ring boundary detection
- Coordinate mapping and scaling

## Why This Rule Exists

The dartboard emulator is a critical component that:
- Has been extensively tested and validated
- Works correctly across all games
- Has complex geometry calculations that are fragile
- Affects all games in the Dart Games app

Changes to this component without thorough testing could:
- Break dartboard accuracy across all games
- Introduce subtle bugs in segment detection
- Affect coordinate mapping and scaling
- Break existing UI automation tests

## Procedure When Issues Are Suspected

If you suspect a bug in the dartboard emulator:

1. **DO NOT modify the code immediately**
2. **Document the suspected issue:**
   - What behavior you're observing
   - What behavior you expected
   - Steps to reproduce
   - Which game(s) are affected
3. **Ask the user to verify the issue**
4. **Wait for explicit approval** before making changes
5. **If approved:**
   - Make the minimal necessary changes
   - Test thoroughly with all games
   - Run full test suite
   - Document what was changed and why

## Example Communication

**Bad approach:**
```
I found a potential issue in the dartboard emulator and fixed it.
```

**Good approach:**
```
I noticed that clicking the 20 segment sometimes registers as 5.
This might be an issue in the dartboard emulator coordinate mapping.

Before making any changes to the protected dartboard emulator code,
I need your permission. Would you like me to investigate and propose
a fix?

Steps to reproduce:
1. Start Target Tag game
2. Click the 20 segment (top of dartboard)
3. Observe it sometimes registers as 5

Expected: Should always register as 20
Actual: Sometimes registers as 5
```

## Testing Requirements After Changes

If changes are approved and made:

1. **Run dartboard widget tests:**
   ```bash
   flutter test test/widgets/interactive_dartboard_test.dart
   ```

2. **Test manually in all games:**
   - Carnival Derby
   - Target Tag
   - Any other games

3. **Run full test suite:**
   ```bash
   flutter test
   ```

4. **Run UI automation tests (optional but recommended):**
   ```bash
   ./run_ui_tests.bat
   ```

## Reference

The dartboard emulator has been validated to work correctly. Test results are documented in `TEST_RESULTS.md`.

## Exception

The only changes that don't require permission:
- **Game-specific styling** via configuration objects (DartboardSectionConfig)
- **Integration code** in game screens (how the dartboard is used)
- **Tests** for the dartboard emulator

These are not changes to the dartboard emulator logic itself.
