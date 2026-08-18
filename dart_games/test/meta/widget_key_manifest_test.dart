// test/meta/widget_key_manifest_test.dart
//
// WS05 §5.2d — the widget-key manifest audit.
//
// 37 `*Keys` classes declare 547 keys in lib/constants/test_keys.dart, and
// until now nothing checked that any of them were attached to a widget. A key
// declared but never used in lib/ is worse than dead code: it is a finder that
// CAN NEVER MATCH, so a test written against it either fails mysteriously or —
// if it guards its tap behind an `isNotEmpty` check — passes while asserting
// nothing at all.
//
// That is not hypothetical. `CarnivalDerbyMenuKeys.targetScoreDropdown` is in
// the baseline below: the menu builds a Slider keyed
// `carnival_menu_target_score_slider`, the dropdown key was never attached,
// and Carnival's "Pause blocks settings controls" UI test spent its whole life
// tapping nothing behind a permanently-false guard. It took the pause_modal
// consolidation to notice, which is precisely the kind of thing a lint should
// have caught for free.
//
// ─── BASELINED, NOT FIXED HERE ─────────────────────────────────────────────
// 212 keys are dead today. Deleting them is a separate mechanical change (some
// may be intended for screens not yet built), so they are enumerated here
// instead. The value is that a NEW dead key cannot be added, and the existing
// debt is named rather than buried in a total.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';


/// Classes whose dead keys are few enough to list individually.
const _deadKeysByClass = <String, Set<String>>{
  'CarnivalDerbyMenuKeys': {
    'perfectFinishToggle',
    'targetScoreDropdown',
  },
  'ClockworkQuestGameKeys': {
    'confirmRemovalButton',
  },
  'LunarLanderGameKeys': {
    'turnSummary',
  },
  'ReefRoyaleGameKeys': {
    'dartBullseyeButton',
    'dartMissButton',
    'dartOuterBullButton',
  },
  'ReefRoyaleMenuKeys': {
    'showHintsSwitch',
  },
  'TargetTagMenuKeys': {
    'assignTeamsButton',
    'heroBonusToggle',
    'targetScoreDropdown',
    'teamModeToggle',
  },
  'TeamAssignmentDialogKeys': {
    'teamCountDropdown',
  },
  'TikiGolfGameKeys': {
    'mulliganButton',
    'scorecardCaption',
  },
  'TikiGolfMenuKeys': {
    'dartboardConnectionInfo',
    'teamCountDropdown',
  },
  'TreasureDivideGameKeys': {
    'mapChestImage',
    'playerTreasureStrip',
    'roundIndicator',
  },
  'TreasureDivideMenuKeys': {
    'teamCountDropdown',
  },
};

/// The three never-wired dart-button grids. Held by COUNT rather than by
/// name: each is ~64 mechanically-generated entries (dartSingle1Button ..
/// dartTriple20Button) for an emulator button layout that was specified
/// but never keyed in lib/. Listing 191 names would bury the 21 that are
/// individually interesting.
const _deadKeyCountsByClass = <String, int>{
  'CarnivalDerbyGameKeys': 64,
  'MonsterMashGameKeys': 63,
  'TargetTagGameKeys': 64,
};

const _keysFile = 'lib/constants/test_keys.dart';

/// Every .dart file under lib/ EXCEPT the declarations themselves.
String _libSourceExcludingDeclarations() {
  final buffer = StringBuffer();
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.replaceAll(r'\', '/').endsWith(_keysFile)) continue;
    buffer.write(entity.readAsStringSync());
  }
  return buffer.toString();
}

/// className -> declared key names, parsed from the declarations file.
Map<String, List<String>> _declaredKeys() {
  final src = File(_keysFile).readAsStringSync();
  final blocks = src.split(RegExp(r'\nclass (?=\w+Keys\b)'));
  final result = <String, List<String>>{};
  for (final block in blocks.skip(1)) {
    final name = RegExp(r'^(\w+Keys)\b').firstMatch(block)?.group(1);
    if (name == null) continue;
    result[name] = RegExp(r'static const (?:Key )?(\w+) =\s*(?:const )?Key\(')
        .allMatches(block)
        .map((m) => m.group(1)!)
        .toList();
  }
  return result;
}

void main() {
  final lib = _libSourceExcludingDeclarations();
  final declared = _declaredKeys();

  test('the declarations file parses', () {
    expect(declared, isNotEmpty,
        reason: 'parsed no key classes from $_keysFile');
  });

  group('every declared key is attached to a widget in lib/', () {
    declared.forEach((className, names) {
      test(className, () {
        final dead = [
          for (final n in names)
            if (!lib.contains('.$n')) n
        ];
        final counted = _deadKeyCountsByClass[className];
        if (counted != null) {
          expect(dead.length, lessThanOrEqualTo(counted),
              reason: '$className gained a new dead key. A key not attached '
                  'in lib/ is a finder that can never match.');
          return;
        }

        final baselined = _deadKeysByClass[className] ?? const <String>{};
        final unexpected = dead.toSet().difference(baselined);
        expect(unexpected, isEmpty,
            reason: 'Declared but never attached to a widget in lib/, so any '
                'finder using them can never match: $unexpected');
      });
    });
  });

  group('baseline hygiene', () {
    test('baselined keys still exist and are still dead', () {
      final revived = <String>[];
      _deadKeysByClass.forEach((className, names) {
        for (final n in names) {
          if (!(declared[className]?.contains(n) ?? false)) {
            revived.add('$className.$n (no longer declared)');
          } else if (lib.contains('.$n')) {
            revived.add('$className.$n (now wired up)');
          }
        }
      });
      expect(revived, isEmpty,
          reason: 'Fixed or deleted keys must come OUT of the baseline, or it '
              'stops guarding them: $revived');
    });

    test('the counted classes still exist', () {
      _deadKeyCountsByClass.forEach((className, _) {
        expect(declared.containsKey(className), isTrue,
            reason: '$className vanished — remove it from the baseline');
      });
    });
  });
}
