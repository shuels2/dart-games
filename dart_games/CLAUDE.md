# Claude Development Guidelines for Dart Games

## Critical Rules

### Dartboard Emulator Code Protection

**NEVER update the dartboard emulator code without explicit permission from the user.**

The dartboard emulator (`lib/widgets/interactive_dartboard.dart`) is working correctly and has been thoroughly tested. Any changes to this component must be explicitly requested and approved by the user before implementation.

Files that require explicit permission before modification:
- `lib/widgets/interactive_dartboard.dart` - Interactive dartboard widget
- Segment calculation logic
- Ring boundary detection
- Coordinate mapping and scaling

If a bug is suspected in the dartboard emulator, ask the user to verify the issue before making changes.

## Testing Requirements

### All Tests Must Pass Before Build

**Run the complete test suite with every build of the dart games app.**

Before any build or deployment:

```bash
cd dart-games/dart_games
flutter test
```

All tests must pass. If any tests fail:
1. Do not proceed with the build
2. Investigate and fix the failing tests
3. Re-run the test suite
4. Only build after all tests pass

### Test Coverage

Current test suite includes:
- Interactive dartboard widget tests (23 tests)
  - Dartboard rendering and scaling
  - Bulls detection (50 and 25 points)
  - Ring detection (double, triple, single)
  - Segment scoring accuracy across the board
  - Dart position persistence across window resize
  - Dart management (add/remove functionality)

### Running Specific Test Suites

Interactive dartboard tests:
```bash
flutter test test/widgets/interactive_dartboard_test.dart
```

### Test Expectations

- **100% pass rate required** - All 23 dartboard tests must pass
- Tests validate both the admin options emulator and carnival derby emulator
- Scaling behavior must be verified at multiple window sizes
- Segment scoring must be accurate for all positions

## Git Workflow

### Push Permission Required

**NEVER push to the master branch without explicit permission from the user.**

Before pushing any commits to the remote repository:
1. Ask the user for permission to push
2. Wait for explicit approval
3. Only push after receiving confirmation

This applies to all git operations that modify the remote repository, including:
- `git push origin master`
- `git push`
- Force pushes or any other push commands

## Workflow

1. Make code changes (excluding protected dartboard emulator code)
2. Run full test suite: `flutter test`
3. Verify all tests pass
4. Commit changes locally (if appropriate)
5. **Ask user for permission before pushing to remote**
6. Only then proceed with build/deployment
7. If tests fail, fix issues before building

## Notes

- The dartboard emulator has been validated to work correctly
- Test results are documented in `TEST_RESULTS.md`
- Any dartboard-related issues should be reported to the user for approval before fixing
