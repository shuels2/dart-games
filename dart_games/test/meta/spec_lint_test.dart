// test/meta/spec_lint_test.dart
//
// WS07 §7.9 — the Phase 0 spec-lint, run as part of `flutter test` so a spec
// problem surfaces BEFORE a build starts rather than as confusion four phases
// in.
//
// ─── WHY THIS EXISTS ───────────────────────────────────────────────────────
// game.build Phase 0 builds its section map by grepping `^## \d+\.`. Two
// spec templates are in circulation and they disagree about where the
// Definition of Done lives:
//
//   * modern  — `## 14. Definition of Done`     (a numbered H2; grep sees it)
//   * legacy  — `### Definition of Done` nested inside §14
//               (an unnumbered H3; the grep CANNOT see it)
//
// When Phase 0 cannot see the DoD, Gate 5 — "verify every item in the spec's
// Definition of Done" — silently degrades to verifying nothing, and the build
// still reports success. That is the specific failure this file prevents.
//
// ─── BASELINED, NOT ENFORCED RETROACTIVELY ─────────────────────────────────
// Most existing specs violate these rules today. Rewriting 27 research
// documents is not this change's job, so the known offenders are listed
// explicitly below. The value is twofold: a NEW spec cannot join the corpus
// broken, and the exact debt is enumerated instead of being folded into a
// count nobody reads.
//
// To fix a spec: correct it, then delete its line from the baseline. The
// "baseline is not stale" test fails if you fix a spec and forget.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Specs with no Definition of Done anywhere, at any heading level.
/// Gate 5 has nothing to check for these.
const _noDefinitionOfDone = <String>{
  'completed/treasure-divide.md',
  'tier1/forest-chase.md',
  'tier1/paws-and-claws.md',
  'tier2/rocket-countdown.md',
  'tier2/wild-west-showdown.md',
  'tier3/castle-siege.md',
  'tier3/depth-charge.md',
  'tier3/wizards-wager.md',
};

/// Specs whose Definition of Done is an unnumbered `###`, invisible to
/// Phase 0's `^## \d+\.` section-map grep.
const _definitionOfDoneNestedAsH3 = <String>{
  'completed/gladiator-arena.md',
  'completed/pirates-grid.md',
  'completed/tiki-golf.md',
  'tier1/candy-cascade.md',
  'tier2/goal-rush.md',
  'tier2/jungle-stampede.md',
  'tier2/stampede-sprint.md',
  'tier2/treasure-hunter.md',
  'tier3/asteroid-defense.md',
  'tier3/dragon-slayer.md',
  'tier3/robot-wars.md',
  'tier3/timber-tumble.md',
  'tier3/vault-cracker.md',
  'tier3/zombie-outbreak.md',
};

const _specRoot = 'docs/research/games';

/// Sections game.build reads by number. §7 drives the options matrix and the
/// option-wiring lint; §10 drives the screen build and visual validation.
const _requiredSections = <String>['7.', '10.'];

final _h2Numbered = RegExp(r'^## (\d+)\. *(.+)$', multiLine: true);
final _dodH2 = RegExp(r'^## \d+\. *Definition of Done', multiLine: true);
final _dodH3 = RegExp(r'^### *Definition of Done', multiLine: true);

List<File> _specs() => Directory(_specRoot)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.md'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

String _rel(File f) =>
    f.path.replaceAll('\\', '/').split('$_specRoot/').last;

void main() {
  final specs = _specs();

  test('there are specs to lint', () {
    expect(specs, isNotEmpty,
        reason: 'No specs found under $_specRoot — has the path moved?');
  });

  group('spec lint', () {
    test('every spec has a Definition of Done', () {
      final missing = <String>[];
      for (final f in specs) {
        final src = f.readAsStringSync();
        if (!_dodH2.hasMatch(src) && !_dodH3.hasMatch(src)) {
          missing.add(_rel(f));
        }
      }
      final unexpected = missing.toSet().difference(_noDefinitionOfDone);
      expect(unexpected, isEmpty,
          reason: 'These specs have NO Definition of Done, so game.build '
              "Gate 5 has nothing to verify and will pass vacuously. Add one "
              'as a numbered H2 (`## N. Definition of Done`): $unexpected');
    });

    test("every spec's Definition of Done is visible to Phase 0", () {
      // Phase 0 maps sections with `^## \d+\.`. An unnumbered H3 is invisible
      // to it, which is what silently degrades Gate 5.
      final nested = <String>[];
      for (final f in specs) {
        final src = f.readAsStringSync();
        if (!_dodH2.hasMatch(src) && _dodH3.hasMatch(src)) {
          nested.add(_rel(f));
        }
      }
      final unexpected = nested.toSet().difference(_definitionOfDoneNestedAsH3);
      expect(unexpected, isEmpty,
          reason: "These specs nest Definition of Done as an unnumbered '### '"
              " heading. Phase 0's `^## \\d+\\.` grep cannot see it, so Gate 5 "
              'degrades to checking nothing. Promote it to `## N. Definition '
              'of Done`: $unexpected');
    });

    test('required numbered sections are present', () {
      final offenders = <String, List<String>>{};
      for (final f in specs) {
        final src = f.readAsStringSync();
        final numbers =
            _h2Numbered.allMatches(src).map((m) => '${m.group(1)}.').toSet();
        final missing =
            _requiredSections.where((s) => !numbers.contains(s)).toList();
        if (missing.isNotEmpty) offenders[_rel(f)] = missing;
      }
      expect(offenders, isEmpty,
          reason: 'game.build reads these sections BY NUMBER (§7 options '
              'matrix, §10 screen designs). Missing: $offenders');
    });

    test('section numbers are unique within a spec', () {
      // A duplicated number makes the Phase 0 section map ambiguous: the
      // build silently reads whichever one the grep happened to return.
      final offenders = <String, List<String>>{};
      for (final f in specs) {
        final src = f.readAsStringSync();
        final seen = <String>{};
        final dupes = <String>[];
        for (final m in _h2Numbered.allMatches(src)) {
          final n = m.group(1)!;
          if (!seen.add(n)) dupes.add('$n. ${m.group(2)}');
        }
        if (dupes.isNotEmpty) offenders[_rel(f)] = dupes;
      }
      expect(offenders, isEmpty,
          reason: 'Duplicate section numbers make the Phase 0 section map '
              'ambiguous: $offenders');
    });
  });

  group('spec-lint baseline hygiene', () {
    test('baseline entries all still exist', () {
      final present = specs.map(_rel).toSet();
      final ghosts = {..._noDefinitionOfDone, ..._definitionOfDoneNestedAsH3}
          .difference(present);
      expect(ghosts, isEmpty,
          reason: 'Baseline names specs that no longer exist. Remove them: '
              '$ghosts');
    });

    test('baseline is not stale — fixed specs must be removed from it', () {
      final stillBroken = <String>{};
      for (final f in specs) {
        final src = f.readAsStringSync();
        final rel = _rel(f);
        if (_noDefinitionOfDone.contains(rel) &&
            !_dodH2.hasMatch(src) &&
            !_dodH3.hasMatch(src)) {
          stillBroken.add(rel);
        }
        if (_definitionOfDoneNestedAsH3.contains(rel) &&
            !_dodH2.hasMatch(src) &&
            _dodH3.hasMatch(src)) {
          stillBroken.add(rel);
        }
      }
      final fixed = {..._noDefinitionOfDone, ..._definitionOfDoneNestedAsH3}
          .difference(stillBroken);
      expect(fixed, isEmpty,
          reason: 'These specs have been FIXED but are still baselined. '
              'Delete them from the baseline so the lint keeps guarding them: '
              '$fixed');
    });
  });
}
