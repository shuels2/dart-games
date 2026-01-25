#!/bin/bash
# Build script that runs dartboard tests before building

echo "========================================"
echo "Running Dartboard Segment Tests"
echo "========================================"
flutter test test/dartboard_test.dart

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "TESTS FAILED - Build aborted"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "All tests passed! Proceeding with build"
echo "========================================"
echo ""

# Run the actual build
flutter build "$@"

if [ $? -ne 0 ]; then
    echo ""
    echo "========================================"
    echo "BUILD FAILED"
    echo "========================================"
    exit 1
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "========================================"
