import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checks that every setting a game menu offers actually reaches its provider.
///
/// The recurring failure this catches: a menu grows a new toggle, the control
/// is built and wired to `setState`, and the value is then never passed to
/// `startGame(...)`. The option looks completely functional — it renders, it
/// toggles, it persists across rebuilds — and changes nothing about the game.
/// No behaviour test notices, because the provider was never asked to behave
/// differently.
///
/// The check is deliberately static (source text, not rendering) so it runs in
/// `flutter test` in under a second and can gate a build before any UI test
/// infrastructure exists.
///
/// Heuristic, so it errs toward silence: it only inspects private mutable
/// fields that a control actually writes to (`setState(() => _x = ...)` or
/// `_x = ...` inside a callback), and it accepts the value being forwarded
/// either directly or through a local computed from it.
void main() {
  final menuScreens = Directory('lib/screens/games')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_menu_screen.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  /// Mutable instance fields that look like game settings: declared with a
  /// default, not `static`/`final`/`const`, and written from a callback.
  Set<String> settingFields(String src) {
    final declared = <String>{};
    for (final line in src.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('static ') ||
          trimmed.startsWith('final ') ||
          trimmed.startsWith('const ') ||
          trimmed.startsWith('late ')) {
        continue;
      }
      final match =
          RegExp(r'^[\w<>,\s?]+\s(_[a-zA-Z]\w*)\s*=[^=]').firstMatch(trimmed);
      if (match != null) declared.add(match.group(1)!);
    }

    // Only fields the UI actually writes to — a field merely initialised once
    // is not a user-facing setting.
    final assigned = declared
        .where((f) => RegExp('setState[^;]*$f\\s*=[^=]|$f\\s*=[^=]')
            .allMatches(src)
            .length >
            1)
        .toSet();

    // Names that are screen plumbing rather than game settings.
    const ignoredExact = {
      '_hasSavedGames',
      '_showResumeModal',
      '_showSaveModal',
      '_isLoading',
      '_loading',
      '_saving',
      '_error',
      '_activeCrestPaths',
      // Crest/icon asset paths loaded at init for display, not chosen by the
      // player — passed to widgets rather than to startGame.
      '_teamIconPaths',
      '_selectedPlayers',
      '_scrollController',
      '_searchQuery',
      '_expanded',
      '_pulseController',
      '_animationController',
    };
    const ignoredSuffixes = [
      'Controller',
      'Animation',
      'Timer',
      'Key',
      'Focus',
      'Subscription',
    ];

    return assigned.where((f) {
      if (ignoredExact.contains(f)) return false;
      for (final suffix in ignoredSuffixes) {
        if (f.endsWith(suffix)) return false;
      }
      return true;
    }).toSet();
  }

  /// The body of the `provider.startGame( ... )` call, plus the enclosing
  /// method, so values forwarded through a local still count.
  String? startGameContext(String src) {
    // `.startGame(` — not `_startGame(`, which is the local method that wraps
    // it and would otherwise match first and yield an empty context.
    final buffer = StringBuffer();
    for (final match in RegExp(r'\.startGame\(').allMatches(src)) {
      final call = match.end - 1;
      // Include the enclosing method so values forwarded through a local
      // (e.g. `final actualTeamCount = ...;`) still count.
      final methodStart = src.lastIndexOf(RegExp(r'void\s+_startGame'), call);
      final from = methodStart >= 0 ? methodStart : call;
      var depth = 0;
      for (var i = call; i < src.length; i++) {
        final ch = src[i];
        if (ch == '(') depth++;
        if (ch == ')') {
          depth--;
          if (depth == 0) {
            buffer.write(src.substring(from, i + 1));
            break;
          }
        }
      }
    }
    final text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  group('Menu option wiring', () {
    test('every menu setting is passed to startGame', () {
      final offenders = <String>[];

      for (final file in menuScreens) {
        final src = file.readAsStringSync();
        final name = file.path.replaceAll(r'\', '/').split('/').last;
        final context = startGameContext(src);
        if (context == null) continue; // menu doesn't start a game itself

        for (final field in settingFields(src)) {
          if (!context.contains(field)) {
            offenders.add('$name: $field is set by the UI but never reaches '
                'startGame()');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'A setting the player can change must change the game. '
              'If a field here is not a game setting, add it to the ignore '
              'list in this test.\n${offenders.join('\n')}');
    });
  });
}
