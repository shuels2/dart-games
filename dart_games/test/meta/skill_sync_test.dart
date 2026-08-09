// test/meta/skill_sync_test.dart
//
// CLAUDE.md requires every project skill to exist in TWO byte-identical
// copies:
//
//   .claude/skills/<name>/SKILL.md   the locally-installed copy this session
//                                    actually reads
//   skills/<name>/SKILL.md           the copy committed to git
//
// Only the second is tracked (`.claude/` is gitignored), so the failure mode
// is silent and one-directional: edit the installed copy, commit nothing, and
// the next session on another machine runs the OLD rules while this machine
// runs the new ones. Or commit only the tracked copy and this session keeps
// reading the stale one.
//
// CLAUDE.md says to verify with `diff -q` by hand. Nothing enforced it, which
// is exactly the kind of rule that quietly rots — so this does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Both trees are scanned rather than a hardcoded list, so a NEW skill is
/// covered the moment it is added.
Set<String> _skillNames() {
  final names = <String>{};
  for (final base in ['skills', '.claude/skills']) {
    final dir = Directory(base);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync()) {
      if (entity is! Directory) continue;
      final name = entity.path.replaceAll(r'\', '/').split('/').last;
      if (File('$base/$name/SKILL.md').existsSync()) names.add(name);
    }
  }
  return names;
}

void main() {
  final names = _skillNames();

  test('there are project skills to check', () {
    expect(names, isNotEmpty,
        reason: 'found no SKILL.md under skills/ or .claude/skills/ — has the '
            'layout changed?');
  });

  group('every project skill exists in both trees, byte-identical', () {
    for (final name in names) {
      test(name, () {
        final tracked = File('skills/$name/SKILL.md');
        final installed = File('.claude/skills/$name/SKILL.md');

        expect(tracked.existsSync(), isTrue,
            reason: 'skills/$name/SKILL.md is missing. The installed copy is '
                'gitignored, so this skill is not in version control at all.');
        expect(installed.existsSync(), isTrue,
            reason: '.claude/skills/$name/SKILL.md is missing, so THIS session '
                'is not running the skill that is committed.');

        final a = tracked.readAsStringSync();
        final b = installed.readAsStringSync();
        if (a == b) return;

        // Give a useful failure rather than "strings differ" on a 5,000-line
        // file: report the first differing line.
        final al = a.split('\n');
        final bl = b.split('\n');
        var i = 0;
        while (i < al.length && i < bl.length && al[i] == bl[i]) {
          i++;
        }
        fail('skills/$name/SKILL.md and .claude/skills/$name/SKILL.md have '
            'diverged at line ${i + 1}:\n'
            '  tracked  : ${i < al.length ? al[i] : "<end of file>"}\n'
            '  installed: ${i < bl.length ? bl[i] : "<end of file>"}\n'
            'Copy one over the other and commit BOTH, per CLAUDE.md.');
      });
    }
  });
}
