import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `test/shared/` and `integration_test/shared/` hold the same helper files
/// twice, and CLAUDE.md requires every edit to be applied to both copies.
///
/// That rule has held so far purely on discipline — nothing detects a miss.
/// Drift here is nasty: the two suites quietly test different behaviour, and
/// whichever one you are not running at the time keeps passing.
///
/// This turns a silent divergence into a failing test. Files that exist in
/// only one tree are fine (some helpers are genuinely non-UI-only); files that
/// exist in both must be byte-identical.
void main() {
  test('shared test helpers are identical in both trees', () {
    final unitDir = Directory('test/shared');
    final uiDir = Directory('integration_test/shared');

    expect(unitDir.existsSync(), isTrue, reason: 'test/shared is missing');
    expect(uiDir.existsSync(), isTrue,
        reason: 'integration_test/shared is missing');

    final drifted = <String>[];
    for (final entity in unitDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = entity.uri.pathSegments.last;
      final twin = File('${uiDir.path}/$name');
      if (!twin.existsSync()) continue; // intentionally single-tree

      // Compare content with line endings normalised: git's autocrlf can
      // legitimately differ between checkouts, and that is not drift.
      final a = entity.readAsStringSync().replaceAll('\r\n', '\n');
      final b = twin.readAsStringSync().replaceAll('\r\n', '\n');
      if (a != b) drifted.add(name);
    }

    expect(drifted, isEmpty,
        reason: 'These helpers differ between test/shared and '
            'integration_test/shared. Apply the change to BOTH copies '
            '(CLAUDE.md → Test Helper Synchronization):\n'
            '${drifted.join('\n')}');
  });
}
