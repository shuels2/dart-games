# Dartboard Tests

## Overview

This directory contains comprehensive tests for the dartboard widget to ensure all segments are working correctly.

## Test Coverage

The `dartboard_test.dart` file includes **90 tests** covering:

### 1. Bullseye Tests (2 tests)
- Center hit (50 points)
- Edge of bullseye (50 points)

### 2. Outer Bull Tests (1 test)
- Outer bull/green ring (25 points)

### 3. Single Segment Tests (40 tests)
- All 20 segments in the inner single area
- All 20 segments in the outer single area
- Validates each segment returns the correct base number (1-20)

### 4. Double Segment Tests (20 tests)
- All 20 segments in the double ring
- Validates each segment returns 2× the base number (2-40)

### 5. Triple Segment Tests (20 tests)
- All 20 segments in the triple ring
- Validates each segment returns 3× the base number (3-60)

### 6. Miss Tests (1 test)
- Taps outside the board return 0 points

### 7. Edge Case Tests (3 tests)
- Boundary between bullseye and outer bull
- Boundary between triple and single
- Boundary between double and miss

### 8. Comprehensive Validation Tests (3 tests)
- All single scores are valid dartboard numbers
- All 20 segments are represented
- Correct dartboard sequence (20 at top)

## Running the Tests

### Run all dartboard tests
```bash
flutter test test/dartboard_test.dart
```

### Run all tests in the project
```bash
flutter test
```

### Run tests with coverage
```bash
flutter test --coverage
```

## Building with Tests

To ensure tests pass before building, use the provided build scripts:

### Windows
```bash
build_with_tests.bat web
```

### Linux/Mac
```bash
chmod +x build_with_tests.sh
./build_with_tests.sh web
```

These scripts will:
1. Run all dartboard tests
2. Abort the build if any test fails
3. Proceed with the build if all tests pass

## Test Structure

Each test follows this pattern:
1. Create a dartboard widget
2. Simulate a tap at a specific calculated position
3. Verify the returned score and multiplier match expectations

## Dartboard Geometry

The tests use the following radius multipliers to target specific areas:
- **Bullseye**: 0.000 - 0.037 (50 points)
- **Outer bull**: 0.037 - 0.094 (25 points)
- **Inner single**: 0.094 - 0.582 (base points)
- **Triple ring**: 0.582 - 0.676 (3× base points)
- **Outer single**: 0.676 - 0.906 (base points)
- **Double ring**: 0.906 - 1.000 (2× base points)
- **Miss**: > 1.000 (0 points)

## Adding New Tests

To add new tests:
1. Open `test/dartboard_test.dart`
2. Add your test within the appropriate `group()`
3. Use the `calculatePosition()` helper to compute tap positions
4. Run tests to verify they pass

## Continuous Integration

For CI/CD pipelines, add this step to your workflow:
```yaml
- name: Run dartboard tests
  run: flutter test test/dartboard_test.dart
```

See `.github/workflows/flutter_test.yml` for a complete example.
