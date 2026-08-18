// test/meta/skill_sync_test.dart
//
// CLAUDE.md requires every project skill to exist in TWO byte-identical
// copies:
//
//   .claude/skills/<name>/...   the locally-installed copy this session reads
//   skills/<name>/...           the copy committed to git
//
// Only the second is tracked (`.claude/` is gitignored), so the failure mode
// is silent and one-directional: edit the installed copy, commit nothing, and
// the next session on another machine runs the OLD rules while this machine
// runs the new ones — or commit only the tracked copy and this session keeps
// reading the stale one.
//
// CLAUDE.md says to verify with `diff -q` by hand. Nothing enforced it, which
// is exactly the kind of rule that quietly rots.
//
// A skill is no longer one file: game.build carves its phases into `phases/`
// and its appendices into `reference/` (WS07 §7.1). Checking only SKILL.md
// would leave those free to diverge silently, so every markdown file a skill
// owns is compared.
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

/// Reads a skill file for comparison, with line endings normalised away.
///
/// Only ONE of the two copies is tracked, and this repo is developed on
/// Windows with `core.autocrlf=true`. Git rewrites the tracked copy with CRLF
/// on every checkout, while the installed copy under `.claude/` is gitignored
/// so nothing ever rewrites it. Comparing raw bytes therefore turns an
/// ordinary branch switch into a wall of failures whose diagnostic prints two
/// identical-looking lines — the only difference being an invisible trailing
/// carriage return. That happened on 2026-08-18 right after PR #52 merged.
///
/// Line endings are not skill content. What must not diverge is what the file
/// SAYS, so normalise them and compare that.
String _content(File f) =>
    f.readAsStringSync().replaceAll('\r\n', '\n').replaceAll('\r', '\n');

/// Every markdown file a skill owns, relative to its own directory.
Set<String> _markdownFiles(String base, String name) {
  final dir = Directory('$base/$name');
  if (!dir.existsSync()) return {};
  final prefix = '$base/$name/';
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .map((f) => f.path.replaceAll(r'\', '/').split(prefix).last)
      .toSet();
}

void main() {
  final names = _skillNames();

  test('there are project skills to check', () {
    expect(names, isNotEmpty,
        reason: 'found no SKILL.md under skills/ or .claude/skills/ — has the '
            'layout changed?');
  });

  for (final name in names) {
    group(name, () {
      test('both trees hold the same set of files', () {
        final tracked = _markdownFiles('skills', name);
        final installed = _markdownFiles('.claude/skills', name);

        expect(tracked, isNotEmpty,
            reason: 'skills/$name contains no markdown');
        expect(installed.difference(tracked), isEmpty,
            reason: 'Installed-only files are NOT in version control, so no '
                'other machine has them: ${installed.difference(tracked)}');
        expect(tracked.difference(installed), isEmpty,
            reason: 'Committed files this session is NOT running: '
                '${tracked.difference(installed)}');
      });

      for (final rel in _markdownFiles('skills', name)) {
        test(rel, () {
          final tracked = File('skills/$name/$rel');
          final installed = File('.claude/skills/$name/$rel');

          expect(tracked.existsSync(), isTrue,
              reason: 'skills/$name/$rel is missing. The installed copy is '
                  'gitignored, so it is not in version control at all.');
          expect(installed.existsSync(), isTrue,
              reason: '.claude/skills/$name/$rel is missing, so THIS session '
                  'is not running what is committed.');

          final a = _content(tracked);
          final b = _content(installed);
          if (a == b) return;

          // A useful failure, not "strings differ" on a 5,600-line file.
          final al = a.split('\n');
          final bl = b.split('\n');
          var i = 0;
          while (i < al.length && i < bl.length && al[i] == bl[i]) {
            i++;
          }
          fail('skills/$name/$rel and .claude/skills/$name/$rel diverged at '
              'line ${i + 1}:\n'
              '  tracked  : ${i < al.length ? al[i] : "<end of file>"}\n'
              '  installed: ${i < bl.length ? bl[i] : "<end of file>"}\n'
              'Copy one over the other and commit BOTH, per CLAUDE.md.');
        });
      }
    });
  }
}
