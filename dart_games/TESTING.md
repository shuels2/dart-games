# Dartboard Testing Guide

## Test Suite Overview

A comprehensive test suite has been created to validate all dartboard segments and scoring logic.

**Total Tests: 90**

## Test Breakdown

| Test Category | Count | Description |
|--------------|-------|-------------|
| Bullseye | 2 | Tests for the red center (50 points) |
| Outer Bull | 1 | Tests for the green ring (25 points) |
| Single Segments | 40 | All 20 segments × 2 areas (inner + outer) |
| Double Segments | 20 | All 20 segments in double ring (2× score) |
| Triple Segments | 20 | All 20 segments in triple ring (3× score) |
| Miss Tests | 1 | Outside board (0 points) |
| Edge Cases | 3 | Boundary conditions |
| Validation | 3 | Dartboard structure validation |

## Running Tests

### Quick Run
```bash
flutter test test/dartboard_test.dart
```

### With Coverage
```bash
flutter test test/dartboard_test.dart --coverage
```

## Building with Tests

### Windows
```bash
build_with_tests.bat web
```

### Linux/Mac
```bash
./build_with_tests.sh web
```

These scripts will:
1. ✅ Run all dartboard tests
2. ❌ Abort if any test fails
3. ✅ Build the app if all tests pass

## Continuous Integration

A GitHub Actions workflow has been created at `.github/workflows/flutter_test.yml` that:
- Runs on every push and pull request
- Executes all tests
- Generates coverage reports
- Builds the app only if tests pass

## Test Coverage

The tests verify:
- ✅ Bullseye (50 points)
- ✅ Outer bull/green ring (25 points)
- ✅ All 20 single segments (1-20 points)
- ✅ All 20 double segments (2-40 points)
- ✅ All 20 triple segments (3-60 points)
- ✅ Miss detection (0 points)
- ✅ Boundary conditions between rings
- ✅ Correct segment sequence (20 at top, clockwise)

## What's Tested

Each test simulates a tap at a precise location on the dartboard and verifies:
1. **Score**: The numeric value returned
2. **Multiplier**: 'single', 'double', 'triple', 'bullseye', 'outer_bull', or 'miss'

## Files Created

1. **test/dartboard_test.dart** - Main test file (90 tests)
2. **build_with_tests.bat** - Windows build script
3. **build_with_tests.sh** - Linux/Mac build script
4. **.github/workflows/flutter_test.yml** - CI/CD workflow
5. **test/README.md** - Detailed test documentation
6. **TESTING.md** - This file

## Next Steps

1. Run tests locally: `flutter test test/dartboard_test.dart`
2. Use build scripts for production builds
3. Push to GitHub to trigger CI/CD workflow
4. Monitor test results in GitHub Actions

## Troubleshooting

**Tests fail?**
- Check that the dartboard widget hasn't been modified
- Verify segment calculations in `interactive_dartboard.dart`
- Review radius multipliers (bullseye: 0.037, outer bull: 0.094, etc.)

**Build script doesn't work?**
- Windows: Ensure Flutter is in PATH or use full path
- Linux/Mac: Make script executable with `chmod +x build_with_tests.sh`

---

**Status**: ✅ All 90 tests passing
