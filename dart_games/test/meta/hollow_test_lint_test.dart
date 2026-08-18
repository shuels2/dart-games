// test/meta/hollow_test_lint_test.dart
//
// Detector (c) of the three from ANSWERS-FROM-FABLE-2 §A8.2 — but NOT the
// design that answer sketched. The sketch is documented here along with why it
// does not work, because it looks reasonable and someone will propose it again.
//
// ─── WHAT WAS SPECIFIED, AND WHY IT WAS ABANDONED ──────────────────────────
// The plan called for a cross-game comparison: within a category, the same
// filename is the same scenario, so a game whose copy performs ZERO
// interactions while its peers perform several is presumptively hollow.
//
// Measured against this repo, that produces ONLY false positives. Every signal
// it raised was a test that drives the app through a PER-GAME DELEGATE:
//
//   reef_royale/results_screen/winner_stats_updated_test.dart  — "0 interactions"
//     ... but it calls setupAndStartGame() and completeGameToVictory(), both
//     of which are local wrappers around real interactions.
//   gladiator_arena/gameplay/min_player_count_test.dart        — "0 interactions"
//     ... but it calls completeTurnWithMisses().
//   tiki_golf/menu_and_settings/max_strokes_persists_test.dart — "0 interactions"
//     ... but it calls setMaxStrokes(), a wrapper around SettingsHelpers.
//
// The detector needs a vocabulary of "verbs that drive the app", and every
// game defines its own delegate names. No regex list can enumerate them, and
// each omission accuses an innocent test. A lint that only ever cries wolf is
// worse than no lint — the same reasoning that kept the overflow harness
// skipped rather than baselined red.
//
// ─── WHAT IS ACTUALLY DETECTED ─────────────────────────────────────────────
// The shape Gladiator's tests really had: several differently-NAMED
// `testWidgets` in one file whose BODIES are identical. That is what "hollow"
// looked like in practice — twenty tests, one body, names promising twenty
// different assertions.
//
// This needs no vocabulary, so delegate naming cannot fool it. Verified
// against the pre-conversion file at 30fb3cf~1:
//   gladiator_arena/pause_modal/menu_pause_test.dart
//     7 testWidgets, 2 distinct bodies, 6 identical  -> would have FAILED
// and it flags nothing in the current tree.
//
// Bodies are normalised by stripping comments, collapsing whitespace, and
// blanking string literals — so two tests differing only in a `reason:`
// message still count as identical, which is correct: the assertion is the
// same either way.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Three identical bodies in one file is not a coincidence worth defending.
/// Two can be legitimate (a pair of cases differing only in a string that the
/// normaliser blanks), so the threshold sits above that.
const _maxIdenticalBodies = 3;

final _splitOnTestWidgets = RegExp(r'\btestWidgets\(');
final _lineComment = RegExp(r'//[^\n]*');
final _singleQuoted = RegExp(r"'(?:[^'\\]|\\.)*'");
final _whitespace = RegExp(r'\s+');
final _callbackStart = RegExp(r'async\s*\{');

List<String> _normalisedBodies(String src) {
  final out = <String>[];
  final parts = src.split(_splitOnTestWidgets);
  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    final start = _callbackStart.firstMatch(part);
    if (start == null) continue;
    var body = part.substring(start.end);
    body = body.replaceAll(_lineComment, '');
    body = body.replaceAll(_singleQuoted, "''");
    body = body.replaceAll(_whitespace, ' ').trim();
    // A prefix is enough to distinguish real scenarios and keeps the
    // comparison cheap on long files.
    out.add(body.length > 900 ? body.substring(0, 900) : body);
  }
  return out;
}

void main() {
  test('no UI test file repeats one body across differently-named tests', () {
    final offenders = <String>[];

    for (final entity
        in Directory('integration_test').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('_test.dart')) continue;
      if (path.contains('/shared/')) continue;

      final bodies = _normalisedBodies(entity.readAsStringSync());
      if (bodies.length < _maxIdenticalBodies) continue;

      final counts = <String, int>{};
      for (final b in bodies) {
        counts[b] = (counts[b] ?? 0) + 1;
      }
      final worst =
          counts.values.fold<int>(0, (a, b) => a > b ? a : b);
      if (worst >= _maxIdenticalBodies) {
        offenders.add('${path.split('integration_test/').last} '
            '(${bodies.length} tests, $worst share one body)');
      }
    }

    expect(offenders, isEmpty,
        reason: 'These files have differently-named tests with IDENTICAL '
            'bodies, so the names promise assertions the code does not make. '
            'That is how twenty Gladiator Arena pause tests passed for months '
            'while asserting nothing. Give each test the body its name '
            'describes, or route the file through a shared suite. '
            'Offenders: $offenders');
  });
}
